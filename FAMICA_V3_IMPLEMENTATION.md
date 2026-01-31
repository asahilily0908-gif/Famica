# 🚀 Famica v3.0 統合実装ガイド

## ✅ 実装完了項目（2025/10/14）

### Phase 1: 基盤＆記念日機能
- [x] **Firestore v3.0構造** - householdIdベース、lifeStage対応
- [x] **セキュリティルール** - 世帯メンバーのみアクセス可能
- [x] **記念日＆マイルストーン機能**
  - Milestoneモデル（日数計算・メッセージ生成）
  - Achievementモデル（達成バッジ）
  - MilestoneService（CRUD・自動生成）
  - AnniversaryCard（グラデーション背景）
  - AnniversaryListScreen（一覧・管理）

### Phase 2: クイック記録画面
- [x] **QuickRecordScreen実装**
  - 記念日バナー統合（最も近い記念日を表示）
  - lifeStage別テンプレート（couple/newlywed/baby）
  - タップ2回で記録完了
  - 時間選択モーダル（5〜120分）
  - カテゴリ別色分け

---

## 📊 実装済みデータ構造

### /users/{uid}
```typescript
{
  "displayName": "田中 花子",
  "email": "hanako@example.com",
  "householdId": "household_abc",
  "role": "妻",
  "lifeStage": "couple", // couple | newlywed | baby | child
  "plan": "free",
  "createdAt": Timestamp
}
```

### /households/{householdId}
```typescript
{
  "name": "田中家",
  "lifeStage": "couple",
  "members": [
    {"uid": "user1", "name": "花子", "role": "妻"},
    {"uid": "user2", "name": "太郎", "role": "夫"}
  ],
  "plan": "free",
  "createdAt": Timestamp
}
```

### /households/{householdId}/records/{id}
```typescript
{
  "memberId": "user1",
  "memberName": "花子",
  "category": "家事",
  "task": "料理",
  "timeMinutes": 30,
  "month": "2025-10",
  "thankedBy": ["user2"],
  "createdAt": Timestamp
}
```

### /households/{householdId}/milestones/{id}
```typescript
{
  "type": "anniversary",
  "title": "同棲記念日",
  "date": "2024-03-15",
  "icon": "💑",
  "isRecurring": true,
  "notifyDaysBefore": 3,
  "createdAt": Timestamp
}
```

### /households/{householdId}/achievements/{id}
```typescript
{
  "type": "record_100" | "thanks_100" | "streak_30",
  "value": 100,
  "badgeIcon": "🏆",
  "title": "記録マスター",
  "description": "100回の記録を達成！",
  "achievedAt": Timestamp
}
```

### /households/{householdId}/quickTemplates/{id}
```typescript
{
  "task": "料理",
  "defaultMinutes": 30,
  "category": "家事",
  "icon": "🍳",
  "order": 1,
  "lifeStage": "couple"
}
```

---

## 🎨 実装済みUI/UX

### カラーパレット（FamicaColors）
- **background**: `#FCE8EE` - 背景
- **text**: `#4A154B` - テキスト
- **accent**: `#FF6B9D` - アクセント
- **thanks**: `#FFD700` - 感謝

### カテゴリーカラー
- **家事**: `#4CAF50` - 緑
- **育児**: `#FF9800` - オレンジ
- **介護**: `#2196F3` - 青
- **その他**: `#9C27B0` - パープル

### デザイン要素
- カード角丸: 16-20px
- ボタン角丸: 16px
- グリッドスペーシング: 12px
- パディング: 16px（標準）

---

## 🧩 実装済みコンポーネント

### 1. QuickRecordScreen
**場所**: `lib/screens/quick_record_screen.dart`

**機能**:
- 記念日バナー表示（FutureBuilder）
- ユーザー情報カード
- lifeStage別テンプレートグリッド
- 時間選択モーダル
- 記録完了ダイアログ

**lifeStage別デフォルトテンプレート**:

| lifeStage | テンプレート |
|-----------|-------------|
| couple | 🍳料理 🧺洗濯 🧹掃除 🛒買い物 🗑️ゴミ出し 💧水回り |
| newlywed | 🍳料理 🧺洗濯 🧹掃除 🛒買い物 🚗車関係 📄書類手続き |
| baby | 🍼授乳 🚼おむつ替え 😴寝かしつけ 🛁お風呂 🍳離乳食 🚗送迎 |

### 2. AnniversaryCard
**場所**: `lib/components/anniversary_card.dart`

**機能**:
- グラデーション背景（日数に応じて自動変更）
- カウントダウン表示
- タップで記念日一覧へ遷移

**グラデーション**:
- 当日: ゴールド（`#FFD700` → `#FFE55C`）
- 1週間以内: ピンク（`#FF6B9D` → `#FF8FAB`）
- 1ヶ月以内: 淡いピンク
- それ以外: パープル（`#9C27B0` → `#BA68C8`）

### 3. AnniversaryListScreen
**場所**: `lib/screens/anniversary_list_screen.dart`

**機能**:
- StreamBuilderでリアルタイム表示
- 記念日追加ダイアログ（10種類アイコン選択）
- 記念日詳細表示
- 削除機能

### 4. MilestoneService
**場所**: `lib/services/milestone_service.dart`

**主要メソッド**:
```dart
// 記念日作成
Future<String> createMilestone({...})

// 記念日一覧取得
Stream<List<Milestone>> getMilestones()

// 最も近い記念日取得
Future<Milestone?> getNextMilestone()

// 達成バッジ作成
Future<String> createAchievement({...})

// 自動チェック
Future<void> checkAndCreateRecordAchievement(int totalRecords)
Future<void> checkAndCreateThanksAchievement(int totalThanks)
Future<void> checkAndCreateStreakAchievement(int streakDays)
```

---

## 📋 未実装項目（Phase 3）

### 優先度A: コア機能完成
- [ ] **感謝ダイアログ実装**
  - 絵文字選択（6種類固定）
  - メッセージ入力（オプション）
  - Firestore /thanks に保存
  - 相手に通知送信

- [ ] **MonthlySummaryScreen（ふたり画面）**
  - 月次タイトルカード「10月のふたり 💕」
  - fl_chartで円グラフ表示
  - 家事バランス表示
  - 感謝回数・記録回数
  - 記念日カード統合
  - AI提案カード（Plus限定）

- [ ] **通知機能（FCM）**
  - 記録完了通知
  - 感謝受信通知
  - 記念日3日前通知
  - 記念日当日通知

### 優先度B: オンボーディング
- [ ] **OnboardingScreen**
  - ライフステージ選択（couple/newlywed/baby/child）
  - 名前・役割入力
  - 招待コード生成（6桁ランダム）
  - スムーズなアニメーション

- [ ] **FamilyInviteScreen**
  - 招待コード入力
  - LINEシェア機能
  - メールシェア機能
  - メンバー一覧表示

### 優先度C: 収益化
- [ ] **ペイウォール画面**
  - Plus機能リスト表示
  - 月払い/年払い選択
  - 7日間トライアル表記
  - 購入フロー実装

- [ ] **AI提案機能（ルールベース）**
  - 時間帯分析
  - バランス判定
  - 提案文生成
  - Plus限定ゲート

### 優先度D: 拡張機能
- [ ] **SNS共有画像生成**
  - 記念日画像
  - 月次レポート画像
  - バッジ獲得画像

- [ ] **詳細レポート機能**
  - 過去6ヶ月の推移
  - カテゴリ別分析
  - 時間帯分析

---

## 🚀 デプロイ手順

### 1. Firestoreルールのデプロイ
```bash
firebase deploy --only firestore:rules
```

**期待される出力**:
```
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

### 2. アプリの実行
```bash
# 依存関係のインストール
flutter pub get

# アプリ起動
flutter run
```

### 3. 動作確認チェックリスト
- [ ] ログイン成功
- [ ] クイック記録画面が表示される
- [ ] 記念日バナーが表示される（記念日がない場合は「記念日を追加」）
- [ ] lifeStageに応じたテンプレートが表示される
- [ ] タップで時間選択モーダルが表示される
- [ ] 記録が成功する
- [ ] 記録一覧画面に反映される
- [ ] 記念日一覧画面に遷移できる
- [ ] 記念日を追加できる
- [ ] Firebase Consoleでデータを確認できる

---

## 🔍 トラブルシューティング

### エラー: "lifeStage取得エラー"
**原因**: usersドキュメントにlifeStageフィールドがない  
**解決**: 
1. Firebase Consoleで `/users/{uid}` を確認
2. `lifeStage: "couple"` フィールドを追加
3. アプリを再起動

### エラー: "householdId取得エラー"
**原因**: usersドキュメントにhouseholdIdフィールドがない  
**解決**:
1. Firebase Consoleで `/users/{uid}` を確認
2. `householdId: "{uid}"` フィールドを追加（初期値は自分のUID）
3. アプリを再起動

### テンプレートが表示されない
**原因**: quickTemplatesコレクションが空  
**解決**: デフォルトテンプレートが自動表示されます（コード内で定義済み）

### 記念日バナーが表示されない
**原因**: milestonesコレクションが空  
**解決**: 記念日一覧画面から記念日を追加してください

---

## 📚 関連ドキュメント

- **FAMICA_ANNIVERSARY_FEATURE.md** - 記念日機能詳細仕様
- **FAMICA_V3_MIGRATION.md** - v3.0移行ガイド
- **FIRESTORE_SETUP.md** - Firestore初期化手順
- **firestore.rules** - セキュリティルール

---

## 🎯 次のステップ

### 今すぐできること
1. **Firestoreルールのデプロイ**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **アプリの動作確認**
   ```bash
   flutter run
   ```

3. **記念日を追加**
   - クイック記録画面の記念日バナーをタップ
   - 「＋」ボタンで記念日追加
   - タイトル・アイコン・日付を入力

### Phase 3で実装すべき項目（優先順位順）
1. 感謝ダイアログ（記録後のフロー完成）
2. MonthlySummaryScreen（月次サマリー）
3. FCM通知（感謝・記念日通知）
4. OnboardingScreen（初回セットアップ）
5. FamilyInviteScreen（パートナー招待）

---

## ✨ 実装のハイライト

### 🎨 lifeStage別デザイン
ユーザーのライフステージに応じて、最適なテンプレートを自動表示：
- **同棲カップル**: 家事中心（料理・洗濯・掃除）
- **新婚夫婦**: 家事＋生活（車関係・書類手続き）
- **乳幼児育児**: 育児中心（授乳・おむつ・寝かしつけ）

### 🎉 記念日の差別化
- 日数に応じたグラデーション自動変更
- カウントダウン表示でワクワク感
- 達成バッジ自動生成（100回記録、100回感謝、30日連続）

### 🚀 UX最適化
- タップ2回で記録完了（高速入力）
- デフォルト時間を強調表示（迷わない）
- 記録完了後に感謝ダイアログ（自然な流れ）

---

## 🎉 Phase 1+2 完了！

QuickRecordScreen実装により、Famica v3.0のコア機能が動作するようになりました。

**実装済み**:
- ✅ 記念日＆マイルストーン機能
- ✅ クイック記録画面（lifeStage対応）
- ✅ 記念日バナー統合
- ✅ Firestore v3.0構造
- ✅ セキュリティルール

**次のマイルストーン**:
感謝ダイアログと月次サマリー画面を実装し、Famicaのコア体験を完成させましょう！

---

*Last Updated: 2025/10/14*  
*Version: 3.0*  
*Status: Phase 1+2 Complete*
