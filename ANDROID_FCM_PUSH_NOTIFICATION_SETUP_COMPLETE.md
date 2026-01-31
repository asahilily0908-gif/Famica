# Android FCM通知セットアップ完了レポート

## 📋 実装サマリー

**実装日**: 2026年1月25日  
**対象**: Android FCM プッシュ通知  
**ステータス**: ✅ 完了

---

## 🔧 修正ファイル一覧

### 1. android/app/src/main/AndroidManifest.xml
**変更内容**: FCM必須権限の追加

```xml
<!-- 追加した権限 -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> <!-- Android 13+ -->
```

**理由**:
- `INTERNET`: FCM通信に必須
- `WAKE_LOCK`: バックグラウンド通知受信に必須
- `POST_NOTIFICATIONS`: Android 13+ (API Level 33) で通知表示に必須

---

### 2. android/app/src/main/kotlin/com/matsushima/famica/MainActivity.kt
**変更内容**: 通知チャネル作成

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    createNotificationChannel()
}

private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channelId = "famica_main_channel"
        val channelName = "Famica通知"
        val importance = NotificationManager.IMPORTANCE_HIGH
        
        val channel = NotificationChannel(channelId, channelName, importance).apply {
            description = "Famicaからのお知らせ"
            enableLights(true)
            enableVibration(true)
        }
        
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.createNotificationChannel(channel)
    }
}
```

**理由**:
- Android 8.0 (API Level 26) 以降では通知チャネルが必須
- `IMPORTANCE_HIGH`: 通知音・バイブレーション・ヘッドアップ表示を有効化

---

### 3. lib/services/fcm_service.dart
**変更内容**: FCMトークンログの強化

```dart
print('📱 FCMトークン取得成功:');
print('   トークン長: ${token.length}文字');
print('   先頭20文字: ${token.substring(0, 20)}...');
if (kDebugMode) {
  print('🔑 完全なFCMトークン（コピーしてFirebase Consoleで使用）:');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print(token);
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
```

**理由**:
- デバッグ時に完全なトークンをコピー可能にする
- Firebase Consoleでのテスト通知送信を容易にする

---

## ✅ 既存の正しい設定（確認済み）

### 1. Firebase設定
- ✅ `android/app/google-services.json` 存在確認
  - package_name: `com.matsushima.famica`
  - project_id: `famica-9b019`
  - project_number: `273365767591`

### 2. Gradle設定
- ✅ `android/app/build.gradle.kts`
  ```kotlin
  plugins {
      id("com.google.gms.google-services")
  }
  ```
- ✅ applicationId: `com.matsushima.famica`

### 3. FCMService実装
- ✅ トークン取得・保存: `users/{uid}/fcmTokens`
- ✅ 通知権限リクエスト（Android 13+対応）
- ✅ フォアグラウンド通知ハンドラー
- ✅ バックグラウンド通知ハンドラー（main.dartで登録済み）

### 4. Cloud Functions
- ✅ `notifyTaskCreated` - デプロイ済み
- ✅ `notifyCostCreated` - デプロイ済み
- ✅ `notifyLetterCreated` - デプロイ済み
- ✅ `notifyInactiveUsers` - デプロイ済み

---

## 🧪 テスト手順

### 準備: アプリのビルド＆インストール

```bash
# 1. クリーンビルド
flutter clean
flutter pub get

# 2. Androidデバイス/エミュレータでビルド＆実行
flutter run --debug
# または
flutter run --release
```

---

### ステップ1: FCMトークンの取得

1. **アプリを起動してログイン**
2. **ログコンソールを確認**

期待されるログ出力:
```
🔔 FCMService: 初期化開始...
✅ ローカル通知プラグイン初期化完了
🔔 通知権限: AuthorizationStatus.authorized
📱 FCMトークン取得成功:
   トークン長: 163文字
   先頭20文字: cXYz1234AbCd5678...
🔑 完全なFCMトークン（コピーしてFirebase Consoleで使用）:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cXYz1234AbCd5678EfGh9012IjKl3456MnOp7890...（完全なトークン）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ FCMトークン保存完了
✅ デフォルト通知設定を初期化
✅ FCMService: 初期化完了
```

3. **完全なFCMトークンをコピー**
   - ログから `━━━━` の間のトークン全体をコピーする

---

### ステップ2: Firebase Consoleからテスト通知を送信

#### 方法1: Firebase Console UI

1. **Firebase Console にアクセス**
   - https://console.firebase.google.com/project/famica-9b019/messaging

2. **「新しいキャンペーン」→「通知」をクリック**

3. **通知内容を入力**
   - 通知タイトル: `テスト通知`
   - 通知テキスト: `Firebase Consoleからの送信テスト`

4. **「テストメッセージを送信」をクリック**

5. **FCMトークンを入力**
   - ステップ1でコピーしたトークンを貼り付け
   - 「+」ボタンをクリック

6. **「テスト」をクリック**

---

#### 方法2: Cloud Functionsによる自動通知（実際の運用）

1. **2台のデバイスで同じ世帯にログイン**
   - デバイスA: ユーザー1
   - デバイスB: ユーザー2

2. **デバイスAでタスクを記録**
   - 例: 「掃除 30分」を記録

3. **デバイスBで通知を確認**
   - 通知バーに表示: 「ユーザー1さんが家事を記録しました」
   - 通知音・バイブレーション

4. **デバイスAでコストを記録**
   - 例: 「¥1,000 食費」を記録

5. **デバイスBで通知を確認**
   - 通知バーに表示: 「ユーザー1さんがコストを記録しました」

6. **デバイスAから感謝メッセージを送信**

7. **デバイスBで通知を確認**
   - 通知バーに表示: 「ユーザー1さんからメッセージが届きました」

---

### ステップ3: 各シナリオでの動作確認

#### シナリオ1: フォアグラウンド通知
- **状態**: アプリが開いている状態
- **期待動作**: 
  - ローカル通知が画面上部に表示される
  - 通知音・バイブレーション
  - ログ: `📨 フォアグラウンド通知受信`

#### シナリオ2: バックグラウンド通知
- **状態**: アプリがバックグラウンド（ホーム画面やタスク切替）
- **期待動作**:
  - 通知バーに通知が表示される
  - 通知音・バイブレーション
  - ログ: `🌙 バックグラウンド通知受信`

#### シナリオ3: ロック画面通知
- **状態**: デバイスがロック中
- **期待動作**:
  - ロック画面に通知が表示される
  - 画面が点灯する
  - 通知音・バイブレーション

#### シナリオ4: 通知タップ
- **状態**: 通知バーから通知をタップ
- **期待動作**:
  - アプリが起動する（既に起動していればフォアグラウンドに）
  - ログ: `🔔 通知ナビゲーション: type=task, docId=...`
  - （TODO: 実装予定）該当画面へのディープリンク

---

## 🔍 トラブルシューティング

### ❌ 問題1: FCMトークンが取得できない

**ログ**:
```
⚠️ FCMトークンを取得できませんでした
```

**原因と解決策**:

1. **google-services.json が正しくない**
   ```bash
   # 確認
   cat android/app/google-services.json
   # package_name が "com.matsushima.famica" であることを確認
   ```

2. **Google Play Services がインストールされていない（エミュレータ）**
   - エミュレータで Google Play Services 有効なイメージを使用
   - または実機を使用

3. **ネットワーク接続がない**
   - Wi-Fi/モバイルデータが有効か確認

---

### ❌ 問題2: Android 13+ で通知が表示されない

**原因**: `POST_NOTIFICATIONS` 権限が許可されていない

**解決策**:
1. **設定 → アプリ → Famica → 通知 → 許可**
2. または
   ```dart
   // アプリ起動時に自動で権限リクエストが実行される
   // FCMService.initialize() で requestPermission() を呼び出し済み
   ```

---

### ❌ 問題3: 通知が音・バイブレーションなしで表示される

**原因**: 通知チャネルの重要度が低い

**解決策**:
1. **アプリをアンインストール＆再インストール**
   ```bash
   flutter clean
   flutter run
   ```
   → 通知チャネルが `IMPORTANCE_HIGH` で再作成される

2. または**設定から手動で変更**
   - 設定 → アプリ → Famica → 通知 → Famica通知 → 重要度 → 緊急

---

### ❌ 問題4: バックグラウンドで通知が届かない

**原因**: バッテリー最適化

**解決策**:
1. **バッテリー最適化を無効化**
   - 設定 → アプリ → Famica → バッテリー → 制限なし

2. **自動起動を許可**
   - 設定 → アプリ → Famica → 自動起動 → ON（機種により異なる）

---

## 📱 動作確認チェックリスト

### 基本動作
- [ ] FCMトークンが取得できる
- [ ] Firestoreに `users/{uid}/fcmTokens` が保存される
- [ ] アプリ再起動後もトークンが保持される

### 通知表示
- [ ] フォアグラウンドで通知が表示される
- [ ] バックグラウンドで通知が表示される
- [ ] ロック画面で通知が表示される
- [ ] 通知音が鳴る
- [ ] バイブレーションが動作する

### Cloud Functions連携
- [ ] タスク記録時にパートナーに通知が届く
- [ ] コスト記録時にパートナーに通知が届く
- [ ] 感謝メッセージ送信時にパートナーに通知が届く

### エッジケース
- [ ] 同じタスクを2回連続で記録しても2回通知が届く
- [ ] 通知設定でOFF にすると通知が届かない
- [ ] 複数デバイスで同時にログインしても正常に動作する

---

## 🚀 次のステップ（オプション）

### 1. 通知アイコンのカスタマイズ
現在はデフォルトアイコン（`@mipmap/ic_launcher`）を使用。
専用の通知アイコンを追加する場合：

```
android/app/src/main/res/
  ├─ drawable-mdpi/ic_notification.png (24x24)
  ├─ drawable-hdpi/ic_notification.png (36x36)
  ├─ drawable-xhdpi/ic_notification.png (48x48)
  ├─ drawable-xxhdpi/ic_notification.png (72x72)
  └─ drawable-xxxhdpi/ic_notification.png (96x96)
```

FCMService内で変更:
```dart
const androidDetails = AndroidNotificationDetails(
  'famica_main_channel',
  'Famica通知',
  icon: 'ic_notification', // ← 追加
  ...
);
```

---

### 2. ディープリンク実装
通知タップ時に特定画面に遷移：

```dart
void _handleNotificationNavigation(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  
  switch (type) {
    case 'task':
      // GoRouter.of(context).go('/records');
      break;
    case 'cost':
      // GoRouter.of(context).go('/cost_record');
      break;
    case 'letter':
      // GoRouter.of(context).go('/letter');
      break;
  }
}
```

---

### 3. 通知バッジカウント
未読通知数をアプリアイコンに表示：

```dart
// flutter_app_badger パッケージを使用
FlutterAppBadger.updateBadgeCount(unreadCount);
```

---

## 📊 Firebase Console確認項目

### 1. Cloud Messaging
https://console.firebase.google.com/project/famica-9b019/messaging

- 送信済み通知の統計
- 配信率・開封率

### 2. Cloud Functions ログ
https://console.firebase.google.com/project/famica-9b019/functions/logs

```
✅ 通知送信完了: {uid} (1/1)
```

### 3. Firestore データ
`users/{uid}` ドキュメント:
```json
{
  "fcmTokens": {
    "cXYz1234...": true
  },
  "notificationsEnabled": true,
  "notifyPartnerActions": true,
  "notifyInactivity": true,
  "lastActivityAt": Timestamp
}
```

`households/{householdId}/notificationLogs` コレクション:
```json
{
  "task_{recordId}": {
    "type": "task",
    "docId": "...",
    "actorUid": "...",
    "createdAt": Timestamp
  }
}
```

---

## 📚 関連ドキュメント

- `FCM_NOTIFICATION_SETUP.md` - FCM全体設計
- `FAMICA_FCM_PUSH_NOTIFICATION_COMPLETE.md` - Flutter実装完了レポート
- `IOS_APNS_TOKEN_FIX_PLAN.md` - iOS APNSトークン修正プラン
- `FCM_GRATITUDE_SECURITY_PATCH_COMPLETE.md` - セキュリティパッチ詳細

---

## ✅ 完了確認

- [x] AndroidManifest.xml に権限追加
- [x] MainActivity に通知チャネル作成
- [x] FCMService にトークンログ強化
- [x] google-services.json 確認
- [x] Gradle設定確認
- [x] Cloud Functions デプロイ済み
- [x] テスト手順ドキュメント作成

---

**実装完了日**: 2026年1月25日 01:05  
**実装者**: Senior Flutter + Firebase Engineer  
**ステータス**: ✅ Android通知システム完全実装完了  
**次のアクション**: 実機/エミュレータでのテスト実施
