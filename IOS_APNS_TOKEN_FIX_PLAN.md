# iOS APNSトークンエラー修正プラン

## 🔍 調査結果

### エラー
```
[firebase_messaging/apns-token-not-set] APNS token has not been set yet.
```

---

## ✅ 確認済み項目（問題なし）

### 1. Runner.entitlements ✅
**ファイル**: `ios/Runner/Runner.entitlements`

```xml
<key>aps-environment</key>
<string>development</string>
```

- ✅ aps-environment が正しく設定されている
- ⚠️ 本番リリース時は`production`に変更が必要

### 2. Info.plist ✅
**ファイル**: `ios/Runner/Info.plist`

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
<key>NSUserNotificationsUsageDescription</key>
<string>記念日や感謝の通知を受け取るために使用します</string>
```

- ✅ remote-notification が有効
- ✅ 通知権限説明文あり

### 3. AppDelegate.swift ✅
**ファイル**: `ios/Runner/AppDelegate.swift`

```swift
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  GeneratedPluginRegistrant.register(with: self)
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

- ✅ シンプルな実装（Firebase初期化はFlutter側）
- ✅ `super.application()` が呼ばれている

---

## ❌ 問題発見

### **主な原因: APNSトークンを明示的に取得していない**

**ファイル**: `lib/services/fcm_service.dart`

**現状のコード**:
```dart
Future<void> _setupToken() async {
  final token = await _messaging.getToken();  // ← FCMトークンのみ
  // ...
}
```

**問題点**:
1. ❌ **iOS では先に `getAPNSToken()` を呼ぶ必要がある**
2. ❌ APNSトークン取得のログ出力がない
3. ❌ APNSトークンが null の場合のハンドリングがない

---

## ⚠️ Info.plistに追加推奨

現在 `FirebaseAppDelegateProxyEnabled` の明示的な設定がありません。
デフォルトでは `true` ですが、明示的に設定することを推奨します。

---

## 🔧 修正コード

### 1. Info.plist に追加

**ファイル**: `ios/Runner/Info.plist`

`</dict>` の直前に以下を追加：

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<true/>
```

### 2. fcm_service.dart を修正

**ファイル**: `lib/services/fcm_service.dart`

**変更箇所**: `_setupToken()` メソッド

```dart
/// トークンを取得してFirestoreに登録
Future<void> _setupToken() async {
  final user = _auth.currentUser;
  if (user == null) {
    print('⚠️ ユーザー未認証のためトークン登録スキップ');
    return;
  }

  try {
    // ========================================
    // iOS: 先にAPNSトークンを取得（重要）
    // ========================================
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        print('🍎 APNSトークン取得成功: ${apnsToken.substring(0, 20)}...');
      } else {
        print('⚠️ APNSトークンを取得できませんでした');
        print('   → 実機で実行していることを確認してください');
        print('   → Xcodeで Push Notifications capability が有効か確認してください');
        
        // APNSトークンがない場合、再試行（最大3回、1秒間隔）
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(seconds: 1));
          final retryToken = await _messaging.getAPNSToken();
          if (retryToken != null) {
            print('🍎 APNSトークン取得成功（再試行 ${i + 1}回目）');
            break;
          }
        }
      }
    }

    // ========================================
    // FCMトークンを取得
    // ========================================
    final token = await _messaging.getToken();
    if (token == null) {
      print('⚠️ FCMトークンを取得できませんでした');
      return;
    }

    _currentToken = token;
    print('📱 FCMトークン取得: ${token.substring(0, 20)}...');

    // Firestoreに保存
    await _saveTokenToFirestore(token);

    // デフォルト設定を初期化（既存の場合はスキップ）
    await _initializeDefaultSettings();
  } catch (e) {
    print('❌ トークン取得エラー: $e');
  }
}
```

**追加import**:
```dart
import 'package:flutter/foundation.dart';  // ← 既にあるか確認
```

---

## 📋 実装手順（ステップバイステップ）

### ステップ1: Info.plist修正
```bash
# ios/Runner/Info.plist を開く
code ios/Runner/Info.plist

# </dict> の直前に以下を追加：
# <key>FirebaseAppDelegateProxyEnabled</key>
# <true/>
```

### ステップ2: fcm_service.dart修正
```bash
# lib/services/fcm_service.dart を開く
code lib/services/fcm_service.dart

# _setupToken() メソッドを上記のコードに置き換え
```

### ステップ3: クリーンビルド
```bash
# iOSプロジェクトをクリーン
cd ios
pod deintegrate
pod install
cd ..

# Flutterもクリーン
flutter clean
flutter pub get
```

### ステップ4: **実機で実行（重要）**
```bash
# シミュレータではAPNSトークンが取得できません
flutter run --release
# または
flutter run --debug

# 実機を接続してから実行すること
```

### ステップ5: ログ確認
アプリ起動時に以下のログが表示されるはずです：

**成功例**:
```
🔔 FCMService: 初期化開始...
✅ ローカル通知プラグイン初期化完了
🔔 通知権限: AuthorizationStatus.authorized
🍎 APNSトークン取得成功: d1e8f72b3a4c5d6e...
📱 FCMトークン取得: eA3bC9dF2g8H1iJ5...
✅ FCMトークン保存完了
✅ デフォルト通知設定を初期化
✅ FCMService: 初期化完了
```

**失敗例（修正前）**:
```
🔔 FCMService: 初期化開始...
⚠️ FCMトークンを取得できませんでした
[firebase_messaging/apns-token-not-set] APNS token has not been set yet.
```

---

## 🧪 テスト方法

### 1. APNSトークン確認
```dart
// main.dartまたはホーム画面で以下を実行
final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
print('APNSトークン: $apnsToken');
```

### 2. FCMトークン確認
```dart
final fcmToken = await FirebaseMessaging.instance.getToken();
print('FCMトークン: $fcmToken');
```

### 3. テスト通知送信
Firebase Consoleから手動でテスト通知を送信：
1. Firebase Console → Cloud Messaging
2. 「Send test message」
3. FCMトークンを入力
4. 実機に通知が届くか確認

---

## ⚠️ よくある問題と解決策

### Q1: シミュレータでテストできますか？
**A**: ❌ **できません**。APNSはシミュレータで動作しません。必ず実機でテストしてください。

### Q2: Development証明書は必要ですか？
**A**: ✅ 必要です。Xcodeで正しいProvisioning Profileが設定されていることを確認してください。

### Q3: aps-environment は本番でも development のままでいいですか？
**A**: ❌ 本番リリース時は `production` に変更してください。または、Releaseビルド用に別のEntitlementsファイルを作成してください。

### Q4: それでもトークンが取得できない場合は？
**A**: 以下を確認してください：
1. Xcodeで Push Notifications capability が有効か
2. Apple Developer Portalで App ID に Push Notifications が有効か
3. GoogleService-Info.plist が正しくプロジェクトに含まれているか
4. Firebase Consoleで iOS アプリが登録されているか
5. APNs認証キーまたは証明書がFirebase Consoleにアップロードされているか

---

## 🎯 本番リリース時の追加対応

### 1. aps-environment を production に変更

**方法1: 手動で2つのEntitlementsファイルを作成**
- Runner.entitlements (development用)
- Runner-Release.entitlements (production用)

**方法2: build configuration で自動切り替え**
Xcodeの Build Settings で条件分岐

### 2. APNs証明書/認証キーをFirebaseに登録
Firebase Console → Project Settings → Cloud Messaging → iOS app configuration

---

## 📚 参考資料

- [Firebase Messaging - iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [FlutterFire - Messaging iOS Integration](https://firebase.flutter.dev/docs/messaging/apple-integration)
- [Apple - Registering Your App with APNs](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns)

---

**実装完了日**: 2026年1月24日  
**対象プラットフォーム**: iOS  
**重要度**: 高（APNSトークンなしではiOS通知が一切機能しない）  
**テスト必須**: 実機での動作確認
