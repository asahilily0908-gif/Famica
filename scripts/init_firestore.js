/**
 * Firestore初期化スクリプト
 * Famica v3.0仕様に基づいてFirestoreを初期化します
 */

const admin = require('firebase-admin');

// Firebase Admin SDKの初期化
// serviceAccountKey.jsonを scripts/ ディレクトリに配置してください
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initializeFirestore() {
  console.log('🚀 Firestore初期化を開始します...\n');

  try {
    // 現在のユーザーIDを取得（実際のユーザーIDに置き換えてください）
    const currentUserId = 'XyKyUvhNBXQtA2oaQVAGSQZjd872'; // asahi9131@icloud.comのUID
    const householdId = currentUserId; // ユーザーのuidを世帯IDとして使用

    // 1. usersコレクションの初期化
    console.log('1️⃣  /users コレクションを初期化中...');
    await db.collection('users').doc(currentUserId).set({
      displayName: '松島',
      email: 'asahi9131@icloud.com',
      householdId: householdId,
      role: '夫',
      lifeStage: 'couple',
      plan: 'free',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ ユーザー情報を作成しました\n');

    // 2. householdsコレクションの初期化
    console.log('2️⃣  /households コレクションを初期化中...');
    await db.collection('households').doc(householdId).set({
      name: '松島家',
      inviteCode: generateInviteCode(),
      lifeStage: 'couple',
      members: [
        {
          uid: currentUserId,
          name: '松島',
          role: '夫',
          avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Matsushima'
        }
      ],
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ 世帯情報を作成しました\n');

    // 3. quickTemplatesサブコレクションの初期化
    console.log('3️⃣  /households/{householdId}/quickTemplates を初期化中...');
    const templates = [
      { task: '食事準備', defaultMinutes: 30, category: '家事', icon: '🍳', order: 1, lifeStage: 'all' },
      { task: '掃除', defaultMinutes: 20, category: '家事', icon: '🧹', order: 2, lifeStage: 'all' },
      { task: '洗濯', defaultMinutes: 15, category: '家事', icon: '👕', order: 3, lifeStage: 'all' },
      { task: '買い物', defaultMinutes: 45, category: '家事', icon: '🛒', order: 4, lifeStage: 'all' },
      { task: '介護サポート', defaultMinutes: 60, category: '介護', icon: '👵', order: 5, lifeStage: 'elderly' },
      { task: '通院付き添い', defaultMinutes: 120, category: '介護', icon: '🏥', order: 6, lifeStage: 'elderly' },
      { task: 'おむつ交換', defaultMinutes: 10, category: '育児', icon: '👶', order: 7, lifeStage: 'kids' },
      { task: '寝かしつけ', defaultMinutes: 30, category: '育児', icon: '😴', order: 8, lifeStage: 'kids' }
    ];

    const batch = db.batch();
    templates.forEach(template => {
      const ref = db.collection('households').doc(householdId).collection('quickTemplates').doc();
      batch.set(ref, template);
    });
    await batch.commit();
    console.log(`✅ ${templates.length}個のクイックテンプレートを作成しました\n`);

    // 4. サンプル記録の作成（オプション）
    console.log('4️⃣  サンプル記録を作成中...');
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    
    const sampleRecords = [
      {
        memberId: currentUserId,
        memberName: '松島',
        category: '家事',
        task: '食事準備',
        timeMinutes: 30,
        cost: 0,
        note: '夕食を作りました',
        month: currentMonth,
        thankedBy: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {
        memberId: currentUserId,
        memberName: '松島',
        category: '家事',
        task: '掃除',
        timeMinutes: 20,
        cost: 0,
        note: 'リビングと寝室を掃除',
        month: currentMonth,
        thankedBy: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }
    ];

    const recordBatch = db.batch();
    sampleRecords.forEach(record => {
      const ref = db.collection('households').doc(householdId).collection('records').doc();
      recordBatch.set(ref, record);
    });
    await recordBatch.commit();
    console.log(`✅ ${sampleRecords.length}個のサンプル記録を作成しました\n`);

    // 5. サンプル感謝メッセージの作成
    console.log('5️⃣  サンプル感謝メッセージを作成中...');
    const sampleThanks = [
      {
        from: currentUserId,
        fromName: '松島',
        to: currentUserId,
        toName: '松島',
        emoji: '❤️',
        message: '今日も美味しいご飯をありがとう！',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }
    ];

    const thanksBatch = db.batch();
    sampleThanks.forEach(thanks => {
      const ref = db.collection('households').doc(householdId).collection('thanks').doc();
      thanksBatch.set(ref, thanks);
    });
    await thanksBatch.commit();
    console.log(`✅ ${sampleThanks.length}個のサンプル感謝を作成しました\n`);

    // 6. サンプル記念日の作成
    console.log('6️⃣  サンプル記念日を作成中...');
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 30);
    
    const sampleMilestones = [
      {
        type: 'anniversary',
        title: '同棲記念日',
        date: futureDate,
        icon: '💑',
        isRecurring: true,
        notifyDaysBefore: 3,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }
    ];

    const milestonesBatch = db.batch();
    sampleMilestones.forEach(milestone => {
      const ref = db.collection('households').doc(householdId).collection('milestones').doc();
      milestonesBatch.set(ref, milestone);
    });
    await milestonesBatch.commit();
    console.log(`✅ ${sampleMilestones.length}個のサンプル記念日を作成しました\n`);

    // 7. membersサブコレクションの作成
    console.log('7️⃣  /households/{householdId}/members を作成中...');
    await db.collection('households').doc(householdId).collection('members').doc(currentUserId).set({
      name: '松島',
      role: '夫',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Matsushima',
      joinedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ メンバー情報を作成しました\n');

    console.log('✨ Firestore初期化が完了しました！\n');
    console.log('📊 作成されたデータ:');
    console.log(`   - ユーザー: 1件`);
    console.log(`   - 世帯: 1件`);
    console.log(`   - クイックテンプレート: ${templates.length}件`);
    console.log(`   - サンプル記録: ${sampleRecords.length}件`);
    console.log(`   - サンプル感謝: ${sampleThanks.length}件`);
    console.log(`   - サンプル記念日: ${sampleMilestones.length}件`);
    console.log(`   - メンバー: 1件\n`);
    console.log('🔐 次のステップ:');
    console.log('   1. Firebase Consoleで firestore.rules をデプロイ');
    console.log('   2. 必要に応じてインデックスを作成');
    console.log('   3. アプリを再起動して動作確認\n');

  } catch (error) {
    console.error('❌ エラーが発生しました:', error);
    process.exit(1);
  }

  process.exit(0);
}

// 招待コード生成（6桁の英数字）
function generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// スクリプト実行
initializeFirestore();
