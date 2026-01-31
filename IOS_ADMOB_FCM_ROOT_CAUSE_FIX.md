# iOS AdMob & FCM 根本原因修正完了レポート

**実施日**: 2026年1月29日  
**対象**: Famica iOS版  
**目的**: AdMob広告とプッシュ通知の根本的な問題を修正

---

## 🎯 実施内容サマリー

### A) プッシュ通知 (FCM/APNs) - 根本修正
✅ **問題**: productionのentitlementsをハードコードしていた  
✅ **解決**: Debug/Release用entitlementsを分離  
✅ デバッグ環境とリリース環境で適切なAPNs環境を使用

### B) AdMob広告 - 根本修正
✅ **問題**: テスト広告への切り替えが困難  
✅ **解決**: テストモードフラグを追加（1行変更で切り替え可能）  
✅ 詳細なエラー診断ログを追加

---

## 📝 A) プッシュ通知の根本修正

### 問題点
以前の修正で`Runner.entitlements`を`production`にハードコードしたため：
- ❌ 開発中のプッシュ通知テストができない
- ❌ Xcodeからのデバッグ実行で通知が届かない
- ❌ App Store配信版とデバッグ版で同じ設定を使用

### 解決策
Debug/Release用entitlementsファイルを分離：

```
ios/Runner/
├── Runner.entitlements         (Debug用: development)
└── RunnerRelease.entitlements  (Release用: production)
```

### 変更ファイル

#### 1. `ios/Runner/Runner.entitlements` (Debug用)
```xml
<key>aps-environment</key>
<string>development</string>
```

#### 2. `ios/Runner/RunnerRelease.entitlements` (新規作成, Release用)
```xml
<key>aps-environment</key>
<string>production</string>
```

### ⚠️ 重要: Xcode設定が必要

entitlementsファイルを分離しただけでは動作しません。
**Xcodeでビルド設定を変更する必要があります。**

#### Xcode設定手順

1. **Xcodeでプロジェクトを開く**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Runner targetを選択**
   - 左側のプロジェクトナビゲーター > Runner
   - TARGETSから「Runner」を選択

3. **Build Settings タブを開く**
   - 上部の「Build Settings」をクリック
   - 検索ボックスに「entitlements」と入力

4. **Code Signing Entitlements を設定**
   
   **Debug構成**:
   - 「Debug」の行を展開
   - 値を `Runner/Runner.entitlements` に設定
   
   **Release構成**:
   - 「Release」の行を展開
   - 値を `Runner/RunnerRelease.entitlements` に設定

5. **保存して閉じる**
   - ⌘+S で保存
   - Xcodeを終了

### 検証方法

#### Debug環境（development APNs）
```bash
flutter run -d <DEVICE_ID>
```
- Firebase ConsoleにDevelopment APNs証明書が設定されていること
- デバイスでアプリを起動
- ログで「🍎 APNSトークン取得成功」を確認
- Firebase Consoleからテスト通知送信

#### Release環境（production APNs）
```bash
flutter build ios --release
# Xcodeでアーカイブ
```
- Firebase ConsoleにProduction APNs証明書が設定されていること
- TestFlightまたはApp Storeからインストール
- プッシュ通知が届くことを確認

---

## 📝 B) AdMob広告の根本修正

### 問題点
- テスト広告IDへの切り替えが面倒（コメント編集が必要）
- エラー時の診断情報が不足
- NO_FILLエラーの原因特定が困難

### 解決策

#### 1. テストモードフラグの追加

`lib/widgets/banner_ad_widget.dart`に以下を追加：

```dart
// テストモード制御: const USE_TEST_ADS = true; にするとテスト広告を使用
const bool USE_TEST_ADS = false;

String adUnitId;
if (USE_TEST_ADS) {
  // Googleの公式テスト広告ID
  adUnitId = Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716' // iOS テスト
      : 'ca-app-pub-3940256099942544/6300978111'; // Android テスト
  print('   ⚠️ テストモード: テスト広告IDを使用');
} else {
  // 本番広告ID
  adUnitId = Platform.isIOS
      ? 'ca-app-pub-8158788636349913/8549185583' // iOS 本番
      : 'ca-app-pub-8158788636349913/6254913551'; // Android 本番
  print('   本番モード: 本番広告IDを使用');
}
```

#### 2. 詳細ログと診断機能

既に以下を実装済み：
- ✅ エラーコード別診断メッセージ
- ✅ iOS特有のチェックポイント表示
- ✅ デバッグモードでエラーを画面表示
- ✅ 広告ロード全イベントのログ出力

### 検証方法

#### ステップ1: テスト広告で動作確認

1. **テストモードを有効化**
   ```dart
   const bool USE_TEST_ADS = true; // ← trueに変更
   ```

2. **アプリを実行**
   ```bash
   flutter run -d <DEVICE_ID>
   ```

3. **期待される結果**
   ```
   ✅ AdMob初期化成功
   ✅ ATT初期化完了: authorized
   🔷 [BannerAd] 広告読み込み開始
      プラットフォーム: iOS
      ⚠️ テストモード: テスト広告IDを使用
      広告ユニットID: ca-app-pub-3940256099942544/2934735716
   ✅ [BannerAd] 広告読み込み成功
      サイズ: 320x50
   ```

4. **確認事項**
   - [ ] 画面下部にテスト広告が表示される
   - [ ] 広告は「Test Ad」または「Test Mode」と表示される
   - [ ] タップすると広告詳細が表示される

#### ステップ2: 本番広告IDで確認

1. **テストモードを無効化**
   ```dart
   const bool USE_TEST_ADS = false; // ← falseに戻す
   ```

2. **アプリを実行**
   ```bash
   flutter clean
   flutter run -d <DEVICE_ID>
   ```

3. **期待される結果**
   ```
   🔷 [BannerAd] 広告読み込み開始
      プラットフォーム: iOS
      本番モード: 本番広告IDを使用
      広告ユニットID: ca-app-pub-8158788636349913/8549185583
   ✅ [BannerAd] 広告読み込み成功
   ```

4. **確認事項**
   - [ ] 実際の広告が表示される（テストマークなし）
   - [ ] または「NO_FILL」エラーで診断メッセージが表示される

#### NO_FILLエラーの場合

```
❌ [BannerAd] 広告読み込み失敗
   エラーコード: 3
   エラーメッセージ: No ad to show.
💡 診断: 広告在庫なし（NO_FILL）
   → 新しい広告ユニットIDの場合、広告配信まで数時間かかることがあります
   → テスト広告IDで試すことを推奨します
```

**対処法**:
1. AdMob管理画面で広告ユニットIDが有効か確認
2. 新規作成の場合、24時間待つ
3. ATT権限が許可されているか確認（設定アプリ > プライバシー > トラッキング）

---

## 📋 変更ファイル一覧

### 新規作成
1. ✅ `ios/Runner/RunnerRelease.entitlements` - Release用APNs設定

### 修正
1. ✅ `ios/Runner/Runner.entitlements` - development APNsに戻す
2. ✅ `lib/widgets/banner_ad_widget.dart` - テストモードフラグ追加

### Xcode設定（手動）
1. ⚠️ **必須**: Build Settings > Code Signing Entitlementsを設定
   - Debug: `Runner/Runner.entitlements`
   - Release: `Runner/RunnerRelease.entitlements`

---

## 🔍 完全な検証チェックリスト

### 事前準備
- [ ] Firebase Consoleで両方のAPNs証明書を設定
  - [ ] Development APNs証明書 (.p12) または Auth Key (.p8)
  - [ ] Production APNs証明書 (.p12) または Auth Key (.p8)
- [ ] XcodeでCode Signing Entitlementsを設定済み

### A) AdMob広告検証（実機必須）

#### テスト広告
- [ ] `USE_TEST_ADS = true` に設定
- [ ] アプリを起動
- [ ] ログに「⚠️ テストモード: テスト広告IDを使用」と表示
- [ ] テスト広告が画面下部に表示される
- [ ] 広告に「Test Ad」マークがある

#### 本番広告
- [ ] `USE_TEST_ADS = false` に設定
- [ ] アプリをクリーンビルド
- [ ] ログに「本番モード: 本番広告IDを使用」と表示
- [ ] 実広告が表示される（またはNO_FILLエラー）

#### ATT権限
- [ ] 初回起動時にATT許可ダイアログが表示
- [ ] 設定アプリ > プライバシー > トラッキング > Famicaが「許可」

### B) プッシュ通知検証（実機必須）

#### Debug環境
- [ ] `flutter run` でアプリを起動
- [ ] ログに「🍎 APNSトークン取得成功」と表示
- [ ] ログに「🔑 完全なFCMトークン」と表示
- [ ] FCMトークンをコピー
- [ ] Firebase Console > Cloud Messaging > テストメッセージ送信
- [ ] アプリがフォアグラウンドで通知が表示される
- [ ] アプリをバックグラウンドにして通知が届く

#### Release環境（TestFlight）
- [ ] Xcodeでアーカイブ
- [ ] TestFlightにアップロード
- [ ] TestFlightからインストール
- [ ] アプリを起動してFCMトークンを取得（ログ）
- [ ] Firebase Consoleからテスト通知送信
- [ ] 通知が届くことを確認

### C) エラー時の診断

#### AdMobエラー
- [ ] コンソールに詳細なエラーログが表示される
- [ ] エラーコード、メッセージ、ドメインが出力される
- [ ] 診断メッセージ（💡）が表示される
- [ ] デバッグモードで画面に赤いエラーバーが表示される

#### FCMエラー
- [ ] APNSトークン取得失敗時に再試行ログが表示される
- [ ] FCMトークン取得失敗時にエラーメッセージが表示される

---

## ⚠️ 重要な外部設定要件

### Firebase Console設定（プッシュ通知）

**必須**: 以下が設定されていない場合、プッシュ通知は届きません。

#### 方法1: APNs Auth Key (.p8) 推奨
1. Apple Developer Console > Keys
2. 「+」ボタンで新しいキーを作成
3. 「Apple Push Notifications service (APNs)」をチェック
4. .p8ファイルをダウンロード
5. Key IDとTeam IDをメモ
6. Firebase Console > プロジェクト設定 > Cloud Messaging
7. Apple アプリの設定 > APNs認証キー
8. .p8ファイル、Key ID、Team IDをアップロード

#### 方法2: APNs証明書 (.p12)
1. Apple Developer Console > Certificates
2. Development/Production Push証明書を作成
3. .p12ファイルをエクスポート
4. Firebase Console > Cloud Messaging > APNs証明書
5. Development用とProduction用の両方をアップロード

### AdMob設定

1. **AdMob管理画面で広告ユニットを確認**
   - iOS広告ユニットID: `ca-app-pub-8158788636349913/8549185583`
   - ステータスが「有効」であること

2. **新しい広告ユニットの場合**
   - 広告配信開始まで数時間～24時間かかる
   - その間はテスト広告IDで検証

3. **Info.plist設定確認**
   - `GADApplicationIdentifier`: ✅ 設定済み
   - `SKAdNetworkItems`: ✅ 設定済み
   - `NSUserTrackingUsageDescription`: ✅ 設定済み

---

## 🚀 リリース手順

### 1. テスト完了確認
- [ ] テスト広告が表示されることを確認
- [ ] Debug環境でプッシュ通知が届くことを確認
- [ ] すべての機能が正常動作することを確認

### 2. 本番設定に戻す
```dart
// lib/widgets/banner_ad_widget.dart
const bool USE_TEST_ADS = false; // ← falseに設定
```

### 3. クリーンビルド
```bash
flutter clean
flutter pub get
```

### 4. iOSアーカイブ
```bash
cd ios
pod install
cd ..
```

Xcodeで:
1. Product > Archive
2. Distribute App > App Store Connect
3. アップロード

### 5. TestFlightで最終確認
- [ ] TestFlightからインストール
- [ ] 実広告が表示されることを確認（または適切なエラーログ）
- [ ] プッシュ通知が届くことを確認

### 6. App Store審査提出
- リリースノートに変更内容を記載
- 審査を待つ

---

## 🔧 トラブルシューティング

### Q1: Xcodeで「Code Signing Entitlementsが見つかりません」エラー
**A**: 
1. Xcodeを閉じる
2. `ios`フォルダで以下を確認:
   ```bash
   ls -la Runner/Runner.entitlements
   ls -la Runner/RunnerRelease.entitlements
   ```
3. ファイルが存在することを確認
4. Xcodeを再度開く
5. Build Settings > Code Signing Entitlementsを再設定

### Q2: Debug環境でプッシュ通知が届かない
**A**:
1. `Runner.entitlements`が`development`になっているか確認
2. Firebase ConsoleにDevelopment APNs証明書が設定されているか確認
3. Xcodeから実機で実行していることを確認（シミュレータ不可）
4. ログで「🍎 APNSトークン取得成功」が表示されるか確認

### Q3: Release環境（TestFlight）でプッシュ通知が届かない
**A**:
1. Xcode Build Settings > Code Signing Entitlementsで:
   - Release: `Runner/RunnerRelease.entitlements` になっているか確認
2. Firebase ConsoleにProduction APNs証明書が設定されているか確認
3. TestFlightからインストール後、一度アプリを起動してFCMトークンを登録
4. Firebase Consoleからテスト通知を送信

### Q4: 広告が「NO_FILL」エラーになる
**A**:
1. テスト広告IDで試す（`USE_TEST_ADS = true`）
2. AdMob管理画面で広告ユニットIDを確認
3. 新しい広告ユニットの場合、24時間待つ
4. ATT権限を確認（設定 > プライバシー > トラッキング > Famica）

### Q5: ATT権限ダイアログが表示されない
**A**:
1. アプリをアンインストール
2. 設定 > プライバシー > トラッキング > リセット
3. アプリを再インストール
4. 初回起動時にダイアログが表示される

---

## 📊 期待される改善結果

### プッシュ通知
- ✅ Debug環境とRelease環境で適切なAPNs環境を使用
- ✅ 開発中もプッシュ通知のテストが可能
- ✅ App Store配信版で確実に通知が届く
- ✅ entitlementsファイルの管理が明確

### AdMob広告
- ✅ 1行の変更でテスト広告に切り替え可能
- ✅ 詳細なエラー診断で問題特定が容易
- ✅ エラーコード別の対処法が明確
- ✅ デバッグモードでエラーが視覚的にわかる

---

## 📚 参考資料

- [Firebase Cloud Messaging - iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [APNs Configuration](https://firebase.google.com/docs/cloud-messaging/ios/certs)
- [Google Mobile Ads SDK - iOS](https://developers.google.com/admob/ios/quick-start)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [Xcode Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)

---

**作成者**: Claude (Cline)  
**日時**: 2026年1月29日 12:35  
**バージョン**: 1.0.2+11
