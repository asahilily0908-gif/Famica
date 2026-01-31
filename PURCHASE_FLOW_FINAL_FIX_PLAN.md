# 購入フロー最終修正プラン

**作成日**: 2026/1/2  
**問題**: StoreKit購入後、Firestoreが更新されずUIがPlusに切り替わらない  
**原因**: 責務の分散（PaywallScreenとPlanServiceで処理が分かれている）

---

## 🔍 現在の問題

### 現象
1. 「7日間無料で始める」ボタン押下 ✅
2. StoreKit購入UIが表示される ✅
3. ローディングが解除される ✅
4. **Firestoreの plan/isPlus が更新されない** ❌
5. **UIがFreeのまま** ❌

### 根本原因
- PaywallScreenでpurchaseStreamを処理
- しかし、PaywallScreenが破棄されると処理が中断される可能性
- PlanServiceに一元化されていない

---

## ✅ 修正方針

### 設計原則
1. **PlanService = 唯一の購入処理責務**
   - purchaseStreamのグローバルlisten
   - Firestore更新の一元管理
   - 状態変更の通知

2. **Firestore = Single Source of Truth**
   - UIはFirestoreのStreamのみを監視
   - ローカル状態での切り替えは禁止

3. **トライアル判定の完全委任**
   - App Store Connectに100%委任
   - アプリ側のトライアル判定ロジックを削除

---

## 🔧 修正内容

### 1. PlanService の修正

#### a) purchaseStreamのグローバルlisten追加
```dart
class PlanService {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  
  // シングルトン初期化時にpurchaseStreamを登録
  PlanService._internal() {
    _initPurchaseStream();
  }
  
  void _initPurchaseStream() async {
    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    
    if (!available) {
      print('⚠️ [PlanService] IAP利用不可');
      return;
    }
    
    // グローバルにpurchaseStreamを監視
    _purchaseSubscription = iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (error) {
        print('❌ [PlanService] Purchase Stream Error: $error');
      },
    );
    
    print('✅ [PlanService] purchaseStream グローバル登録完了');
  }
  
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      print('🔔 [PlanService] Purchase Update: ${purchase.status}');
      print('   - Product ID: ${purchase.productID}');
      print('   - Transaction ID: ${purchase.purchaseID}');
      
      if (purchase.status == PurchaseStatus.purchased) {
        // ここでのみFirestore更新
        await _processPurchaseSuccess(purchase);
      }
      
      // completePurchase必須
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }
}
```

#### b) Firestore更新のトランザクション保証
```dart
Future<void> _processPurchaseSuccess(PurchaseDetails purchase) async {
  final user = _auth.currentUser;
  if (user == null) {
    print('❌ [PlanService] User not authenticated');
    return;
  }
  
  try {
    print('🔄 [PlanService] Firestore更新開始');
    
    final now = DateTime.now();
    
    // users/{uid} を atomic に更新
    await _firestore.collection('users').doc(user.uid).update({
      'plan': 'plus',
      'subscriptionProductId': purchase.productID,
      'subscriptionStartAt': Timestamp.fromDate(now),
      'transactionId': purchase.purchaseID ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ [PlanService] Firestore更新成功');
    print('   → plan: plus');
    print('   → productId: ${purchase.productID}');
    
    // Plus状態変更を通知
    _notifyPlusStatusChanged(true);
    
  } catch (e) {
    print('❌ [PlanService] Firestore更新失敗: $e');
    // 失敗時は通知しない（UIはFreeのまま）
  }
}
```

### 2. PaywallScreen の修正

#### a) purchaseStream登録を削除
```dart
// ❌ 削除
// _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate, ...);

// ✅ PlanServiceに一元化されているため不要
```

#### b) 購入開始メソッドの簡略化
```dart
Future<void> _startPurchase() async {
  if (!mounted) return;
  
  setState(() => _isLoading = true);

  try {
    final productId = _isYearly ? yearlyProductId : monthlyProductId;
    
    // 購入リクエストのみ（結果はPlanServiceで処理）
    final success = await _planService.purchaseSubscription(productId);
    
    if (!success && mounted) {
      setState(() => _isLoading = false);
    }
    
    // 購入成功時の処理は不要
    // PlanServiceがplusStatusStreamで通知→UIが自動更新
    
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('購入を開始できませんでした: $e')),
    );
  }
}
```

#### c) PlanServiceのStreamを監視
```dart
@override
void initState() {
  super.initState();
  
  // PlanServiceのPlus状態変更を監視
  _plusStatusSubscription = _planService.plusStatusStream.listen((isPlus) {
    print('🔔 [PaywallScreen] Plus状態変更: $isPlus');
    
    if (isPlus && mounted) {
      // Plusになったら画面を閉じる
      setState(() => _isLoading = false);
      Navigator.of(context).pop(true);
    }
  });
  
  _initialize();
}

@override
void dispose() {
  _plusStatusSubscription?.cancel();
  super.dispose();
}
```

### 3. トライアル判定ロジックの削除

#### a) 削除するメソッド
```dart
// ❌ 削除
Future<bool> startTrial() async { ... }
Future<void> _markTrialAsUsed() async { ... }
```

#### b) 削除するFirestoreフィールド
```
- trialUsed（不要）
- trialEndDate（不要）
```

**理由**: トライアルか通常購入かはApp Store Connectが判定するため、
アプリ側でトライアル状態を管理する必要がない

---

## 📊 修正後の購入フロー

```
1. ユーザーがボタンをタップ
   ↓
2. PaywallScreen._startPurchase()
   ↓
3. PlanService.purchaseSubscription(productId)
   ↓
4. Apple StoreKit購入UI表示
   ↓
5. ユーザーが購入確認
   ↓
6. PurchaseStatus.purchased イベント発火
   ↓
7. PlanService._handlePurchaseUpdate() 自動実行
   【重要】PaywallScreenの生死に関係なく実行される
   ↓
8. PlanService._processPurchaseSuccess()
   ↓
9. Firestore users/{uid} を atomic に更新
   - plan: 'plus'
   - subscriptionProductId
   - subscriptionStartAt
   - transactionId
   ↓
10. PlanService._notifyPlusStatusChanged(true)
   ↓
11. PaywallScreen.plusStatusStream が発火
   ↓
12. setState(_isLoading = false)
   ↓
13. Navigator.pop()
   ↓
14. MainScreenがFirestore Streamを監視してPlus UIに切り替わる
```

---

## ✅ 修正により保証される事項

### 1. 購入処理の確実性
- ✅ PaywallScreenが破棄されても処理が継続
- ✅ PlanServiceがグローバルにpurchaseStreamを監視
- ✅ Firestore更新が確実に実行される

### 2. データ整合性
- ✅ Firestore更新がatomic
- ✅ 更新成功時のみUI切り替え
- ✅ 失敗時はFreeのまま（安全側）

### 3. 責務の明確化
- ✅ PlanService: 購入処理・Firestore更新
- ✅ PaywallScreen: 購入UI・ローディング表示
- ✅ Firestore: 唯一の真実

### 4. Apple審査対応
- ✅ Guideline 2.1: 完全に機能する
- ✅ Guideline 3.1.2: StoreKit経由の正規フロー
- ✅ Guideline 5.1.1: IAP以外の購入方法なし

---

## 🧪 テスト項目

### 1. 正常系
```
1. PaywallScreenで購入開始
2. StoreKit UIで確認
3. Firestore更新を確認
4. UI がPlus に切り替わることを確認
```

### 2. 画面遷移中の購入
```
1. PaywallScreenで購入開始
2. StoreKit UI表示中にPaywallScreenを閉じる
3. StoreKit UIで確認
4. Firestore更新を確認（PaywallScreen破棄後も）
5. MainScreenがPlus UIに切り替わることを確認
```

### 3. ネットワークエラー
```
1. 機内モードON
2. 購入開始
3. エラー表示を確認
4. 機内モードOFF
5. 再試行で成功することを確認
```

---

## 📝 Apple審査向け説明（英語）

```
We have implemented a robust subscription purchase flow that fully
complies with Apple's guidelines:

1. Single Source of Truth: All purchase events are processed through
   a global purchaseStream listener in PlanService, ensuring that
   subscription status is always correctly reflected regardless of
   UI lifecycle.

2. Firestore as State Manager: The app UI exclusively relies on
   Firestore streams for subscription status, guaranteeing data
   consistency and preventing any local state discrepancies.

3. Trial Determination Delegation: Trial vs. paid purchase logic
   is entirely delegated to App Store Connect's Introductory Offer
   settings, eliminating any app-side trial management code.

4. Transaction Integrity: Subscription data (plan, productId,
   startDate, transactionId) is atomically updated in Firestore
   only after StoreKit confirms the purchase.

This architecture ensures reliable subscription activation across
all scenarios (iPhone, iPad, Sandbox, Production) and prevents
the "purchase completed but not activated" issue reported in
previous reviews.
```

---

**修正完了予定日**: 2026/1/2  
**次のアクション**: 
1. PlanService修正
2. PaywallScreen修正
3. テスト実施
4. ドキュメント更新
