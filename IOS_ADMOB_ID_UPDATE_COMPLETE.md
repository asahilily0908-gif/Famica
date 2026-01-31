# iOS & Android AdMob 広告 ID 統一完了レポート

**更新日**: 2026年1月31日  
**目的**: 「Publisher data not found」エラーの解決  
**対象**: Famica iOS & Android アプリ

---

## 📋 実施内容サマリー

### 問題
- **iOS & Android** で AdMob 広告が表示されず「Publisher data not found」エラーが発生
- **根本原因**: アプリ ID（Info.plist / AndroidManifest.xml）と banner_ad_widget.dart の広告ユニット ID が異なる AdMob アカウントのものだった

### 解決策
- **iOS & Android 両方**を正しい AdMob アカウント（`ca-app-pub-3184270565267183`）の ID に統一

---

## 🔧 変更内容

### 1. Info.plist の確認

**ファイル**: `ios/Runner/Info.plist`  
**行**: 48

✅ **既に正しい値に更新済み**
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3184270565267183~8340379507</string>
```

- 変更前: `ca-app-pub-3184270565267183~2634862619`（古い値）
- 変更後: `ca-app-pub-3184270565267183~8340379507`（新しい値）

---

### 2. AndroidManifest.xml の確認

**ファイル**: `android/app/src/main/AndroidManifest.xml`  
**行**: 51

✅ **既に正しい値に設定済み**
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3184270565267183~3432864611"/>
```

- アカウント ID: `ca-app-pub-3184270565267183`（正しい）

---

### 3. banner_ad_widget.dart の更新

**ファイル**: `lib/widgets/banner_ad_widget.dart`  
**行**: 46

**変更内容**:
```dart
// 変更前
adUnitId = Platform.isIOS
    ? 'ca-app-pub-8158788636349913/8549185583' // iOS 本番（間違ったアカウント）
    : 'ca-app-pub-8158788636349913/6254913551'; // Android 本番（間違ったアカウント）

// 変更後
adUnitId = Platform.isIOS
    ? 'ca-app-pub-3184270565267183/7433426282' // iOS 本番（正しいアカウント）
    : 'ca-app-pub-3184270565267183/5633035433'; // Android 本番（正しいアカウント）
```

**重要なポイント**:
- **iOS と Android 両方**の広告ユニット ID を正しいアカウント（`ca-app-pub-3184270565267183`）のものに変更
- テスト広告 ID（Google 公式）は既に実装済み
- `USE_TEST_ADS = true` に設定することでテスト広告を使用可能

---

## ✅ 更新後の設定一覧

### iOS AdMob 設定

| 項目 | 値 | 説明 |
|------|-----|------|
| **AdMob Publisher ID** | `ca-app-pub-3184270565267183` | AdMob アカウント ID（プレフィックス） |
| **iOS アプリ ID** | `ca-app-pub-3184270565267183~8340379507` | Info.plist の GADApplicationIdentifier |
| **iOS 広告ユニット ID（本番）** | `ca-app-pub-3184270565267183/7433426282` | バナー広告ユニット ID |
| **iOS 広告ユニット ID（テスト）** | `ca-app-pub-3940256099942544/2934735716` | Google 公式テスト ID |
| **テストモードフラグ** | `USE_TEST_ADS = false` | `true` でテスト広告を表示 |

### Android AdMob 設定

| 項目 | 値 | 説明 |
|------|-----|------|
| **AdMob Publisher ID** | `ca-app-pub-3184270565267183` | AdMob アカウント ID（プレフィックス） |
| **Android アプリ ID** | `ca-app-pub-3184270565267183~3432864611` | AndroidManifest.xml の APPLICATION_ID |
| **Android 広告ユニット ID（本番）** | `ca-app-pub-3184270565267183/5633035433` | バナー広告ユニット ID |
| **Android 広告ユニット ID（テスト）** | `ca-app-pub-3940256099942544/6300978111` | Google 公式テスト ID |
| **テストモードフラグ** | `USE_TEST_ADS = false` | `true` でテスト広告を表示 |

---

## 🎯 次のステップ

### 1. ビルドキャッシュのクリア（必須）

古い設定が残らないように、必ず flutter clean を実行してください。

```bash
cd /Users/matsushimaasahi/Developer/famica

# ビルドキャッシュをクリア
flutter clean

# 依存関係を再取得
flutter pub get
```

---

### 2. iOS 実機でのテスト

#### A. テスト広告での動作確認（推奨）

```bash
# 1. banner_ad_widget.dart の 33 行目を編集
# const bool USE_TEST_ADS = false; → true に変更

# 2. iOS 実機で実行
flutter run -d <iOS-device-id>

# 3. 期待される結果:
#    - Google のテスト広告が表示される
#    - ログに「✅ [BannerAd] 広告読み込み成功」が表示される
```

#### B. 本番広告での動作確認

```bash
# 1. banner_ad_widget.dart の 33 行目を確認
# const bool USE_TEST_ADS = false; であることを確認

# 2. iOS 実機で実行
flutter run -d <iOS-device-id>

# 3. 期待される結果:
#    - 数時間〜24時間後に本番広告が表示される（新規広告ユニットの場合）
#    - ログに「✅ [BannerAd] 広告読み込み成功」が表示される
```

---

### 3. Xcode Console でのログ確認

#### 期待されるログ（成功時）

```
✅ AdMob初期化成功
   初期化ステータス: {...}
✅ ATT初期化完了: authorized
🔷 [BannerAd] 広告読み込み開始
   プラットフォーム: iOS
   本番モード: 本番広告IDを使用
   広告ユニットID: ca-app-pub-3184270565267183/7433426282
✅ [BannerAd] 広告読み込み成功
   サイズ: 320x50
👁️ [BannerAd] 広告が表示されました（インプレッション記録）
```

#### エラー時のログ

```
❌ [BannerAd] 広告読み込み失敗
   エラーコード: 3
   エラーメッセージ: No ad to show.
💡 診断: 広告在庫なし（NO_FILL）。
   → 新しい広告ユニットIDの場合、広告配信まで数時間かかることがあります。
   → テスト広告IDで試すことを推奨します。
```

**注意**: 新規広告ユニットの場合、広告配信開始まで数時間〜24時間かかる場合があります。「NO_FILL」エラーが出ても、しばらく時間をおいて再試行してください。

---

### 4. AdMob Console での確認

#### 確認項目

1. **AdMob Console** (https://apps.admob.com) にログイン
2. **アプリ** → **Famica (iOS)** を選択
3. 以下を確認:
   - [ ] アプリのステータスが「有効」になっているか
   - [ ] App Store ID が設定されているか
   - [ ] Bundle ID が `com.matsushima.famica` と一致するか

4. **広告ユニット** セクションで `ca-app-pub-3184270565267183/7433426282` を検索
5. 以下を確認:
   - [ ] ステータスが「有効」か
   - [ ] 広告フォーマットが「バナー」か
   - [ ] プラットフォームが「iOS」か

6. **レポート** でリクエスト数・インプレッション数を確認
   - 広告が表示されると、数時間後にレポートに反映される

---

## 🔍 トラブルシューティング

### Q1: テスト広告は表示されるが、本番広告が表示されない

**A**: 以下を確認してください：

1. **広告ユニットが新規作成の場合**
   - AdMob の広告配信開始まで数時間〜24時間かかります
   - しばらく時間をおいて再試行してください

2. **AdMob Console で広告ユニットのステータスを確認**
   - ステータスが「要審査」の場合、審査完了を待つ
   - ステータスが「無効」の場合、理由を確認

3. **フィルレート（Fill Rate）が低い**
   - 地域や時間帯によって広告在庫が少ない場合があります
   - ATT 権限を許可していないと、フィルレートが下がる可能性があります

---

### Q2: 「Publisher data not found」エラーが解決しない

**A**: 以下を確認してください：

1. **flutter clean を実行したか**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Info.plist と banner_ad_widget.dart のアカウント ID が一致しているか**
   - Info.plist: `ca-app-pub-3184270565267183~8340379507`
   - 広告ユニット ID: `ca-app-pub-3184270565267183/7433426282`
   - どちらも `ca-app-pub-3184270565267183` で始まっている必要がある

3. **AdMob Console で広告ユニット ID が存在するか**
   - `ca-app-pub-3184270565267183/7433426282` を検索
   - 存在しない場合は、正しい ID を確認

---

### Q3: ATT ダイアログが表示されない

**A**: 以下を確認してください：

1. **Info.plist に NSUserTrackingUsageDescription が設定されているか**
   - 既に設定済み: 「より関連性の高い広告を表示するために使用します」

2. **iOS 設定でトラッキングが許可されているか**
   - 設定 → プライバシーとセキュリティ → トラッキング → Famica
   - オンになっているか確認

3. **ATT ダイアログを再表示したい場合**
   - iOS 設定 → プライバシーとセキュリティ → トラッキング → アプリのリセット
   - または、アプリを削除して再インストール

---

## 📊 期待される改善結果

### Before（変更前）

- ❌ iOS で「Publisher data not found」エラー
- ❌ 広告が一切表示されない
- ❌ AdMob レポートにインプレッション数が記録されない

### After（変更後）

- ✅ Info.plist と広告ユニット ID のアカウントが一致
- ✅ テスト広告が正常に表示される
- ✅ 本番広告が表示される（広告配信開始後）
- ✅ AdMob レポートにインプレッション数が記録される
- ✅ 推定収益が発生する

---

## 📝 重要な注意事項

### テストモードの使い分け

```dart
// lib/widgets/banner_ad_widget.dart の 33 行目

// 開発・デバッグ時
const bool USE_TEST_ADS = true;  // ← Google のテスト広告を表示

// 本番リリース時
const bool USE_TEST_ADS = false; // ← 本番広告を表示
```

**重要**: 
- **必ず本番リリース前に `USE_TEST_ADS = false` に戻してください**
- テスト広告を本番アプリに含めると、AdMob ポリシー違反となります
- App Store / TestFlight に提出する前に確認してください

---

## ✅ 完了確認チェックリスト

### コード変更

- [x] Info.plist の GADApplicationIdentifier が `ca-app-pub-3184270565267183~8340379507` に設定されている
- [x] AndroidManifest.xml の APPLICATION_ID が `ca-app-pub-3184270565267183~3432864611` に設定されている
- [x] banner_ad_widget.dart の iOS 広告ユニット ID が `ca-app-pub-3184270565267183/7433426282` に設定されている
- [x] banner_ad_widget.dart の Android 広告ユニット ID が `ca-app-pub-3184270565267183/5633035433` に設定されている
- [x] テスト広告 ID が実装されている（`USE_TEST_ADS` フラグで切り替え可能）
- [x] iOS & Android 両方が同じ AdMob アカウント（`ca-app-pub-3184270565267183`）に統一されている

### 動作確認（実施予定）

- [ ] `flutter clean` を実行した
- [ ] テスト広告が表示されることを確認した
- [ ] Xcode Console のログを確認した
- [ ] 本番広告の表示を確認した（24時間後）
- [ ] AdMob Console のレポートを確認した

### リリース前確認

- [ ] `USE_TEST_ADS = false` に設定されている
- [ ] ATT 権限ダイアログが表示される
- [ ] 広告が適切に表示される

---

## 📚 関連ドキュメント

- `IOS_ADMOB_PUBLISHER_DATA_NOT_FOUND_DIAGNOSIS.md` - エラー診断レポート
- `IOS_ADMOB_FCM_DIAGNOSTIC_FIX.md` - AdMob 診断・修正完了レポート
- `FAMICA_ADMOB_ATT_IMPLEMENTATION_REPORT.md` - ATT 実装レポート

---

**更新完了日時**: 2026年1月31日 22:53  
**次回アクション**: flutter clean → 実機テスト → AdMob Console 確認
