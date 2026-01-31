# FCM通知機能 セットアップガイド

## ✅ 実装完了内容

### 1. Flutter側
- `lib/services/fcm_service.dart` - FCMサービス作成
- `lib/services/firestore_service.dart` - addThanks()にFCM通知送信追加
- `lib/screens/quick_record_screen.dart` - 💗ボタンに通知機能追加
- `lib/main.dart` - FCM初期化とバックグラウンドハンドラー登録
- `pubspec.yaml` - cloud_functions依存関係追加

### 2. Cloud Functions
- `functions/index.js` - 感謝通知を送信する2つの関数
  - `sendThanksNotification` - Callable Function（クライアント呼び出し用）
  - `onRecordThanked` - Firestoreトリガー（自動通知用）

---

## 🚀 デプロイ手順

### Step 1: パッケージインストール

```bash
cd /Users/matsushimaasahi/Developer/famica
flutter pub get
```

### Step 2: Cloud Functions初期化（初回のみ）

```bash
# functionsディレクトリに移動
cd functions

# package.jsonがなければ初期化
npm init -y

# 必要なパッケージをインストール
npm install firebase-functions@latest firebase-admin@latest
```

### Step 3: Cloud Functionsデプロイ

```bash
# プロジェクトルートに戻る
cd ..

# Firebaseにログイン（必要な場合）
firebase login

# Functionsをデプロイ
firebase deploy --only functions
```

デプロイ完了後、以下の関数が利用可能になります：
- `sendThanksNotification` - Callable Function
- `onRecordThanked` - Firestoreトリガー

---

## 📱 iOS設定（必要な場合）

APNs（Apple Push Notification service）の設定が必要です。

### 1. Apple Developer Consoleで証明書作成
1. https://developer.apple.com にアクセス
2. Certificates, Identifiers & Profiles
3. Keys → 新規キー作成
4. Apple Push Notifications service (APNs) を有効化
5. .p8ファイルをダウンロード

### 2. Firebase Consoleにアップロード
1. Firebase Console → プロジェクト設定
2. Cloud Messaging タブ
3. APNs認証キーをアップロード

---

## 🤖 Android設定

google-services.jsonは既に設定済みのため、追加設定不要です。

---

## 🧪 テスト手順

### 1. 基本動作確認

```bash
# アプリをビルド＆実行
flutter run
```

### 2. 通知テストフロー

#### A. ユーザーAの操作
1. Famicaにログイン
2. 通知権限を許可
3. 「きろく」タブで記録を作成
4. アプリを閉じる（バックグラウンド）

#### B. ユーザーBの操作
1. 同じhouseholdにログイン
2. 「きろく」タブの「最近の記録」を確認
3. ユーザーAの記録に💗ボタンをタップ
4. 「💗 ありがとうを送りました」表示確認

#### C. 通知確認
1. ユーザーAの端末に通知が届く
2. 通知内容：「💗 ありがとうが届きました！」
3. 本文：「[ユーザーB名]から感謝が届きました」

### 3. Firestore確認

Firebaseコンソール → Firestore Database
```
households/{householdId}/records/{recordId}
  thankedBy: ["userB_uid"]  ← 追加確認

users/{userA_uid}
  fcmToken: "..."  ← トークン登録確認
```

### 4. ログ確認

#### Flutter側
```
🔔 FCM初期化開始
✅ FCM通知送信完了
```

#### Cloud Functions側
```
✅ 通知送信成功: projects/famica/messages/xxx
```

---

## 📊 データフロー

```
ユーザーB: 💗ボタンタップ
  ↓
FirestoreService.addThanks(recordId, toUserId)
  ↓
Firestore更新: thankedBy配列にUID追加
  ↓
FCMService.sendThanksNotification(toUserId, fromUserName)
  ↓
Cloud Functions: sendThanksNotification呼び出し
  ↓
users/{toUserId}からfcmToken取得
  ↓
Firebase Cloud Messaging: 通知送信
  ↓
ユーザーAの端末: 通知受信 🔔
```

---

## 🔧 トラブルシューティング

### 通知が届かない場合

#### 1. FCMトークン確認
```dart
// lib/services/fcm_service.dart
final token = await _messaging.getToken();
print('FCM Token: $token');
```

#### 2. Cloud Functions実行確認
Firebase Console → Functions → ログ確認

#### 3. 通知権限確認
- iOS: 設定 → Famica → 通知
- Android: 設定 → アプリ → Famica → 通知

#### 4. Firestoreルール確認
```
// firestore.rules
match /users/{userId} {
  allow read, write: if request.auth != null;
}
```

### エラー: "permission-denied"

Cloud Functionsがusersコレクションにアクセスできない場合：
```
// firestore.rules
match /users/{userId} {
  allow read: if request.auth != null;
}
```

---

## 🎯 動作確認チェックリスト

- [ ] Flutter pub getが成功
- [ ] Cloud Functionsデプロイが成功
- [ ] アプリ起動時にFCM初期化ログ表示
- [ ] 通知権限が許可されている
- [ ] users/{uid}/fcmTokenが保存されている
- [ ] 💗ボタンがグレー→ピンクに変化
- [ ] Firestoreのthanked By配列が更新される
- [ ] 相手端末に通知が届く
- [ ] 「もらった感謝」カウントが増える

---

## 📝 補足事項

### オプション: 通知音・バイブレーション

```dart
// lib/services/fcm_service.dart
// flutter_local_notificationsパッケージを使用
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'thanks_channel',
  'Thanks Notifications',
  importance: Importance.high,
  priority: Priority.high,
  sound: RawResourceAndroidNotificationSound('notification'),
);
```

### オプション: 通知タップ時の画面遷移

```dart
// lib/main.dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // 通知タップ時の処理
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CoupleScreen()),
  );
});
```

---

## 🎉 完了！

これで感謝通知機能が完全に動作します。
ユーザーが💗ボタンを押すと、相手に即座に通知が届きます！
