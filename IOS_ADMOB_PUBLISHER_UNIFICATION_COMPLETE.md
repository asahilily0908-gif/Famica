# iOS AdMob Publisher ID 統一完了レポート

**更新日**: 2026年2月1日  
**目的**: iOS AdMob を単一の Publisher に統一し、ビルドモード自動切り替えとログ改善を実装  
**対象**: Famica iOS アプリ

---

## 📋 背景と問題

### 問題
- iOS で「Publisher data not found」エラーが発生していた
- **根本原因**: iOS App ID（Info.plist）と広告ユニット ID が異なる Publisher のものだった

### 既存の対応状況
- `IOS_ADMOB_ID_UPDATE_COMPLETE.md` にて、iOS/Android 両方の ID を統一済み
- しかし、手動フラグによるテスト/本番切り替えなど、改善の余地があった

---

## 🎯 今回の実施内容

### 1. ビルドモード自動切り替えの実装

**変更前**:
```dart
// 手動フラグで切り替え（リリース前に変更し忘れるリスク）
const bool USE_TEST_ADS = false;
```

**変更後**:
```dart
// kDebugMode, kProfileMode で自動判定
final bool useTestAds = kDebugMode || kProfileMode;
// Debug/Profile → テスト広告
// Release → 本番広告
```

**メリット**:
- ✅ リリースビルド時に自動的に本番広告が使用される
- ✅ 開発中は常にテスト広告が表示される
- ✅ 手動フラグ変更忘れによるポリシー違反を防止

---

### 2. 定数の明示的定義

**変更内容**:
```dart
class _BannerAdWidgetState extends State<BannerAdWidget> {
  // iOS AdMob 設定
  static const String _iosAppId = 'ca-app-pub-3184270565267183~8340379507';
  static const String _iosBannerAdUnitIdProd = 'ca-app-pub-3184270565267183/7433426282';
  static const String _iosBannerAdUnitIdTest = 'ca-app-pub-3940256099942544/2934735716';
  
  // Android AdMob 設定（参考用 - 変更しない）
  static const String _androidBannerAdUnitIdProd = 'ca-app-pub-3184270565267183/5633035433';
  static const String _androidBannerAdUnitIdTest = 'ca-app-pub-3940256099942544/6300978111';
```

**メリット**:
- ✅ すべての AdMob ID が一か所で管理される
- ✅ Publisher ID の一貫性が視覚的に確認できる
- ✅ Android ID にコメント「変更しない」を追加し、誤変更を防止

---

### 3. ランタイムログの改善

**追加されたログ**:
```dart
print('🔷 [BannerAd] 広告読み込み開始');
print('   プラットフォーム: ${isIOS ? "iOS" : "Android"}');
print('   ビルドモード: ${kReleaseMode ? "Release" : (kProfileMode ? "Profile" : "Debug")}');
print('   テスト広告使用: ${useTestAds ? "はい" : "いいえ"}');

if (isIOS) {
  print('   iOS App ID: $_iosAppId');
}

// セキュリティのため、adUnitId の最初20文字のみ表示
final String adUnitIdPreview = adUnitId.length > 20 
    ? '${adUnitId.substring(0, 20)}...' 
    : adUnitId;
print('   広告ユニットID: $adUnitIdPreview');
```

**出力例（iOS Debug）**:
```
🔷 [BannerAd] 広告読み込み開始
   プラットフォーム: iOS
   ビルドモード: Debug
   テスト広告使用: はい
   iOS App ID: ca-app-pub-3184270565267183~8340379507
   広告ユニットID: ca-app-pub-39402560...
```

**出力例（iOS Release）**:
```
🔷 [BannerAd] 広告読み込み開始
   プラットフォーム: iOS
   ビルドモード: Release
   テスト広告使用: いいえ
   iOS App ID: ca-app-pub-3184270565267183~8340379507
   広告ユニットID: ca-app-pub-31842705...
```

**メリット**:
- ✅ どの広告 ID が使用されているか即座に確認可能
- ✅ iOS App ID と広告ユニット ID の Publisher 一致を確認できる
- ✅ セキュリティのため adUnitId は最初20文字のみ表示
- ✅ ビルドモードが明示されるため、誤ったモードでのビルドを検知可能

---

### 4. エラー診断の改善

**変更内容**:
```dart
void _diagnoseError(LoadAdError error, bool isIOS) {
  // ... 既存のエラー診断 ...
  
  // iOS特有の問題チェック
  if (isIOS) {
    print('📱 iOS特有のチェック:');
    print('   - Info.plistにGADApplicationIdentifier ($_iosAppId) が設定されているか確認');
    print('   - 広告ユニットIDが同じPublisher ID (ca-app-pub-3184270565267183) であるか確認');
    print('   - ATT（App Tracking Transparency）の権限が許可されているか確認');
    print('   - SKAdNetworkItemsが設定されているか確認');
  }
}
```

**メリット**:
- ✅ エラー発生時に期待される iOS App ID が表示される
- ✅ Publisher ID の不一致を即座に検出可能
- ✅ トラブルシューティングが容易になる

---

## ✅ 変更されたファイル

### 1. `lib/widgets/banner_ad_widget.dart`

**変更箇所**:
- ビルドモード自動切り替えロジック追加
- 定数定義の追加（iOS/Android App ID, 広告ユニット ID）
- ランタイムログの改善（ビルドモード、iOS App ID、adUnitId プレビュー）
- エラー診断の改善（iOS App ID の明示）

**変更されなかったファイル**:
- `ios/Runner/Info.plist` - **既に正しい値に設定済み**
  - GADApplicationIdentifier: `ca-app-pub-3184270565267183~8340379507`
- `android/app/src/main/AndroidManifest.xml` - **Android は変更なし**

---

## 📊 iOS AdMob 設定一覧（確定版）

| 項目 | 値 | 説明 |
|------|-----|------|
| **Publisher ID** | `ca-app-pub-3184270565267183` | AdMob アカウント ID（プレフィックス） |
| **iOS App ID** | `ca-app-pub-3184270565267183~8340379507` | Info.plist の GADApplicationIdentifier |
| **iOS 広告ユニット ID（本番）** | `ca-app-pub-3184270565267183/7433426282` | バナー広告ユニット ID（Release ビルド） |
| **iOS 広告ユニット ID（テスト）** | `ca-app-pub-3940256099942544/2934735716` | Google 公式テスト ID（Debug/Profile ビルド） |
| **切り替え方法** | `kDebugMode || kProfileMode` | 自動判定（手動変更不要） |

---

## 🔍 動作確認方法

### 1. Debug ビルドでテスト広告を確認

```bash
# iOS 実機またはシミュレータで実行
flutter run -d <device-id>

# 期待されるログ:
# 🔷 [BannerAd] 広告読み込み開始
#    プラットフォーム: iOS
#    ビルドモード: Debug
#    テスト広告使用: はい
#    iOS App ID: ca-app-pub-3184270565267183~8340379507
#    広告ユニットID: ca-app-pub-39402560...
# ✅ [BannerAd] 広告読み込み成功
```

### 2. Release ビルドで本番広告を確認

```bash
# Release モードでビルド
flutter build ios --release

# Xcode で実機にインストールして実行

# 期待されるログ（Xcode Console）:
# 🔷 [BannerAd] 広告読み込み開始
#    プラットフォーム: iOS
#    ビルドモード: Release
#    テスト広告使用: いいえ
#    iOS App ID: ca-app-pub-3184270565267183~8340379507
#    広告ユニットID: ca-app-pub-31842705...
```

### 3. Publisher ID 一致の確認

**確認項目**:
- [ ] iOS App ID のプレフィックスが `ca-app-pub-3184270565267183` である
- [ ] 広告ユニット ID のプレフィックスが `ca-app-pub-3184270565267183` である
- [ ] 両方が同じ Publisher ID を使用している

**ログで確認**:
```
iOS App ID: ca-app-pub-3184270565267183~8340379507
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ← この部分
広告ユニットID: ca-app-pub-31842705...
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ← この部分が一致
```

---

## 🎯 期待される効果

### Before（今回の改善前）

- ⚠️ 手動フラグ `USE_TEST_ADS` を変更し忘れるリスク
- ⚠️ リリース時にテスト広告が含まれる可能性
- ⚠️ ログが不十分でトラブルシューティングが困難

### After（今回の改善後）

- ✅ **自動切り替え**: Debug/Profile では自動的にテスト広告
- ✅ **ポリシー遵守**: Release では自動的に本番広告
- ✅ **可視性向上**: ビルドモード、iOS App ID、adUnitId をログ出力
- ✅ **トラブルシューティング**: Publisher ID の一致を即座に確認可能
- ✅ **セキュリティ**: adUnitId は最初20文字のみ表示

---

## ⚠️ 重要な注意事項

### 1. GoogleMobileAds の初期化順序

**必須**: `GoogleMobileAds.instance.initialize()` を `BannerAd.load()` の前に呼び出す

**確認場所**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // AdMob 初期化（★ 必須 ★）
  await GoogleMobileAds.instance.initialize();
  
  runApp(const MyApp());
}
```

---

### 2. Android の設定は変更していない

**重要**: 今回の変更は iOS のみ対象です。

**Android の設定**（変更なし）:
- AndroidManifest.xml の APPLICATION_ID: `ca-app-pub-3184270565267183~3432864611`
- Android 広告ユニット ID（本番）: `ca-app-pub-3184270565267183/5633035433`
- Android 広告ユニット ID（テスト）: `ca-app-pub-3940256099942544/6300978111`

---

### 3. app-ads.txt は変更不要

**現在の app-ads.txt**:
```
google.com, pub-3184270565267183, DIRECT, f08c47fec0942fa0
```

- ✅ Publisher ID が一致している
- ✅ 変更不要

---

## 🔧 トラブルシューティング

### Q1: Debug ビルドで本番広告が表示される

**A**: ビルドモードを確認してください。

```dart
// ログで確認
print('ビルドモード: ${kReleaseMode ? "Release" : (kProfileMode ? "Profile" : "Debug")}');

// 期待される出力:
// Debug ビルド → "Debug"
// Profile ビルド → "Profile"
// Release ビルド → "Release"
```

---

### Q2: 「Publisher data not found」エラーが解決しない

**A**: 以下を確認してください:

1. **flutter clean を実行**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **ログで Publisher ID の一致を確認**
   ```
   iOS App ID: ca-app-pub-3184270565267183~8340379507
   広告ユニットID: ca-app-pub-31842705...
   ```
   - 両方が `ca-app-pub-3184270565267183` で始まっているか確認

3. **Info.plist を確認**
   ```bash
   cat ios/Runner/Info.plist | grep -A1 GADApplicationIdentifier
   ```
   - 出力: `<string>ca-app-pub-3184270565267183~8340379507</string>`

---

### Q3: Release ビルドでテスト広告が表示される

**A**: ビルド方法を確認してください。

**正しい Release ビルド**:
```bash
# iOS の場合
flutter build ios --release

# または Xcode で Archive
```

**間違った例**:
```bash
# flutter run は Debug モードになる
flutter run -d <device-id>  # ← これは Debug ビルド
```

---

## 📚 関連ドキュメント

- `IOS_ADMOB_ID_UPDATE_COMPLETE.md` - iOS/Android AdMob ID 統一完了レポート（初回対応）
- `IOS_ADMOB_PUBLISHER_DATA_NOT_FOUND_DIAGNOSIS.md` - エラー診断レポート
- `IOS_ADMOB_FCM_DIAGNOSTIC_FIX.md` - AdMob 診断・修正完了レポート
- `FAMICA_ADMOB_ATT_IMPLEMENTATION_REPORT.md` - ATT 実装レポート
- `ADMOB_WEBSITE_URL_SETUP_GUIDE.md` - AdMob デベロッパーウェブサイト URL 設定ガイド

---

## ✅ 完了確認チェックリスト

### コード変更

- [x] `banner_ad_widget.dart` に定数定義を追加した
- [x] ビルドモード自動切り替えロジックを実装した
- [x] ランタイムログを改善した（ビルドモード、iOS App ID、adUnitId）
- [x] エラー診断を改善した（iOS App ID の明示）
- [x] Info.plist の GADApplicationIdentifier が正しいことを確認した

### 動作確認（実施予定）

- [ ] Debug ビルドでテスト広告が表示されることを確認した
- [ ] Release ビルドで本番広告が表示されることを確認した
- [ ] Xcode Console のログで Publisher ID の一致を確認した
- [ ] AdMob Console のレポートで広告インプレッションを確認した

### リリース前確認

- [ ] Release ビルドを実行した
- [ ] ログで「ビルドモード: Release」と表示されることを確認した
- [ ] ログで「テスト広告使用: いいえ」と表示されることを確認した
- [ ] App Store / TestFlight に提出する前に再確認した

---

**更新完了日時**: 2026年2月1日 05:40  
**次回アクション**: flutter clean → Debug ビルドでテスト → Release ビルドで検証 → AdMob Console 確認
