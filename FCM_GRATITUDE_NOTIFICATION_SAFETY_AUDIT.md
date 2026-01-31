# FCM感謝メッセージ通知 安全性監査レポート

## 📅 調査日
2026年1月24日

## 🎯 調査目的
FCM通知実装において、gratitudeMessages（感謝メッセージ）の通知ロジックが他の通知（タスク・コスト）と比較して安全性に問題がないか調査。

---

## 1. Firestoreデータ構造の調査結果

### 1.1 gratitudeMessagesコレクション（実装済み）

**場所**: `gratitudeMessages/{messageId}` （ルートレベルコレクション）

**フィールド構成**（`FirestoreService.sendThanksCard`より）:
```dart
{
  'fromUserId': user.uid,          // ✅ 送信者UID
  'fromUserName': fromName,        // ✅ 送信者名
  'toUserId': toUserId,           // ✅ 受信者UID
  'toName': toName,               // ✅ 受信者名
  'message': message,             // ✅ メッセージ本文
  'isRead': false,                // ✅ 既読フラグ
  'createdAt': FieldValue.serverTimestamp()
}
```

### ❌ **重大な発見: householdIdフィールドが存在しない**

**比較: 他のコレクション**
- **タスク記録**: `households/{householdId}/records/{recordId}`
  - パスにhouseholdIdが含まれる ✅
- **コスト記録**: `households/{householdId}/costs/{costId}`
  - パスにhouseholdIdが含まれる ✅
- **感謝メッセージ**: `gratitudeMessages/{messageId}`
  - パスにhouseholdIdなし ❌
  - ドキュメントフィールドにもhouseholdIdなし ❌

---

## 2. Cloud Functions実装の比較分析

### 2.1 notifyTaskCreated（タスク記録通知）

**トリガー**: `households/{householdId}/records/{recordId}` onCreate

**通知先特定ロジック**:
```javascript
// 1. パスからhouseholdIdを取得
const { householdId, recordId } = context.params;

// 2. householdドキュメントからmembersを取得
const householdDoc = await admin.firestore()
  .collection('households')
  .doc(householdId)
  .get();

const members = householdDoc.data()?.members || [];

// 3. 送信者以外のメンバーに通知
const targetMembers = members.filter(m => m.uid !== actorUid);
```

**安全性**: ✅ **高い**
- householdベースで通知先を厳密に制御
- 同じ世帯のメンバーのみに通知

---

### 2.2 notifyCostCreated（コスト記録通知）

**トリガー**: `households/{householdId}/costs/{costId}` onCreate

**通知先特定ロジック**:
```javascript
// notifyTaskCreatedと同じロジック
// householdIdから世帯メンバーを取得し、送信者以外に通知
```

**安全性**: ✅ **高い**
- notifyTaskCreatedと同様に世帯ベースで制御

---

### 2.3 notifyLetterCreated（感謝メッセージ通知）⚠️

**トリガー**: `gratitudeMessages/{messageId}` onCreate

**通知先特定ロジック**:
```javascript
const toUserId = data.toUserId;

// 直接toUserIdのユーザーに通知
const userDoc = await admin.firestore().collection('users').doc(toUserId).get();

// ユーザー設定チェックのみ
if (userData.notificationsEnabled !== true) return;
if (userData.notifyPartnerActions !== true) return;

// トークン取得して送信
const tokens = userData.fcmTokens || {};
```

**⚠️ 重大な違い**:
- **household.membersを参照していない**
- **toUserIdが正しいパートナーか検証していない**
- ドキュメントに記載されたtoUserIdを信頼している

---

## 3. 現状評価と問題点

### 📊 総合評価: **⚠️ 要修正**

### 3.1 セキュリティリスク

#### 🔴 **リスク1: 世帯外ユーザーへの通知可能性（理論的）**

**シナリオ**:
1. ユーザーAとユーザーBが同じhousehold（世帯1）
2. 悪意あるクライアントがFirestoreルールを回避
3. 世帯外のユーザーC（世帯2）のuidを指定してgratitudeMessageを作成
4. ユーザーCに通知が飛ぶ

**現在の防御策**:
- Firestoreセキュリティルール（fallbackルール: 認証済みなら全て許可）
- ⚠️ **問題**: 現在のルールでは世帯ベースの書き込み制限がない

**実際のリスク**: **低〜中**
- 通常のアプリ使用では発生しない（UIがhousehold内のメンバーのみ表示）
- しかし、直接Firestore APIを使えば理論上可能

---

#### 🟡 **リスク2: Function失敗の可能性**

**ケース1: toUserIdが存在しない**
```javascript
const userDoc = await admin.firestore().collection('users').doc(toUserId).get();

if (!userDoc.exists) {
  console.log('⚠️ ユーザーが見つかりません');
  return null; // Functionは成功扱い、通知は送信されない
}
```

**影響**: 通知が飛ばない（サイレント失敗）

---

**ケース2: toUserIdが無効な文字列**
- 例: toUserId = "", null, undefined
- userDoc.existsがfalseになり、サイレント失敗

**影響**: 通知が飛ばない

---

#### 🟡 **リスク3: household情報の不整合**

**問題**: gratitudeMessagesにhouseholdIdがないため
- 通知ログが世帯単位で管理できない
- 削除時に世帯ごとのクリーンアップが困難
- メッセージと世帯の関連性が追跡不可

---

### 3.2 他の通知との一貫性の欠如

| 項目 | タスク/コスト通知 | 感謝メッセージ通知 |
|------|------------------|-------------------|
| householdId | ✅ パスに含む | ❌ なし |
| 通知先特定 | ✅ household.members | ❌ toUserIdを直接信頼 |
| 世帯ベース検証 | ✅ あり | ❌ なし |
| 重複防止ログ | ✅ あり | ❌ なし |
| 削除時の管理 | ✅ 世帯単位 | ❌ グローバル検索必要 |

---

## 4. 起こりうる問題の列挙

### 🚨 **問題A: 通知が飛ばないケース**

1. **toUserIdが空文字列・null**
   - 原因: クライアント側のバグ
   - 結果: userDoc.exists = false → サイレント失敗

2. **toUserIdが存在しないuid**
   - 原因: データ不整合（ユーザー削除後など）
   - 結果: 通知が送信されない

3. **toUserIdにFCMトークンがない**
   - 原因: トークン未登録・削除済み
   - 結果: 正常なスキップ（現在の実装で適切）

4. **通知設定がオフ**
   - 原因: ユーザーが設定でオフにした
   - 結果: 正常なスキップ（現在の実装で適切）

---

### 🔓 **問題B: 誤ったユーザーに飛ぶ可能性**

**シナリオ**: Firestoreセキュリティルールの不備を悪用

```javascript
// 悪意あるクライアントが実行（理論上）
await firestore.collection('gratitudeMessages').add({
  fromUserId: '自分のuid',
  toUserId: '世帯外のユーザーuid', // ← 世帯が違う
  message: '不正なメッセージ',
  ...
});
```

**現在の防御**:
- Firestoreルール: `allow read, write: if request.auth != null;` （fallback）
- ⚠️ **不十分**: 認証されていれば誰でも書き込み可能

**実際のリスク**: **低**（UIが制限しているため）
- しかし、直接API呼び出しでは可能

---

### 💥 **問題C: Function実行エラー**

1. **userData未定義エラー**
   - userDoc.existsのチェック後はOK
   - 現在の実装で対応済み ✅

2. **fcmTokensがundefined**
   - `const tokens = userData.fcmTokens || {};`
   - 現在の実装で対応済み ✅

3. **通知送信失敗**
   - try-catchでキャッチ済み
   - 現在の実装で対応済み ✅

---

## 5. 最小修正で済む対策案（参考）

### 🛠️ **対策1: gratitudeMessagesにhouseholdIdを追加（推奨）**

**実装箇所**: `FirestoreService.sendThanksCard`

```dart
// 現在の実装
final docRef = await _firestore
    .collection('gratitudeMessages')
    .add({
  'fromUserId': user.uid,
  'fromUserName': fromName,
  'toUserId': toUserId,
  'toName': toName,
  'message': message,
  'isRead': false,
  'createdAt': FieldValue.serverTimestamp(),
});

// 👇 修正案（householdIdを追加）
final householdId = await getCurrentUserHouseholdId();

final docRef = await _firestore
    .collection('gratitudeMessages')
    .add({
  'householdId': householdId,  // ← 追加
  'fromUserId': user.uid,
  'fromUserName': fromName,
  'toUserId': toUserId,
  'toName': toName,
  'message': message,
  'isRead': false,
  'createdAt': FieldValue.serverTimestamp(),
});
```

**メリット**:
- Cloud Functions側で世帯検証が可能に
- データ削除時の管理が容易
- 他の通知と一貫性が取れる

---

### 🛠️ **対策2: Cloud Functions側で世帯検証を追加（推奨）**

**実装箇所**: `functions/index.js` の `notifyLetterCreated`

```javascript
// 現在の実装
const toUserId = data.toUserId;
const userDoc = await admin.firestore().collection('users').doc(toUserId).get();

// 👇 修正案（世帯検証を追加）
const householdId = data.householdId; // 対策1で追加したフィールド
const fromUserId = data.fromUserId;

// 送信者と受信者が同じ世帯か検証
const householdDoc = await admin.firestore()
  .collection('households')
  .doc(householdId)
  .get();

if (!householdDoc.exists) {
  console.log('⚠️ 世帯が見つかりません');
  return null;
}

const members = householdDoc.data()?.members || [];
const memberUids = members.map(m => m.uid);

// 送信者と受信者が両方世帯メンバーか確認
if (!memberUids.includes(fromUserId) || !memberUids.includes(toUserId)) {
  console.log('⚠️ 世帯外のユーザーへの通知を拒否');
  return null;
}

// 以降、現在の処理
```

**メリット**:
- 世帯外ユーザーへの誤送信を防止
- セキュリティ向上

---

### 🛠️ **対策3: Firestoreセキュリティルールの強化**

**実装箇所**: `firestore.rules`

```javascript
// 現在の実装（fallback）
match /{document=**} {
  allow read, write: if request.auth != null;
}

// 👇 修正案（gratitudeMessages専用ルール追加）
match /gratitudeMessages/{messageId} {
  // 作成: 認証済みユーザーが自分のfromUserIdで作成する場合のみ
  allow create: if request.auth != null 
    && request.auth.uid == request.resource.data.fromUserId
    && request.resource.data.toUserId is string
    && request.resource.data.householdId is string;
  
  // 読取: 送信者または受信者のみ
  allow read: if request.auth != null
    && (request.auth.uid == resource.data.fromUserId
        || request.auth.uid == resource.data.toUserId);
  
  // 更新: 受信者のみ（既読フラグ更新用）
  allow update: if request.auth != null
    && request.auth.uid == resource.data.toUserId;
  
  // 削除: 禁止（管理機能で対応）
  allow delete: if false;
}
```

**メリット**:
- Firestoreレベルで不正な書き込みを防止
- fromUserIdの偽装を防止

---

### 🛠️ **対策4: 重複防止ログの追加**

**実装箇所**: `functions/index.js` の `notifyLetterCreated`

```javascript
// タスク/コスト通知と同様に重複防止を追加
const logId = `letter_${messageId}`;
const logRef = admin.firestore()
  .collection('households')
  .doc(householdId)
  .collection('notificationLogs')
  .doc(logId);

const logDoc = await logRef.get();
if (logDoc.exists) {
  console.log('ℹ️ 既に通知済み（重複防止）');
  return null;
}

// 通知送信後
await logRef.set({
  type: 'letter',
  docId: messageId,
  actorUid: fromUserId,
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

**メリット**:
- Function再実行時の重複通知を防止
- 他の通知と一貫性が取れる

---

## 6. 実装優先度

### 🔥 **高優先度（必須）**
1. **対策1**: gratitudeMessagesにhouseholdIdフィールド追加
2. **対策2**: Cloud Functions側で世帯検証追加
3. **対策3**: Firestoreセキュリティルール強化

### 🟡 **中優先度（推奨）**
4. **対策4**: 重複防止ログ追加

### 📝 **実装の順序**
1. 対策1（クライアント側修正）
2. 対策3（Firestoreルール修正）
3. 対策2（Cloud Functions修正）
4. 対策4（Cloud Functions追加機能）

---

## 7. 既存データへの影響

### ⚠️ 注意点
- **対策1を実装すると**: 既存のgratitudeMessagesにはhouseholdIdがない
- **対策2を実装すると**: householdIdがないメッセージの通知が失敗する

### 🛡️ 安全な移行手順
1. 対策1を実装（新規メッセージからhouseholdId付き）
2. 既存データのマイグレーション（オプション）
   ```javascript
   // 既存のgratitudeMessagesにhouseholdIdを補完
   // fromUserId/toUserId → users/{uid}.householdId を取得して追加
   ```
3. 対策2・3を実装（householdId必須に）

---

## 8. まとめ

### 📊 現状の安全性
- **通常使用**: ✅ **問題なし**（UIが制限）
- **直接API使用**: ⚠️ **リスクあり**（世帯外通知可能）
- **一貫性**: ❌ **低い**（他の通知と設計が異なる）

### ✅ 推奨アクション
1. **householdIdフィールド追加**（データ一貫性）
2. **Cloud Functions世帯検証**（セキュリティ向上）
3. **Firestoreルール強化**（不正書き込み防止）

### 📌 緊急性
- **即時対応不要**: 通常使用で問題は発生しない
- **次回更新時に対応推奨**: アーキテクチャの一貫性のため

---

**監査完了日**: 2026年1月24日  
**監査者**: システムアーキテクト  
**結論**: 通常使用では安全だが、アーキテクチャの一貫性とセキュリティ強化のため、上記対策の実装を推奨
