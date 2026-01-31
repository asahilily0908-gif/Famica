# Famicaアカウント削除機能 分析レポート

## 📋 実行日時
2025年11月9日 16:19

## 🎯 分析目的
アカウント削除機能が正常に動作するか確認し、改善点を提案する。

---

## 📊 現状の処理フロー

### 1. フロントエンド (lib/screens/settings_screen.dart)

```
[ユーザー] 
  ↓ 「アカウント削除」ボタンタップ
[確認ダイアログ] 「⚠️ アカウントを削除しますか？」
  ↓ 「削除する」タップ
[ローディング表示] "アカウントを削除しています..."
  ↓
[FirebaseAuth削除] await user.delete() ← ここで待機
  ↓
[Cloud Functions呼び出し] deleteUserData(uid) ← Fire-and-forget（待たない）
  ↓
[ローディング閉じる]
  ↓
[ログイン画面へ遷移] AuthScreen
```

### 2. バックエンド (functions/index.js)

**deleteUserData Cloud Function が削除するデータ:**
- ✅ `users/{uid}` ドキュメントとサブコレクション
- ✅ `households/{householdId}` 配下の以下:
  - `records` サブコレクション
  - `insights` サブコレクション
  - `costs` サブコレクション
  - household ドキュメント本体

---

## ⚠️ 検出された問題点

### 問題1: 削除の順序が逆

**現状:**
```dart
// 1. FirebaseAuthを先に削除（await）
await user.delete();

// 2. Firestoreを後で削除（fire-and-forget）
FirebaseFunctions.instance
    .httpsCallable('deleteUserData')
    .call({'uid': uid});
```

**リスク:**
- Auth削除後、Firestore削除の途中でエラーが発生しても気づけない
- ユーザーは削除されたがデータは残る可能性

**推奨順序:**
```
Firestore削除 → Auth削除 → 画面遷移
```

### 問題2: Cloud Functionsのクエリに潜在的な問題

**現在のコード:**
```javascript
const householdsSnapshot = await db
  .collection('households')
  .where('members', 'array-contains', { uid })
  .get();
```

**問題点:**
- `array-contains` はオブジェクトの完全一致を要求
- `members` フィールドの構造によっては一致しない可能性
- 実際のmembers構造: `[{uid: "...", nickname: "...", name: "..."}]`

**推奨修正:**
```javascript
// membersフィールドを配列のまま検索するのは難しいため、
// 全householdsを取得してフィルタリングする方が確実
const householdsSnapshot = await db.collection('households').get();
const targetHouseholds = householdsSnapshot.docs.filter(doc => {
  const members = doc.data().members || [];
  return members.some(m => m.uid === uid);
});
```

### 問題3: gratitudeMessagesが削除されていない

**削除されていないデータ:**
- `gratitudeMessages/{messageId}` - 送受信した感謝メッセージ

**影響:**
- 削除したユーザーの感謝メッセージが残る
- プライバシー上の問題

### 問題4: エラーハンドリングが十分でない

**現状:**
- Cloud Functionsの削除エラーは無視される（catch部分で success: true を返す）
- ユーザーには成功と表示されるが、実際にはデータが残る可能性

---

## ✅ 既に実装されている良い点

### 1. 再認証エラーハンドリング ✅
```dart
if (e.code == 'requires-recent-login') {
  _showReauthenticationDialog();
}
```
- `requires-recent-login` エラーを正しくキャッチ
- 再認証が必要な場合の適切な案内

### 2. 確認ダイアログ ✅
```dart
content: const Column(
  children: [
    Text('・すべての記録データ、パートナー共有情報、プラン情報が削除されます'),
    Text('・この操作は元に戻せません'),
    Text('本当に削除してもよろしいですか？'),
  ],
)
```
- ユーザーに十分な警告を表示

### 3. ローディング表示 ✅
- 削除処理中にローディングダイアログを表示
- UX的に適切

---

## 🔧 改善提案

### 提案1: 削除順序の修正（優先度: 高）

**修正箇所:** `lib/screens/settings_screen.dart` の `_deleteAccount()`

```dart
Future<void> _deleteAccount() async {
  showDialog(/* ローディング */);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('ユーザーが見つかりません');
    final uid = user.uid;

    // 【修正】1. 先にFirestoreを削除（await で待つ）
    final result = await FirebaseFunctions.instance
        .httpsCallable('deleteUserData')
        .call({'uid': uid});
    
    if (result.data['success'] != true) {
      throw Exception('Firestoreデータの削除に失敗しました');
    }

    // 【修正】2. 後でAuthを削除
    await user.delete();

    // 3. 画面遷移
    if (mounted) {
      Navigator.pop(context); // ローディング閉じる
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    // エラーハンドリング（既存のまま）
  }
}
```

### 提案2: Cloud Functionsのクエリ修正（優先度: 高）

**修正箇所:** `functions/index.js` の `deleteUserData`

```javascript
// 世帯データを検索して削除（修正版）
const householdsSnapshot = await db.collection('households').get();

for (const householdDoc of householdsSnapshot.docs) {
  const data = householdDoc.data();
  const members = data.members || [];
  
  // このユーザーがメンバーに含まれているか確認
  const isMember = members.some(m => m.uid === uid);
  
  if (isMember) {
    const householdRef = householdDoc.ref;
    console.log(`🏠 世帯データ削除中: ${householdRef.id}`);
    
    // サブコレクション削除（既存のまま）
    // ...
  }
}
```

### 提案3: gratitudeMessages削除の追加（優先度: 中）

**修正箇所:** `functions/index.js` の `deleteUserData` に追加

```javascript
// 感謝メッセージの削除を追加
const sentMessages = await db
  .collection('gratitudeMessages')
  .where('fromUserId', '==', uid)
  .get();

for (const msg of sentMessages.docs) {
  await msg.ref.delete();
}

const receivedMessages = await db
  .collection('gratitudeMessages')
  .where('toUserId', '==', uid)
  .get();

for (const msg of receivedMessages.docs) {
  await msg.ref.delete();
}

console.log(`✅ 感謝メッセージ削除完了: ${uid}`);
```

### 提案4: エラーハンドリングの改善（優先度: 中）

**修正箇所:** `functions/index.js` の `deleteUserData`

```javascript
exports.deleteUserData = functions.https.onCall(async (data, context) => {
  const errors = [];
  
  try {
    // ... 削除処理 ...
  } catch (error) {
    console.error('❌ ユーザーデータ削除エラー:', error);
    errors.push(error.message);
    
    // エラーを返す（ただし致命的でない場合は成功扱い）
    return { 
      success: errors.length === 0, 
      errors,
      note: errors.length > 0 ? 'partial-success' : 'completed'
    };
  }
});
```

---

## 🧪 テスト手順

### 1. 基本的な削除テスト
```
1. テストアカウントでログイン
2. いくつか記録を作成
3. パートナーと共有
4. 感謝メッセージを送受信
5. 設定画面で「アカウント削除」
6. 確認ダイアログで「削除する」
7. ログイン画面に戻ることを確認
```

### 2. Firestore削除確認
```
Firebase Console で以下を確認:
- users/{uid} が削除されているか
- households/{householdId} が削除されているか
- gratitudeMessages が削除されているか
```

### 3. 再認証エラーテスト
```
1. アカウント作成後30分以上経過させる
2. アカウント削除を試行
3. 「再認証が必要です」ダイアログが表示されることを確認
4. ログアウト → 再ログイン → 削除 が成功することを確認
```

---

## 📈 成功条件

- ✅ FirebaseAuthアカウントが削除される
- ✅ Firestoreの全ユーザーデータが削除される
- ✅ 世帯データ（records, insights, costs）が削除される
- ✅ 感謝メッセージが削除される
- ✅ 削除後にログイン画面へ遷移する
- ✅ `requires-recent-login` エラー時に再認証を促す

---

## 🎯 結論

### 現状評価: ⚠️ 要改善

**良い点:**
- 再認証エラーハンドリングが実装済み
- ユーザーへの警告が適切
- Cloud Functionsでバックグラウンド削除を実装

**改善が必要な点:**
- 削除順序の見直し（Firestore → Auth）
- Cloud Functionsのクエリ修正
- gratitudeMessages削除の追加
- エラーハンドリングの強化

### 推奨対応優先度

1. **高優先度**: 削除順序の修正、Cloud Functionsクエリ修正
2. **中優先度**: gratitudeMessages削除、エラーハンドリング改善
3. **低優先度**: 詳細なログ追加、削除確認メール送信

---

## 📝 補足

- auth_service.dart は存在しないため、全てsettings_screen.dartに実装されている
- 現状でも基本的な削除は機能するが、エッジケースで問題が発生する可能性がある
- 本番環境でテストする前に、必ずFirebase Emulatorでテストすること
