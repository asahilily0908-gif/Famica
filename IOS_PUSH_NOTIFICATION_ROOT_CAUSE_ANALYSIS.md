# iOS Push Notification Root Cause Analysis & Fix

**Date**: 2026-01-29  
**App**: Famica iOS  
**Issue**: Push notifications work on Android but NOT on iOS

---

## 🔍 Root Cause Analysis

### Current Entitlements Configuration

**Verified** via `ios/Runner.xcodeproj/project.pbxproj`:

```
Debug   → CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements (development)
Profile → CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements (production)
Release → CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements (production)
```

✅ **Entitlements mapping is CORRECT**

### File Contents

**ios/Runner/Runner.entitlements** (Debug):
```xml
<key>aps-environment</key>
<string>development</string>
```

**ios/Runner/RunnerRelease.entitlements** (Profile/Release):
```xml
<key>aps-environment</key>
<string>production</string>
```

✅ **Entitlements files are CORRECT**

---

## ❌ Identified Problems

### Problem 1: FCM Initialization in MainScreen
**File**: `lib/screens/main_screen.dart`

**Issue**: FCM is initialized automatically in `MainScreen.initState()`, which:
- Requests notification permission immediately without user context
- May fail to get APNs token on iOS due to timing issues
- Does not retry APNs token fetch if it fails

**Current Code**:
```dart
@override
void initState() {
  super.initState();
  _initializeFCM();  // ← Called automatically
}

Future<void> _initializeFCM() async {
  try {
    await _fcmService.initialize();
    _fcmService.trackActivityNow();
    print('✅ MainScreen: FCM初期化完了');
  } catch (e) {
    print('❌ MainScreen: FCM初期化エラー: $e');
  }
}
```

### Problem 2: Permission Request in FCMService
**File**: `lib/services/fcm_service.dart`

**Issue**: Permission is requested in `_requestPermissions()` which is called during initialize():
```dart
Future<void> initialize() async {
  // ...
  await _requestPermissions();  // ← Too early, no user context
  await _setupToken();
  // ...
}
```

### Problem 3: Insufficient APNs Token Retry
**File**: `lib/services/fcm_service.dart`

**Issue**: APNs token retry only attempts 3 times with 1 second delay:
```dart
for (int i = 0; i < 3; i++) {
  await Future.delayed(const Duration(seconds: 1));
  final retryToken = await _messaging.getAPNSToken();
  if (retryToken != null) {
    print('🍎 APNsトークン取得成功（再試行 ${i + 1}回目）');
    break;
  }
}
```

This may not be enough for iOS device registration timing.

### Problem 4: No Diagnostic UI
There is no way to:
- Check current notification permission status
- View APNs token availability
- Copy FCM token easily
- Manually request permissions
- Test notification flow

---

## 🎯 Why Android Works but iOS Doesn't

### Android
- Permission model is simpler
- No APNs equivalent - uses Google Play Services
- FCM token is available immediately after app install
- `requestPermission()` returns `authorized` by default (until user explicitly denies)

### iOS
- Requires APNs registration BEFORE FCM token can be generated
- APNs token generation requires:
  1. Valid entitlements (`aps-environment`)
  2. Valid provisioning profile
  3. Device registration with Apple servers
  4. Time for registration to complete (asynchronous)
- Permission dialog must be explicitly shown
- User must grant permission
- APNs token may not be available immediately

**Critical Flow for iOS**:
```
1. App launches with correct entitlements
2. Request notification permission (user grants)
3. iOS registers device with APNs servers (async, may take time)
4. APNs token becomes available
5. Firebase SDK can now generate FCM token
6. FCM token is saved to Firestore
7. Notifications can be received
```

**Current Implementation Problem**:
- Steps 1-6 happen too quickly in `initState()`
- APNs token may not be ready when `getAPNSToken()` is called
- Even with retry, 3 seconds may not be enough
- No way to verify what step failed

---

## ✅ Recommended Fixes

### Fix 1: Move Permission Request to Explicit User Action

**Before** (lib/screens/main_screen.dart):
```dart
@override
void initState() {
  super.initState();
  _initializeFCM();  // Auto-request permission
}
```

**After**:
```dart
@override
void initState() {
  super.initState();
  // Do NOT auto-request permission
  // Let user trigger it from settings
}
```

Add to settings screen:
```dart
ListTile(
  title: const Text('通知を有効にする'),
  subtitle: const Text('プッシュ通知の受信を許可'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () async {
    final fcmService = FCMService();
    await fcmService.initialize();
    // Show success/error dialog
  },
)
```

### Fix 2: Improve APNs Token Retry Logic

**File**: `lib/services/fcm_service.dart`

**Change**:
```dart
// iOS: 先にAPNSトークンを取得（重要）
if (defaultTargetPlatform == TargetPlatform.iOS) {
  String? apnsToken;
  
  // Retry up to 10 times with exponential backoff
  for (int i = 0; i < 10; i++) {
    apnsToken = await _messaging.getAPNSToken();
    if (apnsToken != null) {
      print('🍎 APNSトークン取得成功: ${apnsToken.substring(0, 20)}...');
      break;
    }
    
    final delaySeconds = (i + 1);  // 1, 2, 3, 4, 5...
    print('⏳ APNSトークン取得待機 (試行 ${i + 1}/10, ${delaySeconds}秒後に再試行)');
    await Future.delayed(Duration(seconds: delaySeconds));
  }
  
  if (apnsToken == null) {
    print('❌ APNSトークンを取得できませんでした（10回試行後）');
    print('   → デバイスが APNs サーバーに登録できていない可能性があります');
    print('   → インターネット接続を確認してください');
    print('   → アプリを再起動してください');
    throw Exception('APNs token unavailable after 10 retries');
  }
}
```

### Fix 3: Add Diagnostic Screen

Create `lib/screens/notification_debug_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import '../services/fcm_service.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String _status = 'Checking...';
  String? _apnsToken;
  String? _fcmToken;
  
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }
  
  Future<void> _checkStatus() async {
    final messaging = FirebaseMessaging.instance;
    
    // Permission status
    final settings = await messaging.getNotificationSettings();
    
    // APNs token (iOS only)
    String? apns;
    if (Platform.isIOS) {
      apns = await messaging.getAPNSToken();
    }
    
    // FCM token
    final fcm = await messaging.getToken();
    
    setState(() {
      _status = '${settings.authorizationStatus}';
      _apnsToken = apns;
      _fcmToken = fcm;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoTile('Platform', Platform.isIOS ? 'iOS' : 'Android'),
          _buildInfoTile('Build Mode', _getBuildMode()),
          _buildInfoTile('Permission Status', _status),
          
          if (Platform.isIOS) ...[
            _buildInfoTile(
              'APNs Token', 
              _apnsToken != null ? '✅ Available' : '❌ Not Available'
            ),
          ],
          
          _buildInfoTile(
            'FCM Token',
            _fcmToken != null ? '✅ Available' : '❌ Not Available'
          ),
          
          if (_fcmToken != null) ...[
            const Divider(),
            ListTile(
              title: const Text('FCM Token (tap to copy)'),
              subtitle: Text(_fcmToken!, style: const TextStyle(fontSize: 10)),
              trailing: const Icon(Icons.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: _fcmToken!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('FCM Token copied to clipboard')),
                );
              },
            ),
          ],
          
          const Divider(),
          
          ElevatedButton(
            onPressed: _requestPermission,
            child: const Text('Request Notification Permission'),
          ),
          
          const SizedBox(height: 8),
          
          ElevatedButton(
            onPressed: _checkStatus,
            child: const Text('Refresh Status'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
  
  String _getBuildMode() {
    if (kDebugMode) return 'Debug';
    if (kProfileMode) return 'Profile';
    return 'Release';
  }
  
  Future<void> _requestPermission() async {
    try {
      final fcmService = FCMService();
      await fcmService.initialize();
      await _checkStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission requested successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

Add to settings screen (DEBUG only):
```dart
if (kDebugMode) ...[
  const Divider(),
  ListTile(
    leading: const Icon(Icons.bug_report),
    title: const Text('Notification Debug'),
    subtitle: const Text('開発者向け診断画面'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationDebugScreen(),
        ),
      );
    },
  ),
],
```

---

## 📋 Verification Checklist

### Prerequisites
- [ ] Firebase Console has APNs Auth Key (.p8) uploaded
  - Key ID, Team ID configured
  - Both development AND production
- [ ] Real iPhone device (not simulator)
- [ ] App uninstalled before testing

### Step 1: Fresh Install
```bash
# Uninstall from device
# Then:
flutter clean
flutter pub get
flutter run -d <DEVICE_ID>
```

### Step 2: Check Logs
Look for:
```
✅ Firebase初期化成功
✅ FCMバックグラウンドハンドラー登録完了
✅ AdMob初期化成功
✅ ATT初期化完了: authorized
```

### Step 3: Request Notification Permission
- Open Settings screen
- Tap "Notification Debug" (DEBUG mode only)
- Tap "Request Notification Permission"
- iOS permission dialog should appear
- Grant permission

### Step 4: Verify Tokens
In debug screen, check:
- [ ] Permission Status: `authorized`
- [ ] APNs Token: `✅ Available`
- [ ] FCM Token: `✅ Available`
- [ ] Copy FCM token

### Step 5: Test Push Notification
1. Go to Firebase Console > Cloud Messaging
2. Click "Send test message"
3. Paste FCM token
4. Click "Test"
5. Notification should arrive on device

### Step 6: Test Foreground/Background
- [ ] Notification arrives when app is in foreground
- [ ] Notification arrives when app is in background
- [ ] Notification arrives when app is terminated
- [ ] Tapping notification opens app

---

## 🚫 Common Mistakes

### Mistake 1: Testing on Simulator
❌ **iOS Simulator cannot receive push notifications**  
✅ **Always test on a real device**

### Mistake 2: Missing APNs Key in Firebase
❌ **"APNs key not configured" in Firebase Console**  
✅ **Upload .p8 file with Key ID and Team ID**

### Mistake 3: Wrong APNs Environment
❌ **Using development key with production build**  
✅ **Match environment: Debug=development, Release=production**

### Mistake 4: Not Waiting for APNs Token
❌ **Calling getToken() before APNs registration completes**  
✅ **Retry with exponential backoff, up to 10 times**

### Mistake 5: Permission Not Granted
❌ **Assuming permission is granted**  
✅ **Check `settings.authorizationStatus == authorized`**

---

## 📊 Expected Logs (Success Case)

### Debug Build
```
✅ Firebase初期化成功
✅ FCMバックグラウンドハンドラー登録完了
✅ AdMob初期化成功
✅ ATT初期化完了: authorized
🔔 FCMService.initialize() 呼び出し #1: 初期化開始...
✅ ローカル通知プラグイン初期化完了
🔔 通知権限: authorized
🍎 APNSトークン取得成功: abc123def456...
📱 FCMトークン取得成功:
   トークン長: 163文字
   先頭20文字: def456ghi789...
🔑 完全なFCMトークン（コピーしてFirebase Consoleで使用）:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[FULL_TOKEN_HERE]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ FCMトークン保存完了
✅ FCMService: 初期化完了
```

### Receiving Push (Foreground)
```
📨 フォアグラウンド通知受信 (リスナーID: ...)
   messageId: 0:1234567890
📬 タイトル: Test Notification
📬 本文: This is a test
📬 データ: {}
```

### Receiving Push (Background)
```
🌙 バックグラウンド通知受信: 0:1234567890
   タイトル: Test Notification
   本文: This is a test
   データ: {}
```

---

## 🎯 Summary

### What Was Wrong
1. ❌ Automatic permission request in `MainScreen.initState()`
2. ❌ Insufficient APNs token retry (only 3 attempts)
3. ❌ No diagnostic UI to verify state
4. ❌ No way to manually trigger permission request

### What Is Correct
1. ✅ Entitlements mapping (Debug=development, Release=production)
2. ✅ Entitlements files content
3. ✅ Info.plist configuration
4. ✅ FCM implementation structure

### What Needs To Be Fixed
1. 🔧 Move permission request to explicit user action
2. 🔧 Increase APNs token retry attempts (10x with exponential backoff)
3. 🔧 Add diagnostic screen for debugging
4. 🔧 Add better error messages and recovery

---

**Author**: Claude (Cline)  
**Date**: 2026-01-29 16:15  
**Version**: 1.0.2+11
