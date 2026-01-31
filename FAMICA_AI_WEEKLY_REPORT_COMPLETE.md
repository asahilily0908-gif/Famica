# ✅ Famica AIふりかえりレポート機能 実装完了

## 📅 実装日時
2025年11月1日

## 🎯 概要
過去7日間の家事データから「温かく、ユーモア少し、責めない」AIふりかえりレポートを自動生成する機能を実装しました。Plus会員限定機能として提供されます。

---

## ✅ 実装完了内容

### 1. Cloud Functions (functions/index.js)

#### generateWeeklyReport関数
```javascript
exports.generateWeeklyReport = functions.https.onCall(async (data, context) => {
  // Plus会員チェック
  // 過去7日間の記録を取得
  // メンバー名（nickname優先）を取得
  // データ集計（カテゴリ別・メンバー別）
  // OpenAI APIでレポート生成
  // Firestoreに保存
});
```

**機能:**
- ✅ Plus会員のみアクセス可能
- ✅ 過去7日間の家事記録を自動集計
- ✅ ニックネーム優先で表示
- ✅ OpenAI GPT-4o-miniでレポート生成
- ✅ エラーハンドリング完備

### 2. AIService (lib/services/ai_service.dart)

#### generateWeeklyReport()
```dart
Future<String> generateWeeklyReport(String householdId) async {
  // Cloud Functions呼び出し
  // エラーハンドリング
  // Firestore保存
}
```

#### getPastWeeklyReports()
```dart
Future<List<Map<String, dynamic>>> getPastWeeklyReports(
  String householdId, {
  int limit = 5,
}) async {
  // 過去のレポートを取得
}
```

### 3. AI提案画面 (lib/screens/ai_suggestion_screen.dart)

#### 追加UI
```
┌─────────────────────────────────────┐
│ 🌿 AIふりかえりレポート             │
│ Plus限定                            │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🧾 今週のまとめ                  │ │
│ │ {ふたりの頑張りを労う}          │ │
│ │                                  │ │
│ │ 📊 バランス                      │ │
│ │ {A}% vs {B}%                    │ │
│ │                                  │ │
│ │ 🧺 家事スキル診断                │ │
│ │ ・料理 ★★★★☆                  │ │
│ │ ・洗濯 ★★★☆☆                  │ │
│ │                                  │ │
│ │ 🏅 今週のナイスタスク            │ │
│ │ {褒める}                         │ │
│ │                                  │ │
│ │ 💡 あしたのワンアクション        │ │
│ │ {提案}                           │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [ ふりかえりレポートを生成 ]        │
└─────────────────────────────────────┘
```

---

## 📋 OpenAIプロンプトテンプレート

### システムプロンプト
```
あなたはパートナー同士の生活データをやさしく振り返るAIです。
温かく・ユーモア少し・責めない口調で、
家事分担のふりかえりレポートを作成します。
```

### ユーザープロンプト
```
【入力データ】
- メンバー名（ニックネーム）：{user1}, {user2}
- 今週の家事記録：
  料理：{count}回/{minutes}分
  洗濯：{count}回/{minutes}分
  掃除：{count}回/{minutes}分
- 今週の家事バランス：{user1} {%} vs {user2} {%}

【出力フォーマット】
🌿 AIふりかえりレポート（Plus限定）

🧾 今週のまとめ
{ふたりの頑張りを1〜2文でやさしく労う}

📊 バランス
{user1} {%} vs {user2} {%}

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
```

---

## 🔄 データフロー

### レポート生成フロー
```
1. ユーザーがボタンをタップ
   ↓
2. Flutter → Cloud Functions呼び出し
   ↓
3. Cloud Functions:
   - Plus会員チェック
   - 過去7日間の記録を取得
   - メンバー名（nickname優先）を取得
   - データ集計
   ↓
4. OpenAI API呼び出し
   - プロンプト生成
   - GPT-4o-miniでレポート生成
   ↓
5. Firestoreに保存
   households/{householdId}/weeklyReports/{reportId}
   ↓
6. Flutterに返却
   ↓
7. UIに表示
```

### Firestoreデータ構造
```javascript
households/{householdId}/weeklyReports/{reportId}
{
  createdAt: timestamp,
  report: "🌿 AIふりかえりレポート...",
  type: "weekly",
  plan: "plus",
  userId: "user123"
}
```

---

## 🎨 UI/UXの特徴

### デザイン
- ✅ 緑系の配色（ふりかえり＝成長のイメージ）
- ✅ アイコン：📊 assessment
- ✅ グラデーション背景
- ✅ 「Plus限定」バッジ表示

### ユーザビリティ
- ✅ 生成中のローディング表示
- ✅ 成功時のSnackBar
- ✅ エラー時の明確なフィードバック
- ✅ 生成したレポートの美しい表示
- ✅ 行間1.8でreadability向上

---

## 🧪 テスト方法

### 1. Plus会員でテスト
```bash
flutter run
```

1. Plus会員でログイン
2. AI改善提案画面を開く
3. 「AIふりかえりレポート」セクションを確認
4. 「
