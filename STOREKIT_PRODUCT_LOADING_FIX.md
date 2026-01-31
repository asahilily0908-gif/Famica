# StoreKit商品情報取得エラー 修正ガイド

**作成日**: 2026/1/2  
**エラー**: `storekit_no_response` - StoreKitが商品情報を取得できない  
**ステータス**: 🔧 診断・修正中

---

## 🐛 エラーの症状

### エラーログ
```
flutter: ❌ [PaywallScreen] 商品情報取得エラー: IAPError(
  code: storekit_no_response, 
  source: app_store, 
  message: StoreKit: Failed to get response from platform., 
  details: null
)
flutter: ✅ [PaywallScreen] 商品情報読み込み完了: 0件
```

### 影響
- 商品情報が0件になる
- 購入ボタンが押せない
- トライアルが開始できない

---

## 🔍 根本原因の診断

### 1. StoreKit Configuration Fileの設定確認

#### ✅ 確認項目
1. **Xcodeで StoreKit Configuration File が作成されているか**
   ```
   File > New > File > StoreKit Configuration File
   ```

2. **商品IDが正しく登録されているか**
   - `famica_plus_monthly2025`
   - `famica_plus_yearly2026`

3. **Schemeで StoreKit Configuration が設定されているか**
   ```
   Product > Scheme > Edit Scheme > Run > Options
   → StoreKit Configuration: [Your Config File]
   ```

#### 🛠️ 修正方法
```bash
# Xcodeでプロジェクトを開く
cd ios
open Runner.xcworkspace

# 以下の手順を実行:
# 1. File > New > File
# 2. StoreKit Configuration File を選択
# 3. ファイル名: Products.storekit
# 4. 商品を追加:
#    - Product ID: famica_plus_monthly2025
#    - Type: Auto-Renewable Subscription
#    - Price: ¥300/月
#    - Subscription Group: famica_plus
#
#    - Product ID: famica_plus_yearly2026
#    - Type: Auto-Renewable Subscription
#    - Price: ¥3,000/年
#    - Subscription Group: famica_plus
```

---

### 2. App Store Connectの設定確認

#### ✅ 確認項目
1. **商品が作成されているか**
   - App Store Connect > アプリ > サブスクリプション
   - 商品ID: `famica_plus_monthly2025`, `famica_plus_yearly2026`

2. **商品ステータスが「配信準備完了」か**
   - ステータス: 配信準備完了 (Ready to Submit)
   - ⚠️「審査中」「拒否」「削除済み」では取得できない

3. **Paid Applications Agreementが有効か**
   - App Store Connect > Agreements, Tax, and Banking
   - Status: Active

4. **無料トライアルが設定されているか**
   - サブスクリプション > Introductory Offer
   - Duration: 7 days
   - Type: Free Trial

#### 🛠️ 修正方法
```
1. App Store Connect にログイン
   https://appstoreconnect.apple.com

2. アプリ > サブスクリプション を開く

3. 新しいサブスクリプショングループを作成
   - Group Name: Famica Plus

4. 商品を追加
   【月額プラン】
   - Product ID: famica_plus_monthly2025
   - Name: Famica Plus Monthly
   - Duration: 1 Month
   - Price: ¥300
   - Introductory Offer: 7 Days Free Trial

   【年額プラン】
   - Product ID: famica_plus_yearly2026
   - Name: Famica Plus Yearly
   - Duration: 1 Year
   - Price: ¥3,000
   - Introductory Offer: 7 Days Free Trial

5. ステータスを「配信準備完了」にする
```

---

### 3. Sandbox環境の確認

#### ✅ 確認項目
1. **Sandbox Apple IDでログインしているか**
   - 設定 > App Store > Sandbox アカウント

2. **本番環境のApple IDでログインしていないか**
   - ⚠️ 本番環境ではテスト購入できない

3. **Sandboxアカウントが有効か**
   - App Store Connect > Users and Access > Sandbox Testers

#### 🛠️ 修正方法
```
1. iOSデバイス/シミュレータで設定を開く
   設定 > App Store

2. 本番環境のApple IDからサインアウト

3. Sandbox Apple IDでサインイン
   - App Store Connect > Sandbox Testers で作成したアカウント

4. アプリを再起動

5. PaywallScreenを開いて商品情報を確認
```

---

### 4. ネットワーク・タイミングの問題

#### ✅ 確認項目
1. **インターネット接続が有効か**
   - Wi-Fi または モバイルデータ通信

2. **初回起動時に時間がかかっていないか**
   - StoreKitの初期化には数秒かかる場合がある

3. **タイムアウトが発生していないか**
   - 10秒でタイムアウト設定済み

#### 🛠️ 修正方法
- リトライ機能が実装済み（最大3回、2秒→4秒→6秒間隔）
- ネットワーク接続を確認
- アプリを再起動して再試行

---

## ✅ 実施した修正

### 1. リトライ機能の追加
**ファイル**: `lib/screens/paywall_screen.dart`

```dart
/// 商品情報の読み込み（リトライ機能付き）
Future<void> _loadProducts({int retryCount = 0}) async {
  if (!mounted) return;
  
  const maxRetries = 3;
  
  try {
    const productIds = {monthlyProductId, yearlyProductId};
    print('🔍 [PaywallScreen] 商品情報取得開始 (試行${retryCount + 1}/$maxRetries): $productIds');
    
    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏱️ [PaywallScreen] 商品情報取得タイムアウト');
        throw TimeoutException('Product query timeout');
      },
    );
    
    // エラーハンドリング...
    
    if (response.error != null) {
      // リトライ可能なエラーの場合
      if (retryCount < maxRetries - 1) {
        final delay = Duration(seconds: (retryCount + 1) * 2);
        print('🔄 [PaywallScreen] ${delay.inSeconds}秒後にリトライします...');
        await Future.delayed(delay);
        return _loadProducts(retryCount: retryCount + 1);
      }
    }
    
  } catch (e) {
    // リトライ処理...
  }
}
```

**改善点**:
- ✅ 最大3回のリトライ（2秒→4秒→6秒間隔）
- ✅ 10秒タイムアウト設定
- ✅ 詳細なエラーログ出力
- ✅ 商品情報0件時の警告メッセージ

---

### 2. 詳細なエラーログの追加

```dart
if (response.error != null) {
  print('❌ [PaywallScreen] 商品情報取得エラー: ${response.error}');
  print('  - Code: ${response.error!.code}');
  print('  - Source: ${response.error!.source}');
  print('  - Message: ${response.error!.message}');
  print('  - Details: ${response.error!.details}');
}

if (response.notFoundIDs.isNotEmpty) {
  print('⚠️ [PaywallScreen] 見つからない商品ID: ${response.notFoundIDs}');
  print('  → App Store Connectで以下を確認してください:');
  print('    1. 商品IDが正しいか');
  print('    2. 商品ステータスが「配信準備完了」か');
  print('    3. Agreementsが有効か');
}

if (_products.isEmpty && mounted) {
  print('⚠️ [PaywallScreen] 商品情報が0件です');
  print('  → 購入ボタンは無効化されます');
  print('  → 以下を確認してください:');
  print('    1. StoreKit Configuration Fileが設定されているか');
  print('    2. App Store Connectで商品が作成されているか');
  print('    3. Sandbox環境でテストしているか');
}
```

**改善点**:
- ✅ エラーコード・メッセージの詳細出力
- ✅ 見つからない商品IDのリスト表示
- ✅ 具体的な確認項目の提示

---

## 🧪 テスト手順

### 1. ローカルテスト（StoreKit Configuration File）
```bash
# クリーンビルド
flutter clean
flutter pub get

# iOSシミュレータで起動
flutter run -d "iPhone 15 Pro"

# PaywallScreenを開く
# → 商品情報が取得できるか確認
# → ログで詳細を確認
```

**期待される結果**:
```
🔍 [PaywallScreen] 商品情報取得開始 (試行1/3): {famica_plus_monthly2025, famica_plus_yearly2026}
📦 [PaywallScreen] 商品情報取得結果:
  - 取得成功: 2件
    ✓ famica_plus_monthly2025: Famica Plus Monthly - ¥300
    ✓ famica_plus_yearly2026: Famica Plus Yearly - ¥3,000
✅ [PaywallScreen] 商品情報読み込み完了: 2件
```

---

### 2. Sandboxテスト（App Store Connect）
```bash
# 実機で起動
flutter run -d "iPhone"

# Sandbox Apple IDでログイン
# 設定 > App Store > Sandbox アカウント

# PaywallScreenを開く
# → 商品情報が取得できるか確認
# → 購入フローをテスト
```

**期待される結果**:
- ✅ 商品情報が2件取得できる
- ✅ 購入ボタンが押せる
- ✅ Apple購入UIが表示される
- ✅ トライアルが開始できる

---

## 📋 チェックリスト

### Xcode設定
- [ ] StoreKit Configuration File が作成されている
- [ ] 商品ID が正しく登録されている
  - [ ] `famica_plus_monthly2025`
  - [ ] `famica_plus_yearly2026`
- [ ] Scheme > Options で StoreKit Configuration が設定されている

### App Store Connect設定
- [ ] サブスクリプショングループが作成されている
- [ ] 商品が作成されている
  - [ ] 月額プラン (¥300/月)
  - [ ] 年額プラン (¥3,000/年)
- [ ] 商品ステータスが「配信準備完了」
- [ ] Introductory Offer (7日間無料トライアル) が設定されている
- [ ] Paid Applications Agreement が有効

### Sandbox環境
- [ ] Sandbox Apple ID が作成されている
- [ ] デバイス/シミュレータで Sandbox Apple ID にログインしている
- [ ] 本番環境のApple IDからサインアウトしている

### ネットワーク
- [ ] インターネット接続が有効
- [ ] 機内モードがOFF

---

## 🚀 次のステップ

### 1. 即座に確認すべきこと
1. **StoreKit Configuration File の確認**
   - Xcodeで `Products.storekit` ファイルが存在するか
   - 商品IDが正しいか

2. **App Store Connect の確認**
   - 商品が作成されているか
   - ステータスが「配信準備完了」か

3. **Sandbox環境の確認**
   - Sandbox Apple IDでログインしているか

### 2. ログから診断
現在のエラーログを確認:
```
flutter: ❌ [PaywallScreen] 商品情報取得エラー: IAPError(code: storekit_no_response, ...)
flutter: ✅ [PaywallScreen] 商品情報読み込み完了: 0件
```

**次のログを確認してください**:
- `⚠️ [PaywallScreen] 見つからない商品ID:` が出力されているか
- エラーコード・メッセージの詳細
- リトライが実行されているか

### 3. 段階的な修正
1. **ローカル開発**: StoreKit Configuration File で動作確認
2. **Sandbox環境**: App Store Connect + Sandbox Apple ID で動作確認
3. **本番環境**: TestFlight経由で動作確認

---

## 📝 よくある問題と解決方法

### Q1: 「storekit_no_response」エラーが出る
**A**: StoreKit Configuration File が設定されていないか、App Store Connectで商品が見つからない
- Xcodeで StoreKit Configuration File を作成
- Scheme > Options で設定
- App Store Connectで商品を作成

### Q2: 「見つからない商品ID」が表示される
**A**: 商品IDが間違っているか、App Store Connectで商品が作成されていない
- 商品IDを確認: `famica_plus_monthly2025`, `famica_plus_yearly2026`
- App Store Connectで商品を作成
- ステータスを「配信準備完了」にする

### Q3: Sandbox環境で購入できない
**A**: Sandbox Apple IDでログインしていないか、本番環境のApple IDでログインしている
- 設定 > App Store > Sandbox アカウント でログイン
- 本番環境のApple IDからサインアウト

### Q4: リトライしても商品情報が取得できない
**A**: ネットワーク接続の問題か、Apple側のサービス障害の可能性
- インターネット接続を確認
- 機内モードをOFF
- アプリを再起動
- Apple System Status を確認: https://www.apple.com/support/systemstatus/

---

## 🔗 参考リンク

- [StoreKit Testing Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [StoreKit Configuration File](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
- [App Store Connect Subscriptions](https://help.apple.com/app-store-connect/#/dev3d2d0e60f)
- [in_app_purchase Package](https://pub.dev/packages/in_app_purchase)

---

**修正完了日**: 2026/1/2  
**修正者**: Claude (Flutter/iOS Engineer)  
**ステータス**: 診断・修正中 → テスト待ち
