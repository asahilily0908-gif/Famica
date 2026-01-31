# 🚨 重大な問題発見: Firestoreセキュリティルールが招待を阻止

## 📅 発見日時
2025年11月6日

## 🔴 根本原因

**Firestoreのセキュリティルールが、招待コード経由での新規ユーザーのhousehold参加を拒否しています。**

### 問題のあるルール

```javascript
// firestore.rules
function isHouseholdMember(householdId) {
  return request.auth != null &&
    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.householdId == householdId;
}

match /households/{householdId} {
  allow read, write: if request.auth != null && isHouseholdMember(householdId);
}
```

### なぜ失敗するのか

**Transaction内での実行順序:**

1. 新しいユーザーB が Firebase Authで作成される ✅
2. **Transaction開始**
3. `transaction.set(users/{B_uid}, {...})` を実行（まだコミットされていない）
4. `transaction.update(households/{A_householdId}, {...})` を実行しようとする
5. **Firestoreルールチェック:** `isHouseholdMember(A_householdId)` を評価
6. `get(/databases/.../users/{B_uid}).data.householdId == A_householdId` をチェック
7. **❌ しかし、users/{B_uid} はまだTransactionがコミットされていないので存在しない！**
8. **❌ ルールチェック失敗 → households更新が拒否される**
9. **❌ Transaction全体が失敗**

### Transaction内でのget()の制限

Firestore Transaction内では：
- `transaction.get()` で読み取ったドキュメントは、Transactionがコミットされるまで外部から見えない
- セキュリティルールの `get()` は、**Transaction外部の視点**からドキュメントを評価する
- **そのため、Transaction内で作成したusersドキュメントは、セキュリティルールからは「存在しない」と判定される**

## 🔧 解決策

### 解決策1: Firestoreルールに招待参加の例外を追加（推奨）

```javascript
// firestore.rules の修正版
function isHouseholdMember(householdId) {
  return request.auth != null &&
    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.householdId == householdId;
}

// 新しいヘルパー関数を追加
function isValidInviteParticipation(householdId) {
  // householdドキュメントが存在し、members配列に自分のuidが追加される場合
  return request.auth != null &&
    exists(/databases/$(database)/documents/households/$(householdId)) &&
    // リクエストデータのmembers配列に自分のuidが含まれている
    request.auth.uid in request.resource.data.members.map(member => member.uid);
}

match /households/{householdId} {
  // 既存メンバーまたは有効な招待参加の場合に許可
  allow read: if request.auth != null && isHouseholdMember(householdId);
  allow write: if request.auth != null && 
    (isHouseholdMember(householdId) || isValidInviteParticipation(householdId));
}
```

### 解決策2: Transactionを分割（非推奨 - 原子性が失われる）

```dart
// 1. まず users/{uid} を作成
await FirebaseFirestore.instance.collection('users').doc(user.uid).set({...});

// 2. 次に households/{id} を更新
await FirebaseFirestore.instance.collection('households').doc(householdId).update({...});
```

**問題点:** 原子性が失われ、途中で失敗すると不整合が生じる

### 解決策3: Cloud Functions（最も堅牢だが複雑）

```javascript
// functions/index.js
exports.joinHouseholdWithInvite = functions.https.onCall(async (data, context) => {
  // Admin SDKを使用するとセキュリティルールをバイパスできる
  // ここで users作成 + household参加を実行
});
```

## 📊 推奨する修正

**解決策1（Firestoreルールの修正）を推奨します。**

理由：
1. コードの変更が最小限
2. Transaction の原子性を保持
3. セキュリティを維持しつつ招待参加を許可

## 🔧 具体的な修正手順

### Step 1: firestore.rules を修正

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ヘルパー関数：ユーザーのhouseholdIdと一致するかチェック
    function isHouseholdMember(householdId) {
      return request.auth != null &&
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.householdId == householdId;
    }
    
    // ★ 新しいヘルパー関数を追加
    function isJoiningHousehold(householdId) {
      // 新規参加: リクエストのmembers配列に自分のuidが含まれている
      return request.auth != null &&
        exists(/databases/$(database)/documents/households/$(householdId)) &&
        request.resource.data.members != null &&
        request.auth.uid in request.resource.data.members.map(m => m.uid);
    }
    
    // ユーザー情報：本人のみ読み書き可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 世帯情報とそのサブコレクション
    match /households/{householdId} {
      // ★ read は既存メンバーのみ
      allow read: if request.auth != null && isHouseholdMember(householdId);
      
      // ★ write は既存メンバー OR 新規参加の場合に許可
      allow write: if request.auth != null && 
        (isHouseholdMember(householdId) || isJoiningHousehold(householdId));
      
      // 以下、サブコレクションは変更なし
      match /records/{recordId} {
        allow read, write: if request.auth != null && isHouseholdMember(householdId);
      }
      // ... 他のサブコレクション
    }
    
    // ... 残りは変更なし
  }
}
```

### Step 2: Firestoreルールをデプロイ

```bash
firebase deploy --only firestore:rules
```

### Step 3: テスト

1. 新規ユーザーAを登録（household作成）
2. 招待コードを取得
3. 新規ユーザーBが招待コードで参加
4. **✅ Transaction成功**
5. **✅ households/{A_householdId}/members に B_uid が追加される**
6. **✅ users/{B_uid}.householdId が設定される**

## 🎯 なぜこれで解決するのか

### 修正前
```
Transaction内:
1. users/{B_uid} 作成（まだ見えない）
2. households/{A_id} 更新を試みる
   → ルールチェック: isHouseholdMember(A_id)
   → users/{B_uid} が存在しない（見えない）
   → ❌ 拒否
```

### 修正後
```
Transaction内:
1. users/{B_uid} 作成（まだ見えない）
2. households/{A_id} 更新を試みる
   → ルールチェック: isHouseholdMember(A_id) || isJoiningHousehold(A_id)
   → isHouseholdMember は false
   → isJoiningHousehold をチェック:
      - households/{A_id} は存在する ✅
      - request.resource.data.members に B_uid が含まれている ✅
   → ✅ 許可
```

## 🚨 セキュリティ上の注意

`isJoiningHousehold` 関数は以下を確認しています：
1. householdドキュメントが実際に存在する
2. リクエストのmembers配列に自分のuidが含まれている

これにより：
- ✅ 存在しないhouseholdには参加できない
- ✅ 自分以外のuidを追加することはできない
- ✅ 既存メンバーの削除はできない（isHouseholdMemberが必要）

## 📝 まとめ

**根本原因:** Firestoreのセキュリティルールが、Transaction内での新規ユーザーのhousehold参加を拒否

**解決策:** ルールに `isJoiningHousehold` 関数を追加し、新規参加を許可

**次のステップ:** firestore.rules を修正してデプロイ
