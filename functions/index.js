const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { OpenAI } = require('openai');

// Firebase Admin初期化
admin.initializeApp();

// 多言語通知テキスト
function getNotificationText(locale) {
  const texts = {
    ja: {
      taskTitle: (actorName, taskName) => `${actorName}さんが「${taskName}」を記録しました`,
      taskBody: (timeMinutes) => timeMinutes ? `${timeMinutes}分` : '',
      costTitle: (actorName) => `${actorName}さんがコストを記録しました`,
      costBody: (purpose, amount) => `${purpose}: ¥${amount}`,
      letterTitle: (fromName) => `${fromName}さんからメッセージが届きました`,
      inactivityTitle: 'そろそろ、今日の分を10秒で',
      inactivityBody: '',
    },
    en: {
      taskTitle: (actorName, taskName) => `${actorName} recorded "${taskName}"`,
      taskBody: (timeMinutes) => timeMinutes ? `${timeMinutes} min` : '',
      costTitle: (actorName) => `${actorName} recorded a cost`,
      costBody: (purpose, amount) => `${purpose}: ¥${amount}`,
      letterTitle: (fromName) => `You received a message from ${fromName}`,
      inactivityTitle: "Time to record today's tasks in 10 seconds",
      inactivityBody: '',
    },
    ko: {
      taskTitle: (actorName, taskName) => `${actorName}님이 "${taskName}"을(를) 기록했습니다`,
      taskBody: (timeMinutes) => timeMinutes ? `${timeMinutes}분` : '',
      costTitle: (actorName) => `${actorName}님이 비용을 기록했습니다`,
      costBody: (purpose, amount) => `${purpose}: ¥${amount}`,
      letterTitle: (fromName) => `${fromName}님에게서 메시지가 도착했습니다`,
      inactivityTitle: '오늘의 기록을 10초 만에 해볼까요?',
      inactivityBody: '',
    },
  };
  return texts[locale] || texts['ja'];
}

// OpenAI設定
// 環境変数またはFirebase configからAPIキーを取得
const openaiKey = process.env.OPENAI_API_KEY || functions.config().openai?.key;
const openai = new OpenAI({
  apiKey: openaiKey,
});

/**
 * AI提案生成（OpenAI連携）
 * @param {string} householdId - 世帯ID
 * @returns {object} {suggestion: string}
 */
exports.generateAISuggestion = functions.https.onCall(async (data, context) => {
  try {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'ユーザーが認証されていません'
      );
    }

    const { householdId } = data;
    if (!householdId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'householdIdが指定されていません'
      );
    }

    console.log(`🤖 AI提案生成開始: ${householdId}`);

    // Plus会員チェック
    const userDoc = await admin
      .firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'ユーザー情報が見つかりません'
      );
    }

    const userData = userDoc.data();
    const locale = userData.locale || 'ja';
    if (userData.plan !== 'plus') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'この機能はPlus会員限定です'
      );
    }

    // 最新20件の記録を取得
    const recordsRef = admin
      .firestore()
      .collection('households')
      .doc(householdId)
      .collection('records');

    const snapshot = await recordsRef
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();

    if (snapshot.empty) {
      return {
        suggestion: 'まだ記録がありません。記録を始めて、AIからの提案を受け取りましょう！'
      };
    }

    // 記録データを集計
    const records = [];
    const memberStats = {};
    const categoryStats = {};

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      records.push({
        memberName: data.memberName || '不明',
        category: data.category || 'その他',
        task: data.task || '',
        timeMinutes: data.timeMinutes || 0,
        createdAt: data.createdAt?.toDate?.()?.toISOString() || '',
      });

      // メンバー別集計
      const member = data.memberName || '不明';
      if (!memberStats[member]) {
        memberStats[member] = { count: 0, totalMinutes: 0 };
      }
      memberStats[member].count += 1;
      memberStats[member].totalMinutes += data.timeMinutes || 0;

      // カテゴリ別集計
      const category = data.category || 'その他';
      categoryStats[category] = (categoryStats[category] || 0) + 1;
    });

    // household情報からメンバー名を取得
    const householdDoc = await admin
      .firestore()
      .collection('households')
      .doc(data.householdId)
      .get();

    const members = householdDoc.data()?.members || [];
    const memberNames = {};
    members.forEach(m => {
      memberNames[m.uid] = m.nickname || m.name || 'メンバー';
    });

    // メンバー別統計を更新（nicknameを使用）
    const memberStatsWithNames = {};
    Object.keys(memberStats).forEach(oldName => {
      // recordsからuidを探してnicknameに変換
      const record = records.find(r => r.memberName === oldName);
      if (record) {
        const uid = record.memberId || '';
        const nickname = memberNames[uid] || oldName;
        memberStatsWithNames[nickname] = memberStats[oldName];
      } else {
        memberStatsWithNames[oldName] = memberStats[oldName];
      }
    });

    // バランス計算
    const memberList = Object.keys(memberStatsWithNames);
    const totalMinutes = Object.values(memberStatsWithNames).reduce(
      (sum, stat) => sum + stat.totalMinutes,
      0
    );

    const balances = {};
    memberList.forEach(name => {
      const percent = totalMinutes > 0
        ? Math.round((memberStatsWithNames[name].totalMinutes / totalMinutes) * 100)
        : 50;
      balances[name] = percent;
    });

    const user1 = memberList[0] || 'メンバー1';
    const user2 = memberList[1] || 'メンバー2';

    // OpenAI APIプロンプト作成（ニックネーム重視・バランス削除・多言語対応）
    const promptByLocale = {
      ja: `あなたは、パートナー同士の生活データをやさしく振り返るAIです。
以下の条件とフォーマットに従って、「温かく・ユーモア少し・責めない」文章でレポートを作成してください。

【重要】必ずニックネームで呼びかけてください
- ユーザー1のニックネーム：「${user1}さん」
- ユーザー2のニックネーム：「${user2}さん」
- 文章内では必ずこのニックネームを使って呼びかけること

【入力データ】
- 今週の家事記録：
${Object.entries(categoryStats)
  .map(([cat, count]) => `  ${cat}：${count}回`)
  .join('\n')}
- ${user1}さん：${memberStatsWithNames[user1]?.count || 0}回、${memberStatsWithNames[user1]?.totalMinutes || 0}分
- ${user2}さん：${memberStatsWithNames[user2]?.count || 0}回、${memberStatsWithNames[user2]?.totalMinutes || 0}分

【出力フォーマット - 必ず以下の4項目の形式で返してください】
🧾 今週のまとめ：
{${user1}さん、${user2}さんのニックネームを使って、ふたりの頑張りを1〜2文でやさしく労う}

🧺 家事スキル診断：
・料理 ★★★☆☆：{短くユーモア＋改善のヒント}
・洗濯 ★★★☆☆：{短くユーモア＋改善のヒント}
・掃除 ★★★☆☆：{短くユーモア＋改善のヒント}

🏅 今週のナイスタスク：
{${user1}さんか${user2}さんのニックネームを使って、いちばん助かった家事を1文でほめる}

💡 あしたのワンアクション：
{${user1}さんか${user2}さんへの提案を、ニックネームを使って伝える}

【トーンルール】
- 責めない・比べすぎない・温かい言葉
- 必ずニックネームで呼びかける（「あなた」「メンバー」などは使わない）
- ユーモア 1割まで
- 絵文字は4〜6個まで
- 説明文や補足は返さない。必ず上記4項目の形式で返す`,
      en: `You are an AI that warmly reviews household data between partners.
Follow the conditions and format below to create a report in a "warm, slightly humorous, non-blaming" tone.

【Important】Always address by nickname
- User 1 nickname: "${user1}"
- User 2 nickname: "${user2}"
- Always use these nicknames in the text

【Input Data】
- This week's household records:
${Object.entries(categoryStats)
  .map(([cat, count]) => `  ${cat}: ${count} times`)
  .join('\n')}
- ${user1}: ${memberStatsWithNames[user1]?.count || 0} times, ${memberStatsWithNames[user1]?.totalMinutes || 0} min
- ${user2}: ${memberStatsWithNames[user2]?.count || 0} times, ${memberStatsWithNames[user2]?.totalMinutes || 0} min

【Output Format - Always return in the following 4 sections】
🧾 Weekly Summary:
{Use nicknames to warmly acknowledge both partners' efforts in 1-2 sentences}

🧺 Housework Skill Check:
・Cooking ★★★☆☆: {Brief humor + improvement hint}
・Laundry ★★★☆☆: {Brief humor + improvement hint}
・Cleaning ★★★☆☆: {Brief humor + improvement hint}

🏅 Nice Task of the Week:
{Use a nickname to praise the most helpful task in 1 sentence}

💡 Tomorrow's One Action:
{A suggestion for ${user1} or ${user2}, using their nickname}

【Tone Rules】
- Non-blaming, warm words
- Always address by nickname (never use "you" or "member")
- Humor up to 10%
- 4-6 emojis max
- No explanations or notes. Always return in the above 4-section format`,
      ko: `당신은 파트너 간의 생활 데이터를 따뜻하게 돌아보는 AI입니다.
아래 조건과 형식에 따라 "따뜻하고, 약간의 유머, 비난하지 않는" 문장으로 리포트를 작성해주세요.

【중요】반드시 닉네임으로 불러주세요
- 사용자 1 닉네임: "${user1}"
- 사용자 2 닉네임: "${user2}"
- 문장 내에서 반드시 이 닉네임을 사용할 것

【입력 데이터】
- 이번 주 가사 기록:
${Object.entries(categoryStats)
  .map(([cat, count]) => `  ${cat}: ${count}회`)
  .join('\n')}
- ${user1}: ${memberStatsWithNames[user1]?.count || 0}회, ${memberStatsWithNames[user1]?.totalMinutes || 0}분
- ${user2}: ${memberStatsWithNames[user2]?.count || 0}회, ${memberStatsWithNames[user2]?.totalMinutes || 0}분

【출력 형식 - 반드시 아래 4개 항목 형식으로 반환】
🧾 이번 주 요약:
{닉네임을 사용하여 두 사람의 노력을 1~2문장으로 따뜻하게 격려}

🧺 가사 스킬 진단:
・요리 ★★★☆☆: {짧은 유머 + 개선 힌트}
・세탁 ★★★☆☆: {짧은 유머 + 개선 힌트}
・청소 ★★★☆☆: {짧은 유머 + 개선 힌트}

🏅 이번 주 나이스 태스크:
{닉네임을 사용하여 가장 도움이 된 가사를 1문장으로 칭찬}

💡 내일의 원 액션:
{닉네임을 사용하여 ${user1} 또는 ${user2}에게 제안}

【톤 규칙】
- 비난하지 않기, 따뜻한 말
- 반드시 닉네임으로 호칭 ("당신"이나 "멤버" 사용 금지)
- 유머 10%까지
- 이모지 4~6개
- 설명이나 보충 없이 위의 4개 항목 형식으로만 반환`,
    };
    const prompt = promptByLocale[locale] || promptByLocale['ja'];

    console.log('📤 OpenAI APIリクエスト送信');

    // OpenAI APIで提案生成（多言語対応）
    const systemMessageByLocale = {
      ja: 'あなたはパートナー同士の生活データをやさしく振り返るAIです。温かく・ユーモア少し・責めない口調で、家事分担のふりかえりレポートを作成します。',
      en: 'You are an AI that warmly reviews household data between partners. Create a housework review report in a warm, slightly humorous, non-blaming tone.',
      ko: '당신은 파트너 간의 생활 데이터를 따뜻하게 돌아보는 AI입니다. 따뜻하고, 약간의 유머, 비난하지 않는 어조로 가사 분담 리포트를 작성합니다.',
    };
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: systemMessageByLocale[locale] || systemMessageByLocale['ja'],
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 500,
      temperature: 0.7,
    });

    const suggestion = completion.choices[0].message.content.trim();
    
    console.log('✅ AI提案生成完了');
    console.log(`提案: ${suggestion}`);

    return { suggestion };

  } catch (error) {
    console.error('❌ AI提案生成エラー:', error);

    // OpenAI APIエラーの場合
    if (error.status === 429) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'APIの利用制限に達しました。しばらくしてから再度お試しください。'
      );
    }

    if (error.status === 401) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'OpenAI APIキーが無効です。'
      );
    }

    // その他のエラー
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'AI提案の生成に失敗しました。'
    );
  }
});

/**
 * AIふりかえりレポート生成（Plus限定）
 * @param {string} householdId - 世帯ID
 * @returns {object} {report: string}
 */
exports.generateWeeklyReport = functions.https.onCall(async (data, context) => {
  try {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'ユーザーが認証されていません'
      );
    }

    const { householdId } = data;
    if (!householdId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'householdIdが指定されていません'
      );
    }

    console.log(`📊 AIふりかえりレポート生成開始: ${householdId}`);

    // Plus会員チェック
    const userDoc = await admin
      .firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'ユーザー情報が見つかりません'
      );
    }

    const userData = userDoc.data();
    const locale = userData.locale || 'ja';
    if (userData.plan !== 'plus') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'この機能はPlus会員限定です'
      );
    }

    // 過去7日間の記録を取得
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recordsRef = admin
      .firestore()
      .collection('households')
      .doc(householdId)
      .collection('records');

    const snapshot = await recordsRef
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .orderBy('createdAt', 'desc')
      .get();

    if (snapshot.empty) {
      return {
        report: '🌿 まだ記録がありません\n\n記録を始めて、AIふりかえりレポートを受け取りましょう！'
      };
    }

    // household情報からメンバー名を取得
    const householdDoc = await admin
      .firestore()
      .collection('households')
      .doc(householdId)
      .get();

    const members = householdDoc.data()?.members || [];
    const memberNames = {};
    members.forEach(m => {
      memberNames[m.uid] = m.nickname || m.name || 'メンバー';
    });

    // データ集計
    const memberStats = {};
    const categoryStats = {};
    const taskDetails = {};

    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const memberId = data.memberId || 'unknown';
      const memberName = memberNames[memberId] || data.memberName || '不明';
      const category = data.category || 'その他';
      const task = data.task || category;
      const timeMinutes = data.timeMinutes || 0;

      // メンバー別集計
      if (!memberStats[memberName]) {
        memberStats[memberName] = { count: 0, totalMinutes: 0 };
      }
      memberStats[memberName].count += 1;
      memberStats[memberName].totalMinutes += timeMinutes;

      // カテゴリ別集計
      if (!categoryStats[category]) {
        categoryStats[category] = { count: 0, totalMinutes: 0 };
      }
      categoryStats[category].count += 1;
      categoryStats[category].totalMinutes += timeMinutes;

      // タスク詳細
      if (!taskDetails[category]) {
        taskDetails[category] = [];
      }
      taskDetails[category].push({
        memberName,
        task,
        timeMinutes,
      });
    });

    // バランス計算
    const memberList = Object.keys(memberStats);
    const totalMinutes = Object.values(memberStats).reduce(
      (sum, stat) => sum + stat.totalMinutes,
      0
    );

    const balances = {};
    memberList.forEach(name => {
      const percent = totalMinutes > 0
        ? Math.round((memberStats[name].totalMinutes / totalMinutes) * 100)
        : 50;
      balances[name] = percent;
    });

    // OpenAI用プロンプト
    const user1 = memberList[0] || 'メンバー1';
    const user2 = memberList[1] || 'メンバー2';
    
    const weeklyPromptByLocale = {
      ja: `あなたは、パートナー同士の生活データをやさしく振り返るAIです。
以下の条件とフォーマットに従って、「温かく・ユーモア少し・責めない」文章でレポートを作成してください。

【入力データ】
- メンバー名（ニックネーム）：${user1}, ${user2}
- 今週の家事記録：
${Object.entries(categoryStats)
  .map(([cat, stat]) => `  ${cat}：${stat.count}回/${stat.totalMinutes}分`)
  .join('\n')}
- 今週の家事バランス：${user1} ${balances[user1] || 50}% vs ${user2} ${balances[user2] || 50}%
- ${user1}：${memberStats[user1]?.count || 0}回、${memberStats[user1]?.totalMinutes || 0}分
- ${user2}：${memberStats[user2]?.count || 0}回、${memberStats[user2]?.totalMinutes || 0}分

【出力フォーマット】
🌿 AIふりかえりレポート（Plus限定）

🧾 今週のまとめ
{ふたりの頑張りを1〜2文でやさしく労う}

📊 バランス
${user1} {%} vs ${user2} {%}

🧺 家事スキル診断
・料理    {★1〜5}：{短くユーモア＋改善のヒント}
・洗濯    {★1〜5}：{柔軟剤マスター級 など}
・掃除    {★1〜5}：{得意/苦手ポイントを優しく表現}

🏅 今週のナイスタスク
{いちばん助かった家事を1文でほめる}

💡 あしたのワンアクション
{次にひとつだけ挑戦すると良いこと}

【トーンルール】
- 責めない・比べすぎない・温かい言葉
- ユーモア 1割まで
- 全体 200〜280文字以内
- 絵文字は4〜7個まで
- 説明文や補足は返さない。出力本文のみ返す。
- 必ず上記フォーマットを守ること`,
      en: `You are an AI that warmly reviews household data between partners.
Follow the conditions and format below to create a report in a "warm, slightly humorous, non-blaming" tone.

【Input Data】
- Member nicknames: ${user1}, ${user2}
- This week's household records:
${Object.entries(categoryStats)
  .map(([cat, stat]) => `  ${cat}: ${stat.count} times / ${stat.totalMinutes} min`)
  .join('\n')}
- This week's balance: ${user1} ${balances[user1] || 50}% vs ${user2} ${balances[user2] || 50}%
- ${user1}: ${memberStats[user1]?.count || 0} times, ${memberStats[user1]?.totalMinutes || 0} min
- ${user2}: ${memberStats[user2]?.count || 0} times, ${memberStats[user2]?.totalMinutes || 0} min

【Output Format】
🌿 AI Review Report (Plus)

🧾 Weekly Summary
{Warmly acknowledge both partners' efforts in 1-2 sentences}

📊 Balance
${user1} {%} vs ${user2} {%}

🧺 Housework Skill Check
・Cooking    {★1-5}: {Brief humor + improvement hint}
・Laundry    {★1-5}: {Brief humor + improvement hint}
・Cleaning   {★1-5}: {Brief humor + improvement hint}

🏅 Nice Task of the Week
{Praise the most helpful task in 1 sentence}

💡 Tomorrow's One Action
{One thing to try next}

【Tone Rules】
- Non-blaming, warm words
- Humor up to 10%
- 200-280 characters total
- 4-7 emojis max
- No explanations or notes. Return only the output text.
- Always follow the above format`,
      ko: `당신은 파트너 간의 생활 데이터를 따뜻하게 돌아보는 AI입니다.
아래 조건과 형식에 따라 "따뜻하고, 약간의 유머, 비난하지 않는" 문장으로 리포트를 작성해주세요.

【입력 데이터】
- 멤버 닉네임: ${user1}, ${user2}
- 이번 주 가사 기록:
${Object.entries(categoryStats)
  .map(([cat, stat]) => `  ${cat}: ${stat.count}회 / ${stat.totalMinutes}분`)
  .join('\n')}
- 이번 주 가사 밸런스: ${user1} ${balances[user1] || 50}% vs ${user2} ${balances[user2] || 50}%
- ${user1}: ${memberStats[user1]?.count || 0}회, ${memberStats[user1]?.totalMinutes || 0}분
- ${user2}: ${memberStats[user2]?.count || 0}회, ${memberStats[user2]?.totalMinutes || 0}분

【출력 형식】
🌿 AI 리뷰 리포트 (Plus)

🧾 이번 주 요약
{두 사람의 노력을 1~2문장으로 따뜻하게 격려}

📊 밸런스
${user1} {%} vs ${user2} {%}

🧺 가사 스킬 진단
・요리    {★1~5}: {짧은 유머 + 개선 힌트}
・세탁    {★1~5}: {짧은 유머 + 개선 힌트}
・청소    {★1~5}: {짧은 유머 + 개선 힌트}

🏅 이번 주 나이스 태스크
{가장 도움이 된 가사를 1문장으로 칭찬}

💡 내일의 원 액션
{다음에 한 가지 도전하면 좋을 것}

【톤 규칙】
- 비난하지 않기, 따뜻한 말
- 유머 10%까지
- 전체 200~280자 이내
- 이모지 4~7개
- 설명이나 보충 없이 본문만 반환
- 반드시 위 형식을 지킬 것`,
    };
    const prompt = weeklyPromptByLocale[locale] || weeklyPromptByLocale['ja'];

    console.log('📤 OpenAI APIリクエスト送信（ふりかえりレポート）');

    // OpenAI APIでレポート生成（多言語対応）
    const weeklySystemByLocale = {
      ja: 'あなたはパートナー同士の生活データをやさしく振り返るAIです。温かく・ユーモア少し・責めない口調で、家事分担のふりかえりレポートを作成します。',
      en: 'You are an AI that warmly reviews household data between partners. Create a housework review report in a warm, slightly humorous, non-blaming tone.',
      ko: '당신은 파트너 간의 생활 데이터를 따뜻하게 돌아보는 AI입니다. 따뜻하고, 약간의 유머, 비난하지 않는 어조로 가사 분담 리포트를 작성합니다.',
    };
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: weeklySystemByLocale[locale] || weeklySystemByLocale['ja'],
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      max_tokens: 500,
      temperature: 0.7,
    });

    const report = completion.choices[0].message.content.trim();
    
    console.log('✅ AIふりかえりレポート生成完了');

    return { report };

  } catch (error) {
    console.error('❌ AIふりかえりレポート生成エラー:', error);

    // OpenAI APIエラーの場合
    if (error.status === 429) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'APIの利用制限に達しました。しばらくしてから再度お試しください。'
      );
    }

    if (error.status === 401) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'OpenAI APIキーが無効です。'
      );
    }

    // その他のエラー
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'AIふりかえりレポートの生成に失敗しました。'
    );
  }
});

/**
 * ユーザーデータを再帰的に削除（アカウント削除時）
 * @param {string} uid - ユーザーID
 */
exports.deleteUserData = functions.https.onCall(async (data, context) => {
  const { uid } = data;
  const errors = [];
  
  if (!uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'uidが指定されていません'
    );
  }

  console.log(`🧹 ユーザーデータ削除開始: ${uid}`);

  try {
    const db = admin.firestore();

    // 1. users ドキュメント削除
    try {
      const userDocRef = db.collection('users').doc(uid);
      const userDoc = await userDocRef.get();
      
      if (userDoc.exists) {
        await userDocRef.delete();
        console.log(`✅ usersドキュメント削除完了: ${uid}`);
      }
    } catch (error) {
      console.error(`❌ users削除エラー:`, error);
      errors.push(`users削除: ${error.message}`);
    }

    // 2. households 検索＆削除（修正版：全取得してフィルタリング）
    try {
      const householdsSnapshot = await db.collection('households').get();
      
      for (const householdDoc of householdsSnapshot.docs) {
        const data = householdDoc.data();
        const members = data.members || [];
        
        // このユーザーがメンバーに含まれているか確認
        const isMember = members.some(m => m.uid === uid);
        
        if (isMember) {
          const householdRef = householdDoc.ref;
          console.log(`🏠 household削除: ${householdRef.id}`);
          
          // サブコレクション削除
          const subcollections = ['records', 'insights', 'costs'];
          for (const subName of subcollections) {
            try {
              const subSnapshot = await householdRef.collection(subName).get();
              for (const subDoc of subSnapshot.docs) {
                await subDoc.ref.delete();
              }
              console.log(`  └ ${subName} 削除完了`);
            } catch (error) {
              console.error(`  └ ${subName} 削除エラー:`, error);
              errors.push(`${subName}削除: ${error.message}`);
            }
          }
          
          // household ドキュメント削除
          await householdRef.delete();
          console.log(`✅ household削除完了: ${householdRef.id}`);
        }
      }
    } catch (error) {
      console.error(`❌ households削除エラー:`, error);
      errors.push(`households削除: ${error.message}`);
    }

    // 3. gratitudeMessages 削除
    try {
      // 送信したメッセージ
      const sentMessages = await db
        .collection('gratitudeMessages')
        .where('fromUserId', '==', uid)
        .get();
      
      for (const msg of sentMessages.docs) {
        await msg.ref.delete();
      }
      console.log(`✅ 送信した感謝メッセージ削除完了: ${sentMessages.size}件`);

      // 受信したメッセージ
      const receivedMessages = await db
        .collection('gratitudeMessages')
        .where('toUserId', '==', uid)
        .get();
      
      for (const msg of receivedMessages.docs) {
        await msg.ref.delete();
      }
      console.log(`✅ 受信した感謝メッセージ削除完了: ${receivedMessages.size}件`);
    } catch (error) {
      console.error(`❌ gratitudeMessages削除エラー:`, error);
      errors.push(`gratitudeMessages削除: ${error.message}`);
    }

    // 結果を返す
    if (errors.length === 0) {
      console.log(`✅ ユーザーデータ削除完了: ${uid}`);
      return { success: true, deleted: true };
    } else {
      console.warn(`⚠️ ユーザーデータ削除完了（一部エラーあり）: ${uid}`);
      return { success: true, deleted: true, errors, note: 'partial-success' };
    }

  } catch (error) {
    console.error('❌ deleteUserData 致命的エラー:', error);
    errors.push(`致命的エラー: ${error.message}`);
    return { 
      success: false, 
      deleted: false,
      errors,
      note: 'failed'
    };
  }
});

// ========================================
// FCM通知トリガー（パートナーアクション通知）
// ========================================

/**
 * タスク/記録作成時の通知
 * households/{householdId}/records/{recordId}
 */
exports.notifyTaskCreated = functions.firestore
  .document('households/{householdId}/records/{recordId}')
  .onCreate(async (snap, context) => {
    const { householdId, recordId } = context.params;
    const data = snap.data();
    const actorUid = data.memberId;
    const actorName = data.memberName || '家族';
    
    console.log(`📝 タスク作成通知: ${recordId} by ${actorName}`);
    
    try {
      // 重複防止：通知ログをチェック
      const logId = `task_${recordId}`;
      const logRef = admin.firestore()
        .collection('households')
        .doc(householdId)
        .collection('notificationLogs')
        .doc(logId);
      
      const logDoc = await logRef.get();
      if (logDoc.exists) {
        console.log('ℹ️ 既に通知済み（重複防止）');
        return null;
      }
      
      // 世帯のメンバーを取得
      const householdDoc = await admin.firestore()
        .collection('households')
        .doc(householdId)
        .get();
      
      if (!householdDoc.exists) {
        console.log('⚠️ 世帯情報が見つかりません');
        return null;
      }
      
      const members = householdDoc.data()?.members || [];
      const targetMembers = members.filter(m => m.uid !== actorUid);
      
      // 各パートナーに通知
      for (const member of targetMembers) {
        const uid = member.uid;
        
        // ユーザー設定を確認
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        if (!userDoc.exists) continue;
        
        const userData = userDoc.data();
        if (userData.notificationsEnabled !== true) continue;
        if (userData.notifyPartnerActions !== true) continue;

        const tokens = userData.fcmTokens || {};
        const tokenList = Object.keys(tokens).filter(t => tokens[t] === true);

        if (tokenList.length === 0) continue;

        // 多言語対応通知ペイロード
        const texts = getNotificationText(userData.locale || 'ja');
        const payload = {
          notification: {
            title: texts.taskTitle(actorName, data.task || data.category),
            body: texts.taskBody(data.timeMinutes),
          },
          data: {
            type: 'task',
            householdId,
            docId: recordId,
          },
        };

        // 複数トークンに送信
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokenList,
          notification: payload.notification,
          data: payload.data,
        });
        
        // 無効なトークンを削除
        if (response.failureCount > 0) {
          const tokensToRemove = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success && 
                (resp.error?.code === 'messaging/invalid-registration-token' ||
                 resp.error?.code === 'messaging/registration-token-not-registered')) {
              tokensToRemove.push(tokenList[idx]);
            }
          });
          
          if (tokensToRemove.length > 0) {
            const updates = {};
            tokensToRemove.forEach(token => {
              updates[`fcmTokens.${token}`] = admin.firestore.FieldValue.delete();
            });
            await admin.firestore().collection('users').doc(uid).update(updates);
            console.log(`🗑️ 無効トークン削除: ${tokensToRemove.length}個`);
          }
        }
        
        console.log(`✅ 通知送信完了: ${uid} (${response.successCount}/${tokenList.length})`);
      }
      
      // 通知ログを保存
      await logRef.set({
        type: 'task',
        docId: recordId,
        actorUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (error) {
      console.error('❌ タスク作成通知エラー:', error);
      return null;
    }
  });

/**
 * コスト記録作成時の通知
 * households/{householdId}/costs/{costId}
 */
exports.notifyCostCreated = functions.firestore
  .document('households/{householdId}/costs/{costId}')
  .onCreate(async (snap, context) => {
    const { householdId, costId } = context.params;
    const data = snap.data();
    const actorUid = data.userId;
    const actorName = data.payerName || '家族';
    
    console.log(`💰 コスト記録通知: ${costId} by ${actorName}`);
    
    try {
      // 重複防止
      const logId = `cost_${costId}`;
      const logRef = admin.firestore()
        .collection('households')
        .doc(householdId)
        .collection('notificationLogs')
        .doc(logId);
      
      const logDoc = await logRef.get();
      if (logDoc.exists) {
        console.log('ℹ️ 既に通知済み（重複防止）');
        return null;
      }
      
      // 世帯のメンバーを取得
      const householdDoc = await admin.firestore()
        .collection('households')
        .doc(householdId)
        .get();
      
      if (!householdDoc.exists) return null;
      
      const members = householdDoc.data()?.members || [];
      const targetMembers = members.filter(m => m.uid !== actorUid);
      
      // 各パートナーに通知
      for (const member of targetMembers) {
        const uid = member.uid;
        
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        if (!userDoc.exists) continue;
        
        const userData = userDoc.data();
        if (userData.notificationsEnabled !== true) continue;
        if (userData.notifyPartnerActions !== true) continue;

        const tokens = userData.fcmTokens || {};
        const tokenList = Object.keys(tokens).filter(t => tokens[t] === true);

        if (tokenList.length === 0) continue;

        // 多言語対応通知ペイロード
        const texts = getNotificationText(userData.locale || 'ja');
        const payload = {
          notification: {
            title: texts.costTitle(actorName),
            body: texts.costBody(data.purpose || '', data.amount?.toLocaleString() || 0),
          },
          data: {
            type: 'cost',
            householdId,
            docId: costId,
          },
        };

        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokenList,
          notification: payload.notification,
          data: payload.data,
        });
        
        console.log(`✅ 通知送信完了: ${uid} (${response.successCount}/${tokenList.length})`);
      }
      
      // 通知ログを保存
      await logRef.set({
        type: 'cost',
        docId: costId,
        actorUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (error) {
      console.error('❌ コスト記録通知エラー:', error);
      return null;
    }
  });

/**
 * 感謝メッセージ作成時の通知（セキュリティ強化版）
 * gratitudeMessages/{messageId}
 */
exports.notifyLetterCreated = functions.firestore
  .document('gratitudeMessages/{messageId}')
  .onCreate(async (snap, context) => {
    const { messageId } = context.params;
    const data = snap.data();
    const householdId = data.householdId;
    const fromUserId = data.fromUserId;
    const toUserId = data.toUserId;
    const fromName = data.fromUserName || data.fromName || '家族';
    const message = data.message || '';
    
    console.log(`💌 感謝メッセージ通知: ${messageId}`);
    
    try {
      // householdIdチェック（セキュリティ強化）
      if (!householdId) {
        console.log('⚠️ householdIdが存在しません（古いデータ or 不正）');
        return null;
      }
      
      // 重複防止ログチェック
      const logId = `letter_${messageId}`;
      const logRef = admin.firestore()
        .collection('households')
        .doc(householdId)
        .collection('notificationLogs')
        .doc(logId);
      
      const logDoc = await logRef.get();
      if (logDoc.exists) {
        console.log('ℹ️ 既に通知済み（重複防止）');
        return null;
      }
      
      // 世帯情報を取得
      const householdDoc = await admin.firestore()
        .collection('households')
        .doc(householdId)
        .get();
      
      if (!householdDoc.exists) {
        console.log('⚠️ 世帯が見つかりません');
        return null;
      }
      
      const members = householdDoc.data()?.members || [];
      const memberUids = members.map(m => m.uid);
      
      // 送信者が世帯メンバーか検証
      if (!memberUids.includes(fromUserId)) {
        console.log('⚠️ 送信者が世帯メンバーではありません');
        return null;
      }
      
      // 受信者を決定（toUserIdがあれば検証、なければ送信者以外全員）
      let targetUids = [];
      if (toUserId) {
        // toUserIdが指定されている場合は世帯メンバーか検証
        if (memberUids.includes(toUserId)) {
          targetUids = [toUserId];
        } else {
          console.log('⚠️ 受信者が世帯メンバーではありません');
          return null;
        }
      } else {
        // toUserIdがない場合は送信者以外の全メンバー
        targetUids = memberUids.filter(uid => uid !== fromUserId);
      }
      
      if (targetUids.length === 0) {
        console.log('ℹ️ 通知対象者がいません');
        return null;
      }
      
      // 各受信者に通知
      for (const uid of targetUids) {
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        
        if (!userDoc.exists) continue;
        
        const userData = userDoc.data();
        if (userData.notificationsEnabled !== true) continue;
        if (userData.notifyPartnerActions !== true) continue;

        const tokens = userData.fcmTokens || {};
        const tokenList = Object.keys(tokens).filter(t => tokens[t] === true);

        if (tokenList.length === 0) continue;

        // 多言語対応通知ペイロード
        const texts = getNotificationText(userData.locale || 'ja');
        const payload = {
          notification: {
            title: texts.letterTitle(fromName),
            body: message.length > 50 ? `${message.substring(0, 50)}...` : message,
          },
          data: {
            type: 'letter',
            householdId,
            docId: messageId,
            fromUserId: fromUserId || '',
          },
        };
        
        // 複数トークンに送信
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokenList,
          notification: payload.notification,
          data: payload.data,
        });
        
        // 無効トークン削除
        if (response.failureCount > 0) {
          const tokensToRemove = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success && 
                (resp.error?.code === 'messaging/invalid-registration-token' ||
                 resp.error?.code === 'messaging/registration-token-not-registered')) {
              tokensToRemove.push(tokenList[idx]);
            }
          });
          
          if (tokensToRemove.length > 0) {
            const updates = {};
            tokensToRemove.forEach(token => {
              updates[`fcmTokens.${token}`] = admin.firestore.FieldValue.delete();
            });
            await admin.firestore().collection('users').doc(uid).update(updates);
            console.log(`🗑️ 無効トークン削除: ${tokensToRemove.length}個`);
          }
        }
        
        console.log(`✅ 通知送信完了: ${uid} (${response.successCount}/${tokenList.length})`);
      }
      
      // 通知ログを保存
      await logRef.set({
        type: 'letter',
        docId: messageId,
        actorUid: fromUserId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (error) {
      console.error('❌ 感謝メッセージ通知エラー:', error);
      return null;
    }
  });

/**
 * 3日間非アクティブユーザーへの通知（毎日午前9時実行）
 * スケジュール: 'every day 09:00' (Asia/Tokyo)
 */
exports.notifyInactiveUsers = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    console.log('⏰ 非アクティブユーザー通知開始');
    
    try {
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
      
      // 3日以上アクティビティがないユーザーを検索
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('notificationsEnabled', '==', true)
        .where('notifyInactivity', '==', true)
        .where('lastActivityAt', '<', admin.firestore.Timestamp.fromDate(threeDaysAgo))
        .get();
      
      console.log(`📊 対象ユーザー: ${usersSnapshot.size}人`);
      
      let sentCount = 0;
      
      for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        const userData = userDoc.data();
        
        // レート制限：最後の通知から3日経過しているかチェック
        const lastNotified = userData.lastInactivityNotifiedAt;
        if (lastNotified) {
          const lastNotifiedDate = lastNotified.toDate();
          const threeDaysAgoFromNow = new Date();
          threeDaysAgoFromNow.setDate(threeDaysAgoFromNow.getDate() - 3);
          
          if (lastNotifiedDate > threeDaysAgoFromNow) {
            console.log(`⏭️ スキップ: ${uid} (最近通知済み)`);
            continue;
          }
        }
        
        const tokens = userData.fcmTokens || {};
        const tokenList = Object.keys(tokens).filter(t => tokens[t] === true);

        if (tokenList.length === 0) continue;

        // 多言語対応通知ペイロード
        const texts = getNotificationText(userData.locale || 'ja');
        const payload = {
          notification: {
            title: texts.inactivityTitle,
            body: texts.inactivityBody,
          },
          data: {
            type: 'inactivity',
          },
        };
        
        // 送信
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokenList,
          notification: payload.notification,
          data: payload.data,
        });
        
        if (response.successCount > 0) {
          // 最後の通知時刻を更新
          await admin.firestore()
            .collection('users')
            .doc(uid)
            .update({
              lastInactivityNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          
          sentCount++;
          console.log(`✅ 非アクティブ通知送信: ${uid}`);
        }
      }
      
      console.log(`✅ 非アクティブユーザー通知完了: ${sentCount}人に送信`);
      return null;
    } catch (error) {
      console.error('❌ 非アクティブユーザー通知エラー:', error);
      return null;
    }
  });

/**
 * 健全性チェック用エンドポイント
 */
exports.healthCheck = functions.https.onRequest((req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Famica Cloud Functions is running',
    timestamp: new Date().toISOString(),
  });
});
