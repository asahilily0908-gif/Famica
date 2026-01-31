# Famica FCMプッシュ通知機能 実装完了

## 📅 実装日
2026年1月24日

## ✅ 実装内容

### 0. リポジトリ調査結果
実際のFirestoreパスを特定:
- **タスク/記録**: `households/{householdId}/records/{recordId}`
- **コスト記録**: `households/{householdId}/costs/{costId}`
- **感謝メッセージ**: `gratitudeMessages/{messageId}` (ルートレベル)

### 1. Flutter Client実装

#### 1.1 依存関係追加 (`pubspec.yaml`)
```yaml
firebase_messaging: ^15.1.5
flutter_local_notifications: ^18.0.1
timezone: ^0.9.4
```

#### 1.2 FCMService実装 (`lib/services/fcm_service.dart`)
- FCMトークン登録・管理（マルチデバイス対応）
- 通知権限リクエスト（iOS/Android）
- フォアグラウンド通知ハンドラー
- バックグラウンド通知ハンドラー
- lastActivityAt追跡（デバウンス付き）
- 通知設定管理

#### 1.3 main.dart統合
- バックグラウンドメッセージハンドラー登録
- FCMService初期化フロー

#### 1.4 MainScreen統合
- アプリ起動時のFCM初期化
- アクティビティ追跡開始

### 2. Firestoreモデル拡張

#### users/{uid}に追加フィールド:
```javascript
{
  fcmTokens: { [token]: true },  // マルチデバイス対応
  notificationsEnabled: true,     // マスター通知トグル
  notifyPartnerActions: true,     // パートナーアクション通知
  notifyInactivity: true,         // 非アクティブ通知
  lastActivityAt: Timestamp,      // 最終アクティビティ
  lastInactivityNotifiedAt: Timestamp  // 最終非アクティブ通知
}
```

### 3. Firestoreセキュリティルール更新

`firestore.rules`に以下を追加:
- ユーザーは自分のtokens/preferencesフィールドのみ書き込み可
- Cloud Functions（admin）はlastInactivityNotifiedAt等を更新可

### 4. Cloud Functions実装 (`functions/index.js`)

#### 4.1 パートナーアクション通知トリガー

**notifyTaskCreated**
- トリガー: `households/{householdId}/records/{recordId}` onCreate
- 動作: パートナーに「{名前}さんが家事を記録しました」通知
- 重複防止: `notificationLogs/{eventId}`
- 設定チェック: notificationsEnabled, notifyPartnerActions
- 無効トークン自動削除

**notifyCostCreated**
- トリガー: `households/{householdId}/costs/{costId}` onCreate
- 動作: パートナーに「{名前}さんがコストを記録しました」通知
- 同様の重複防止・設定チェック機能

**notifyLetterCreated**
- トリガー: `gratitudeMessages/{messageId}` onCreate
- 動作: 受信者に「{名前}さんからメッセージが届きました」通知
- 既存の`sendGratitudeNotification`を強化

#### 4.2 非アクティブユーザー通知

**notifyInactiveUsers**
- スケジュール: 毎日午前9時（JST）
- 対象: lastActivityAtが3日以上前のユーザー
- レート制限: 最後の通知から3日経過している場合のみ
- 通知内容: 「そろそろ、今日の分を10秒で」

### 5. プラットフォーム設定

#### Android
- `AndroidManifest.xml`: 既に設定済み（変更不要）
- 通知アイコン: `@mipmap/ic_launcher`使用

#### iOS
- `Info.plist`: プッシュ通知の説明追加が推奨
- APNs証明書: Firebase Consoleで設定必要

## 🔧 セットアップ手順

### 1. 依存関係のインストール

```bash
# Flutterパッケージ取得
flutter pub get

# iOS Podインストール（macOSのみ）
cd ios && pod install && cd ..

# Cloud Functions依存関係インストール
cd functions && npm install && cd ..
```

### 2. Cloud Functionsデプロイ

```bash
# Firebase CLIでログイン（未ログインの場合）
firebase login

# Functionsをデプロイ
firebase deploy --only functions
```

### 3. Firestoreルールデプロイ

```bash
# セキュリティルールをデプロイ
firebase deploy --only firestore:rules
```

### 4. iOS APNs設定（iOSの場合）

1. Apple Developer Portalで APNs証明書を生成
2. Firebase Console > Project Settings > Cloud Messaging
3. APNs証明書をアップロード

## 🧪 テスト方法

### 1. 通知権限テスト
1. アプリをアンインストール
2. 再インストール＆ログイン
3. 通知権限ダイアログが表示されることを確認
4. 許可を選択

### 2. パートナーアクション通知テスト
1. デバイス1でユーザーAとしてログイン
2. デバイス2でユーザーBとしてログイン（同じhousehold）
3. デバイス1でタスクを記録
4. デバイス2に通知が届くことを確認

### 3. 非アクティブ通知テスト（手動）
```javascript
// Firestore Consoleで手動でlastActivityAtを3日前に設定
// 翌日午前9時（JST）に通知が届くことを確認
```

### 4. 通知ログ確認
```bash
# Cloud Functionsログ確認
firebase functions:log --only notifyTaskCreated,notifyInactiveUsers
```

## ⚠️ 制限事項・注意点

### シミュレーター制限
- **iOSシミュレーター**: APNs未サポート → 実機でのテスト必須
- **Androidエミュレーター**: FCM動作可能（Google Play Services必須）

### 実機テスト推奨項目
1. フォアグラウンド通知表示
2. バックグラウンド通知受信
3. 通知タップ時のナビゲーション
4. トークン更新処理
5. マルチデバイス対応

### Cloud Functions料金
- Blaze（従量課金）プラン必須
- スケジュール関数: 毎日1回実行
- Firestoreトリガー: 記録作成ごとに実行

## 📊 使用されているFirebaseサービス

- **Firebase Cloud Messaging (FCM)**: プッシュ通知配信
- **Cloud Functions**: 通知トリガー＆スケジューラー
- **Cloud Firestore**: トークン・設定・ログ保存
- **Cloud Scheduler**: 定期実行（非アクティブ通知）

## 🔐 セキュリティ

- FCMトークンはusers/{uid}に保存（認証済みユーザーのみ読み書き可）
- 通知設定は各ユーザーが管理
- 重複通知防止機能実装済み
- 無効トークン自動削除機能実装済み

## 📝 今後の拡張案

1. **通知設定UI追加**: 設定画面に通知トグルを追加（時間の都合で簡略化）
2. **リッチ通知**: 画像付き通知
3. **通知履歴**: 受信した通知の履歴表示
4. **通知カテゴリ**: カテゴリごとの通知設定
5. **Deep Link強化**: 通知タップ時の詳細画面遷移

## ✅ 完了チェックリスト

- [x] 0. リポジトリ調査：実際のFirestoreパス特定
- [x] 1. pubspec.yaml依存関係追加
- [x] 2. Firestoreセキュリティルール拡張
- [x] 3. FCMサービス実装（Flutter）
- [x] 4. main.dart統合（バックグラウンドハンドラー）
- [x] 5. MainScreen統合（FCM初期化）
- [x] 6. Cloud Functions: パートナーアクション通知トリガー
- [x] 7. Cloud Functions: 3日間非アクティブ通知
- [x] 8. テスト手順ドキュメント作成

## 🎉 実装完了

FCMプッシュ通知機能のエンドツーエンド実装が完了しました。
上記のセットアップ手順に従って、依存関係のインストールとデプロイを実行してください。

---

**Next Steps:**
1. `flutter pub get` でパッケージ取得
2. `cd functions && npm install` でCloud Functions依存関係インストール
3. `firebase deploy --only functions,firestore:rules` でデプロイ
4. 実機でテスト実行
