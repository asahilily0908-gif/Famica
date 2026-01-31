# Notification Debug Screen Implementation Complete

**Date**: 2026-01-29  
**Feature**: In-app Notification Debug Screen (DEBUG ONLY)  
**Purpose**: Diagnose iOS push notification issues without Firebase Console

---

## ✅ Implementation Summary

Successfully implemented a debug-only notification diagnostic screen that:
- Shows notification permission status
- Displays APNs token availability (iOS)
- Shows FCM token with copy functionality
- Provides manual permission request
- Only visible in debug mode

---

## 📝 Files Changed

### 1. **lib/screens/notification_debug_screen.dart** (NEW)

**Type**: New file  
**Lines**: ~600 lines

**Features**:
- ✅ Platform detection (iOS/Android)
- ✅ Build mode display (debug/profile/release)
- ✅ Permission status with color-coded indicators
- ✅ APNs token check (iOS only) with retry button
- ✅ FCM token display with copy + print to console
- ✅ Manual permission request button
- ✅ Refresh status button
- ✅ Open iOS notification settings button (iOS only)
- ✅ All logs use `[NOTIF_DEBUG]` prefix for easy filtering

**Key Implementation Details**:

```dart
// Build mode detection
if (kDebugMode) {
  _buildMode = 'debug';
} else if (kProfileMode) {
  _buildMode = 'profile';
} else {
  _buildMode = 'release';
}

// Permission status
final settings = await messaging.getNotificationSettings();
final authStatus = _formatAuthStatus(settings.authorizationStatus);
// authorized / denied / notDetermined / provisional / ephemeral

// APNs token (iOS only)
if (Platform.isIOS) {
  apns = await messaging.getAPNSToken();
  // Retry logic with 3 attempts + 500ms delay
}

// FCM token
final fcm = await messaging.getToken();

// Logging
print('[NOTIF_DEBUG] Permission status: $authStatus');
print('[NOTIF_DEBUG] APNs token: ${apns?.substring(0, 20)}...');
print('[NOTIF_DEBUG] FCM token length: ${fcm?.length}');
```

---

### 2. **lib/screens/settings_screen.dart** (MODIFIED)

**Changes**:

#### Added import:
```dart
import 'notification_debug_screen.dart';
```

#### Added method `_buildDebugSection()`:
```dart
Widget _buildDebugSection() {
  // Debug mode only
  if (!kDebugMode) {
    return const SizedBox.shrink();
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: _buildSettingsItem(
      icon: Icons.bug_report,
      title: 'Notification Debug (Debug)',
      subtitle: '開発者向け通知診断',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationDebugScreen(),
          ),
        );
      },
    ),
  );
}
```

#### Modified `build()` method:
```dart
children: [
  _buildHeader(),
  _buildPremiumFeatures(),
  _buildSettingsList(),
  const SizedBox(height: 16),
  _buildDebugSection(),  // ← NEW
  _buildDeleteAccountButton(),
  const SizedBox(height: 80),
],
```

**Location**: Debug section appears between settings list and delete account button.

**Visibility**: 
- ✅ Visible ONLY when `kDebugMode == true`
- ❌ Hidden in Profile mode
- ❌ Hidden in Release mode

---

## 🎯 UI/UX Design

### Screen Layout

```
┌─────────────────────────────────────┐
│  ← Notification Debug               │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 基本情報                       │  │
│  │ Platform: iOS                 │  │
│  │ Build Mode: debug             │  │
│  │ Permission Status: authorized │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 🍎 APNs Token (iOS)           │  │
│  │ ✅ Available                  │  │
│  │ [Retry APNs Token] (if null)  │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ ☁️ FCM Token                   │  │
│  │ ✅ Available                  │  │
│  │ ┌───────────────────────────┐ │  │
│  │ │ abc123def456...           │ │  │
│  │ │ (selectable monospace)    │ │  │
│  │ └───────────────────────────┘ │  │
│  │ [Copy]     [Print]            │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Actions                       │  │
│  │ [Request Permission]          │  │
│  │ [Refresh Status]              │  │
│  │ [Open iOS Settings] (iOS)     │  │
│  └───────────────────────────────┘  │
│                                     │
│  最終更新: 18:35:42                │
└─────────────────────────────────────┘
```

### Color Indicators

- **Green** (`authorized`) = Push notifications enabled ✅
- **Red** (`denied`) = Push notifications blocked ❌
- **Orange** (`notDetermined`) = Not yet requested ⚠️
- **Grey** = Other states

---

## 📋 Verification Steps (Real iPhone)

### Prerequisites
- Real iPhone device (iOS Simulator CANNOT test push)
- Xcode or Flutter installed
- Debug build

### Step-by-Step Test

#### 1. Fresh Install (Reset Permission State)
```bash
# Uninstall app from iPhone
# Then:
flutter clean
flutter pub get
flutter run -d <YOUR_DEVICE_ID>
```

#### 2. Navigate to Debug Screen
1. Launch app
2. Go to **Settings** tab (bottom navigation)
3. Scroll to bottom
4. Tap **"Notification Debug (Debug)"**

Expected:
- ✅ Entry visible ONLY in debug builds
- ✅ Entry has bug icon + subtitle "開発者向け通知診断"

#### 3. Initial State Check
Immediately after first launch:

| Field | Expected Value |
|-------|---------------|
| Platform | iOS |
| Build Mode | debug |
| Permission Status | `notDetermined` (orange) |
| APNs Token | ❌ Not Available |
| FCM Token | ❌ Not Available OR ✅ Available |

#### 4. Request Permission
1. Tap **"Request Notification Permission"** button
2. iOS permission dialog appears
3. Tap **"Allow"**

Expected logs:
```
[NOTIF_DEBUG] Requesting notification permission...
[NOTIF_DEBUG] Permission request result: authorized
[NOTIF_DEBUG] Permission status: authorized
[NOTIF_DEBUG] APNs token: abc123def456...
[NOTIF_DEBUG] FCM token length: 163, first 20 chars: def456ghi789...
```

#### 5. Verify Final State
After granting permission:

| Field | Expected Value |
|-------|---------------|
| Permission Status | `authorized` (green) ✅ |
| APNs Token | ✅ Available |
| FCM Token | ✅ Available (full token shown) |

#### 6. Copy FCM Token
1. Tap **"Copy"** button
2. Snackbar: "✅ FCMトークンをクリップボードにコピーしました"
3. Paste into Firebase Console for test notification

#### 7. Send Test Push
1. Go to [Firebase Console > Cloud Messaging](https://console.firebase.google.com/)
2. Click **"Send test message"**
3. Paste FCM token
4. Click **"Test"**
5. Push notification should arrive on device ✅

#### 8. Test Other Buttons

**Refresh Status**:
- Tap → All fields update
- Timestamp updates

**Retry APNs Token** (if null):
- Tap → 3 retry attempts with 500ms delay
- Toast shows success or failure

**Print** (FCM Token):
- Tap → Full token printed to console with separators
```
[NOTIF_DEBUG] ========================================
[NOTIF_DEBUG] FULL FCM TOKEN (for Firebase Console):
[NOTIF_DEBUG] abc123def456...full_token_here
[NOTIF_DEBUG] ========================================
```

**Open iOS Notification Settings** (iOS only):
- Tap → Opens iOS Settings > Famica > Notifications
- User can manually toggle notification settings

---

## 🔍 Logging Examples

### Success Case (iOS)
```
[NOTIF_DEBUG] Permission status: authorized
[NOTIF_DEBUG] APNs token: f3a9b2c1d4e5f6a7...
[NOTIF_DEBUG] FCM token length: 163, first 20 chars: dA7fG2kL9pQw3rT8...
[NOTIF_DEBUG] FCM token copied to clipboard
```

### APNs Token Retry
```
[NOTIF_DEBUG] Retrying APNs token (3 attempts with 500ms delay)...
[NOTIF_DEBUG] APNs retry attempt 1/3: null
[NOTIF_DEBUG] APNs retry attempt 2/3: null
[NOTIF_DEBUG] APNs retry attempt 3/3: success
```

### Permission Request
```
[NOTIF_DEBUG] Requesting notification permission...
[NOTIF_DEBUG] Permission request result: authorized
```

---

## 🚀 Key Benefits

### For Developers
1. **No Firebase Console needed** - Everything in-app
2. **Token visibility** - See APNs + FCM tokens instantly
3. **Permission testing** - Test permission flow easily
4. **Copy token** - Quick copy for Firebase Console testing
5. **Real-time status** - Refresh button for live updates

### For Debugging
1. **Clear logging** - All logs use `[NOTIF_DEBUG]` prefix
2. **Easy grep** - `flutter logs | grep NOTIF_DEBUG`
3. **Timestamped** - See when last refresh occurred
4. **Color-coded** - Visual indicators for status

### For Testing
1. **Permission reset** - Uninstall to reset
2. **Manual trigger** - No auto-prompt on startup
3. **Retry mechanism** - APNs token retry built-in
4. **Settings access** - Direct link to iOS settings

---

## ⚠️ Important Notes

### Debug Mode Only
- Screen is **hidden** in Profile/Release builds
- Uses `kDebugMode` check (Flutter constant)
- No performance impact on production

### iOS Simulator Limitation
- ❌ iOS Simulator **CANNOT** receive push notifications
- ❌ APNs token will always be `null` in simulator
- ✅ **Must test on real iPhone device**

### Permission Timing
- Permission dialog appears ONLY when user taps "Request Permission"
- No auto-prompt on app startup (by design)
- Once granted, persists until app is uninstalled

### APNs Token Timing
- May take 1-2 seconds to become available after permission grant
- Retry button helps if initial fetch returns null
- Network connection required for APNs registration

---

## 📊 Diff Summary

```diff
lib/screens/notification_debug_screen.dart (NEW)
  + 600 lines (complete implementation)

lib/screens/settings_screen.dart (MODIFIED)
  + 1 import
  + 1 method (_buildDebugSection)
  + 1 widget call in build()
  = ~30 lines added
```

**Total**: 1 new file, 1 modified file

---

## 🎓 How It Works

### Permission Flow
```
1. User taps "Request Notification Permission"
   ↓
2. App calls FirebaseMessaging.instance.requestPermission()
   ↓
3. iOS shows system permission dialog
   ↓
4. User grants/denies
   ↓
5. Screen auto-refreshes to show new status
   ↓
6. APNs token becomes available (if authorized)
   ↓
7. FCM token generates
   ↓
8. User can copy token and test in Firebase Console
```

### Token Hierarchy (iOS)
```
APNs Token (Apple)
       ↓
   Required for
       ↓
FCM Token (Firebase)
       ↓
   Used for
       ↓
Push Notifications
```

**Why APNs First?**
- iOS requires APNs registration before FCM can generate token
- Without APNs token, FCM token will be null or fail
- This is why APNs token availability is critical on iOS

---

## 🔧 Troubleshooting Guide

### Issue: Debug screen not visible
**Cause**: Not in debug mode  
**Solution**: Run with `flutter run` (not `flutter run --release`)

### Issue: APNs token always null
**Cause 1**: Testing on iOS Simulator  
**Solution**: Use real iPhone device

**Cause 2**: No internet connection  
**Solution**: Connect to WiFi/cellular

**Cause 3**: Permission not granted  
**Solution**: Tap "Request Permission" button

**Cause 4**: Timing issue  
**Solution**: Tap "Retry APNs Token" button (3 attempts)

### Issue: FCM token null
**Cause**: APNs token not available yet  
**Solution**: Wait for APNs token, then refresh

### Issue: Push not arriving
**Check**:
1. Permission Status = `authorized`? ✅
2. APNs Token = Available? ✅
3. FCM Token = Available? ✅
4. Firebase Console has APNs key uploaded? ✅
5. Correct APNs environment (dev vs prod)? ✅

---

## 🎯 Success Criteria (All Met)

- [x] Debug-only screen (hidden in profile/release)
- [x] Shows platform (iOS/Android)
- [x] Shows build mode (debug/profile/release)
- [x] Shows permission authorizationStatus
- [x] Shows APNs token status (iOS only)
- [x] Shows FCM token with copy button
- [x] Manual permission request button
- [x] Refresh status button
- [x] Open iOS settings button (iOS only)
- [x] All logs use [NOTIF_DEBUG] prefix
- [x] APNs token retry mechanism (3 attempts)
- [x] Print full token to console (debug only)
- [x] No breaking changes to existing code
- [x] No new dependencies added

---

## 📚 Related Documentation

- [IOS_PUSH_NOTIFICATION_ROOT_CAUSE_ANALYSIS.md](./IOS_PUSH_NOTIFICATION_ROOT_CAUSE_ANALYSIS.md) - Root cause analysis
- [FCM_NOTIFICATION_SETUP.md](./FCM_NOTIFICATION_SETUP.md) - FCM setup guide
- [IOS_APNS_TOKEN_FIX_PLAN.md](./IOS_APNS_TOKEN_FIX_PLAN.md) - APNs token fix plan

---

**Status**: ✅ **COMPLETE**  
**Author**: Claude (Cline)  
**Date**: 2026-01-29 18:45  
**Version**: 1.0.2+11
