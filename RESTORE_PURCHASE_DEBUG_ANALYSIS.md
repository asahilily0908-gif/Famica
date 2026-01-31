# 購入復元（Restore Purchase）デバッグ分析レポート

**作成日**: 2026/1/5  
**問題**: 「購入を復元」ボタンを押しても反応がない  
**ステータス**: 🔍 調査中

---

## ✅ コード検証結果

### 1. purchaseStreamのリスナー登録
**場所**: `lib/services/plan_service.dart` - `_initPurchaseStream()`

```dart
// ✅ 正しく実装されている
_purchaseSubscription = _iap.purchaseStream.listen(
  _handlePurchaseUpdate,
  onError: (error) {
    print('❌ [PlanService] Purchase Stream Error: $error');
  },
);
```

**結果**: ✅ グローバルに登録されている（PaywallScreenの生死に関係なく動作）

---

### 2. PurchaseStatus.restoredのハンドリング
**場所**: `lib/services/plan_service.dart` - `_handlePurchaseUpdate()` (95-98行目)

```dart
} else if (purchase.status == PurchaseStatus.restored) {
  print('🔄 [PlanService] PurchaseStatus.restored を検知');
  print('🔄 [PlanService] Firestore更新を開始します...');
  await _processPurchaseSuccess(purchase);
}
```

**結果**: ✅ 正しく実装されている（purchasedと同じ処理）

---

### 3. completePurchaseの呼び出し
**場所**: `lib/services/plan_service.dart` - `_handlePurchaseUpdate()` (101-105行目)

```dart
// completePurchase必須（Appleへの完了通知）
if (purchase.pendingCompletePurchase) {
  print('🔄 [PlanService] completePurchase()を呼び出し');
  await _iap.completePurchase(purchase);
  print('✅ [PlanService] completePurchase()完了');
}
```

**結果**: ✅ 正しく実装されている

---

### 4. Firestore更新処理
**場所**: `lib/services/plan_service.dart` - `_processPurchaseSuccess()`

```dart
final user = _auth.currentUser;  // ✅ 最新のUIDを取得

await _firestore.collection('users').doc(user.uid).set(
  {
    'plan': 'plus',
    'subscriptionProductId': purchase.productID,
    'subscriptionStartAt': Timestamp.fromDate(now),
    'transactionId': purchase.purchaseID ?? '',
    'trialUsed': true,
    'updatedAt': FieldValue.serverTimestamp(),
  },
  SetOptions(merge: true),  // ✅ set(merge: true)を使用
);
```

**結果**: ✅ 正しく実装されている

---

## 🔍 問題の可能性

### 可能性1: 復元する購入履歴がない

**症状**:
- `restorePurchases()`は成功する
- しかし、`purchaseStream`にイベントが流れてこない

**原因**:
- Sandboxアカウントで購入履歴がない
- 購入したApple IDと復元しようとしているApple IDが異なる
- サブスクリプションが既にキャンセルされている

**確認方法**:
```
1. 設定 > App Store > Apple ID > サブスクリプション
2. 該当アプリのサブスクリプションが存在するか確認
```

### 可能性2: イベントが発火していない

**症状**:
- `restorePurchases()`は成功する
- ログに「🔄 [PlanService._handlePurchaseUpdate] イベント受信」が出ない

**原因**:
- `purchaseStream`がリッスンされていない（初期化失敗）
- Appleのサーバーからレスポンスが返ってこない

### 可能性3: ユーザーがログインしていない

**症状**:
- イベントは受信される
- しかし「❌ [PlanService._processPurchaseSuccess] User not authenticated」が出る

**原因**:
- Firebase Authにログインしていない
- `_auth.currentUser`が`null`

---

## 📊 デバッグログの追跡ポイント

復元ボタンを押した後、以下のログが順番に出るはずです：

### 正常フロー

```
1. 🔄 [PaywallScreen] 購入復元開始

2. 🔄 [PlanService] 購入復元開始
   📱 [PlanService] IAP利用可能: true
   🔄 [PlanService] restorePurchases()を呼び出し
   ✅ [PlanService] restorePurchases()完了

3. 🔔 [PlanService._handlePurchaseUpdate] イベント受信: 1件
   
4. 📦 [PlanService] Purchase Event Details:
      - Status: PurchaseStatus.restored
      - Product ID: famica_plus_yearly2026
      - Firebase Auth UID: abc123...

5. 🔄 [PlanService] PurchaseStatus.restored を検知
   🔄 [PlanService] Firestore更新を開始します...

6. 🔄 [PlanService] Firestore更新開始
   📝 [PlanService] users/abc123 に書き込み中...
   ✅ [PlanService] users/abc123 更新成功

7. 🔔 [PlanService] Plus状態変更通知: isPlus=true

8. 🎉 [MainScreen] Plusプランに切り替わりました！
```

### 復元する購入がない場合

```
1. 🔄 [PaywallScreen] 購入復元開始

2. 🔄 [PlanService] 購入復元開始
   📱 [PlanService] IAP利用可能: true
   🔄 [PlanService] restorePurchases()を呼び出し
   ✅ [PlanService] restorePurchases()完了

3. （ここで止まる - イベントが来ない）
```

---

## 🧪 テスト手順

### 前提条件

1. **Sandboxアカウントでログイン**:
   ```
   設定 > App Store > Apple ID からサインアウト
   アプリ内で購入時にSandboxアカウントでログイン
   ```

2. **一度購入を完了させる**:
   ```
   PaywallScreenで「7日間無料で始める」をタップ
   購入完了後、Plus機能が使えることを確認
   ```

### テストケース1: アプリ再インストール

```
1. アプリをアンインストール
2. アプリを再インストールして起動
3. 同じFirebaseアカウントでログイン
4. PaywallScreenを開く
5. 「購入を復元する」ボタンをタップ
6. ログを確認
```

**期待される結果**:
- Plus機能が復元される
- PaywallScreenが自動的に閉じる

### テストケース2: アカウント削除後の復元

```
1. アプリ内でアカウント削除
2. 新しいFirebaseアカウントで登録
3. PaywallScreenを開く
4. 「購入を復元する」ボタンをタップ
5. ログを確認
```

**期待される結果**:
- Appleが「既に購入済みです」と表示
- 新しいUIDに対してPlus機能が復元される

---

## 💡 トラブルシューティング

### ログに「IAP利用可能: false」と出る場合

**原因**: In-App Purchaseが初期化されていない

**対処法**:
```dart
// main.dartで初期化を確認
await InAppPurchase.instance.isAvailable();
```

### ログに「イベント受信」が出ない場合

**原因**: 復元する購入履歴がない、またはAppleのサーバーエラー

**対処法**:
1. 設定 > App Store > サブスクリプション で購入履歴を確認
2. 別のSandboxアカウントでテスト
3. 実機で再テスト（シミュレーターでは不安定）

### ログに「User not authenticated」と出る場合

**原因**: Firebase Authにログインしていない

**対処法**:
```dart
// 復元前にログイン状態を確認
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // ログイン画面に遷移
}
```

---

## 🎯 次のステップ

### 1. デバッグログの確認

復元ボタンを押した後、以下を確認してください：

- [ ] 「🔄 [PaywallScreen] 購入復元開始」が出る
- [ ] 「🔄 [PlanService] 購入復元開始」が出る
- [ ] 「✅ [PlanService] restorePurchases()完了」が出る
- [ ] 「🔔 [PlanService._handlePurchaseUpdate] イベント受信」が出る
- [ ] 「📦 [PlanService] Purchase Event Details」が出る
- [ ] 「Status: PurchaseStatus.restored」が出る

### 2. Appleのポップアップ確認

復元ボタンを押した後、以下を確認してください：

- [ ] 「既に購入済みです」というポップアップが出る
- [ ] ポップアップで「OK」をタップ
- [ ] その後にログが出るか確認

### 3. 購入履歴の確認

```
設定 > App Store > Apple ID > サブスクリプション
```

- [ ] Famicaのサブスクリプションが表示される
- [ ] ステータスが「アクティブ」または「トライアル中」
- [ ] Apple IDが正しい

---

## 📝 実装確認済み項目

- [x] `purchaseStream`のリスナー登録
- [x] `PurchaseStatus.restored`のハンドリング
- [x] `completePurchase()`の呼び出し
- [x] Firestore更新処理（`set(merge: true)`）
- [x] 最新のUIDの使用（`_auth.currentUser`）
- [x] Plus状態変更通知（`plusStatusStream`）
- [x] エラーハンドリング（try/catch + スタックトレース）

---

**調査完了日**: 2026/1/5  
**調査者**: Claude (Flutter Engineer)  
**結論**: コード実装は正しい。問題はテスト環境またはApple側の可能性が高い。
