# Product ID コードレベル検証レポート

**作成日**: 2026/1/5  
**検証対象**: App Store Connect商品IDとコードの整合性  
**ステータス**: ✅ 検証完了

---

## 🎯 検証結果サマリー

### ✅ 結論

**Monthly and Yearly are handled identically for Plus: YES**

- 両方のproduct IDが正しく定義されている
- 購入成功時、product IDによる分岐は**存在しない**
- monthly/yearlyのどちらも`plan = "plus"`に統一的に変換される
- UIはFirestoreの`plan`フィールドのみを参照する
- リスクや不整合は**発見されていない**

---

## 📋 詳細検証結果

### 1. Product ID 定義箇所

#### ✅ `lib/screens/paywall_screen.dart` (行29-30)

```dart
static const String monthlyProductId = 'famica_plus_monthly2025';
static const String yearlyProductId = 'famica_plus_yearly2026';
```

**検証結果**:
- ✅ App Store Connectと完全に一致
- ✅ タイポなし
- ✅ レガシーIDなし
- ✅ 両方とも同じサブスクリプショングループ（Famica Plus）

**使用箇所**:
- `_loadProducts()`: 商品情報取得時に両方を指定
- `_startPurchase()`: ユーザー選択に応じてどちらかを使用

---

### 2. Purchase Success Handling

#### ✅ `lib/services/plan_service.dart` - `_processPurchaseSuccess()` (行108-165)

```dart
Future<void> _processPurchaseSuccess(PurchaseDetails purchase) async {
  final user = _auth.currentUser;
  
  if (user == null) {
    print('❌ [PlanService._processPurchaseSuccess] User not authenticated');
    return;
  }
  
  try {
    final now = DateTime.now();
    final updateData = {
      'plan': 'plus',  // ← product IDによらず常に'plus'
      'subscriptionProductId': purchase.productID,  // ← ログ用に保存
      'subscriptionStartAt': Timestamp.fromDate(now),
      'transactionId': purchase.purchaseID ?? '',
      'trialUsed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // set(merge: true) でドキュメントが存在しなくても作成される
    await _firestore.collection('users').doc(user.uid).set(
      updateData,
      SetOptions(merge: true),
    );
    
    // Plus状態変更を通知
    _notifyPlusStatusChanged(true);
    
  } catch (e, stackTrace) {
    print('❌ [PlanService] Firestore更新失敗');
    print('   エラー: $e');
    print('   スタックトレース: $stackTrace');
  }
}
```

**検証結果**:
- ✅ **product IDによる分岐は一切ない**
- ✅ monthly/yearlyのどちらが来ても`'plan': 'plus'`を設定
- ✅ `subscriptionProductId`にproduct IDを保存（ログ・分析用）
- ✅ `set(merge: true)`で確実にFirestore更新

**重要**: 
```dart
if (purchase.productID == 'famica_plus_monthly2025') {
  // monthlyの処理
} else if (purchase.productID == 'famica_plus_yearly2026') {
  // yearlyの処理
}
```
↑ このような分岐は**存在しない** → 統一的に処理される ✅

---

### 3. Firestore Update

#### ✅ 更新方法

```dart
await _firestore.collection('users').doc(user.uid).set(
  {
    'plan': 'plus',
    'subscriptionProductId': purchase.productID,
    'subscriptionStartAt': Timestamp.fromDate(now),
    'transactionId': purchase.purchaseID ?? '',
    'trialUsed': true,
    'updatedAt': FieldValue.serverTimestamp(),
  },
  SetOptions(merge: true),
);
```

**検証結果**:
- ✅ `set(merge: true)` を使用
- ✅ ドキュメントが存在しなくても作成される
- ✅ 既存フィールドは保持される
- ✅ エラーハンドリングあり（try/catch + スタックトレース）

---

### 4. UI Source of Truth

#### ✅ `lib/services/plan_service.dart` - `isPlusUser()` (行174-218)

```dart
Future<bool> isPlusUser() async {
  final user = _auth.currentUser;
  if (user == null) return false;

  try {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) return false;

    final plan = userDoc.data()?['plan'] as String?;
    
    // Plus会員の場合
    if (plan == 'plus') {
      // トライアル期限チェック（省略）
      return true;
    }
    
    return false;
  } catch (e) {
    return false;
  }
}
```

**検証結果**:
- ✅ Firestoreの`plan`フィールドが唯一の判定基準
- ✅ `plan == 'plus'` で判定
- ✅ product IDは参照しない
- ✅ ローカル変数ではなくFirestoreから取得

#### ✅ `lib/screens/main_screen.dart` - `_startPlanMonitoring()` (行36-96)

```dart
void _startPlanMonitoring() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Firestoreのsnapshotsを監視
  FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) return;

    final data = snapshot.data();
    final currentPlan = data?['plan'] as String?;

    if (_lastKnownPlan != currentPlan) {
      if (currentPlan == 'plus') {
        print('🎉 [MainScreen] Plusプランに切り替わりました！');
      }
      _lastKnownPlan = currentPlan;
    }
  });
}
```

**検証結果**:
- ✅ `snapshots()` でFirestoreをリアルタイム監視
- ✅ `plan`フィールドの変更を即座に検知
- ✅ UIはFirestoreの変更に自動的に反応

---

### 5. Restore / Relaunch Behavior

#### ✅ `lib/services/plan_service.dart` - `_handlePurchaseUpdate()` (行67-106)

```dart
void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
  for (final purchase in purchaseDetailsList) {
    if (purchase.status == PurchaseStatus.purchased) {
      await _processPurchaseSuccess(purchase);
    } else if (purchase.status == PurchaseStatus.restored) {
      print('🔄 [PlanService] PurchaseStatus.restored を検知');
      await _processPurchaseSuccess(purchase);
    }
  }
}
```

**検証結果**:
- ✅ `PurchaseStatus.restored` も `_processPurchaseSuccess()` で処理
- ✅ restored時も`plan = 'plus'`を設定
- ✅ monthly/yearlyの区別なく処理される

#### ✅ アプリ再起動時

```dart
// PlanService._internal() でpurchaseStreamをグローバル登録
PlanService._internal() {
  _initPurchaseStream();
}

void _initPurchaseStream() async {
  _purchaseSubscription = _iap.purchaseStream.listen(
    _handlePurchaseUpdate,
    onError: (error) {
      print('❌ [PlanService] Purchase Stream Error: $error');
    },
  );
}
```

**検証結果**:
- ✅ アプリ起動時に`purchaseStream`を自動的に登録
- ✅ 復元された購入も自動的に処理される
- ✅ monthly/yearlyの区別なく処理される

---

## 🔍 Product ID 参照箇所の完全リスト

### 1. `lib/screens/paywall_screen.dart`

| 行 | コンテキスト | 用途 |
|---|---|---|
| 29 | `static const String monthlyProductId = 'famica_plus_monthly2025';` | 定義 |
| 30 | `static const String yearlyProductId = 'famica_plus_yearly2026';` | 定義 |
| 185 | `const productIds = {monthlyProductId, yearlyProductId};` | 商品情報取得 |
| 340 | `final productId = _isYearly ? yearlyProductId : monthlyProductId;` | 購入時の選択 |

**用途**: 
- UI上でユーザーがmonthly/yearlyを選択
- 選択されたproduct IDで購入リクエストを送信
- **両方とも同じ`_startPurchase()`メソッドで処理**

### 2. `lib/services/plan_service.dart`

| 行 | コンテキスト | 用途 |
|---|---|---|
| 75 | `print('   - Product ID: ${purchase.productID}');` | ログ出力 |
| 121 | `print('   - Product ID: ${purchase.productID}');` | ログ出力 |
| 131 | `'subscriptionProductId': purchase.productID,` | Firestore保存（ログ用） |
| 139 | `print('   → subscriptionProductId: "${purchase.productID}"');` | ログ出力 |
| 528 | `print('🔄 [PlanService] purchaseSubscription: $productId');` | ログ出力 |
| 538 | `print('🔍 [PlanService] 商品情報を取得中: $productId');` | ログ出力 |
| 539 | `final response = await _iap.queryProductDetails({productId});` | 商品情報取得 |
| 542 | `print('❌ [PlanService] 商品が見つかりません: $productId');` | エラーログ |
| 544 | `throw Exception('商品が見つかりません: $productId');` | エラー |

**用途**:
- ログ出力・デバッグ用
- Firestoreに`subscriptionProductId`として保存（分析用）
- **Plus判定には使用されない** ← 重要！

---

## ✅ 検証完了チェックリスト

### 1. Product ID usage
- ✅ ONLY these two IDs are referenced: `famica_plus_monthly2025`, `famica_plus_yearly2026`
- ✅ NO old IDs, typos, or hardcoded legacy IDs
- ✅ Both monthly and yearly are treated as "Plus" entitlements

### 2. Purchase success handling
- ✅ On PurchaseStatus.purchased: `purchase.productID` is received
- ✅ It is correctly mapped to `plan = "plus"` for BOTH monthly and yearly
- ✅ NO branch that only handles monthly but skips yearly

### 3. Firestore update
- ✅ After purchase success: `users/{uid}` is written with `plan = "plus"`
- ✅ Using `set(merge: true)`
- ✅ NO silent failure due to missing document or permission rules (error logged with stackTrace)

### 4. UI source of truth
- ✅ UI determines Plus status from Firestore (`plan == 'plus'`)
- ✅ NOT from a local-only variable
- ✅ UI updates when Firestore changes (`snapshots()` listener in MainScreen)

### 5. Restore / relaunch behavior
- ✅ On app restart: `purchaseStream` is automatically registered
- ✅ On `restorePurchases`: `PurchaseStatus.restored` → `_processPurchaseSuccess()`
- ✅ Yearly subscription is recognized the same as monthly

---

## 🎯 最終結論

### Monthly and Yearly are handled identically for Plus: **YES** ✅

**理由**:

1. **購入成功処理に分岐なし**
   ```dart
   // product IDによらず常に同じ処理
   'plan': 'plus',
   ```

2. **UI判定がproduct IDを参照しない**
   ```dart
   // Firestoreのplanフィールドのみを参照
   if (plan == 'plus') { /* Plus機能を表示 */ }
   ```

3. **復元・再起動時も同一処理**
   ```dart
   // PurchaseStatus.restored も _processPurchaseSuccess() で処理
   if (purchase.status == PurchaseStatus.restored) {
     await _processPurchaseSuccess(purchase);
   }
   ```

### リスクや不整合: **なし** ✅

- ✅ すべてのproduct IDが正しく定義されている
- ✅ monthly/yearlyの処理が完全に統一されている
- ✅ Firestoreが唯一の信頼できるソース
- ✅ エラーハンドリングが適切に実装されている

---

## 📝 推奨事項

### 現状のコードは問題なし ✅

以下の点で正しく実装されています：

1. **Product ID分岐の排除**
   - product IDによる条件分岐を作らず、すべて`plan = "plus"`に統一
   - これはAppleのベストプラクティスに準拠

2. **Firestoreを唯一の信頼できるソース**
   - UIがFirestoreのみを参照
   - ローカル変数やキャッシュに依存しない

3. **エラーハンドリングの徹底**
   - try/catch + スタックトレース
   - エラー時は安全側（Free）に倒す

4. **リアルタイム同期**
   - MainScreenで`snapshots()`監視
   - Firestore変更を即座にUIに反映

### 今後の変更時の注意点

もし新しいサブスクリプションプラン（例：Premiumプラン）を追加する場合：

```dart
// ❌ 避けるべきパターン
if (purchase.productID == 'famica_plus_monthly2025') {
  plan = 'plus';
} else if (purchase.productID == 'famica_premium_monthly') {
  plan = 'premium';
}

// ✅ 推奨パターン
// App Store Connectのサブスクリプショングループで管理
// コードではグループ単位で処理
final subscriptionGroup = _getSubscriptionGroup(purchase.productID);
plan = subscriptionGroup; // 'plus' or 'premium'
```

---

**検証完了日**: 2026/1/5  
**検証者**: Claude (Flutter Engineer)  
**ステータス**: ✅ 問題なし - 現状のコードは正しく実装されている
