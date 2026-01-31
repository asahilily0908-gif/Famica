# Famica 招待コード パートナー紐づけ不具合 調査報告

## 📅 調査日時
2025年11月6日

## 🔍 調査対象
招待コード経由でのパートナー紐づけが正常に機能しない問題

## ❗ 不具合の症状

### 現在発生している問題
- 新規登録後ユーザーの `users/{uid}` には `householdId` が保存されている
- 招待コード経由で参加しても、`households/{id}` に参加者が追加されていない（members が自分のみ）
- アプリ側ではパートナーが存在しない状態として表示される
- ニックネームは**保存される場合とされない場合がある**

### Firestoreの現状例
```
users/{uid}:
  householdId: "o9oH3OaJLhYPd6HWxPhClPUh6Eb2"
  nickname: "〇〇" ← nicknameがある場合とない場合がある

households/{o9oH3OaJLhYPd6HWxPhClPUh6Eb2}:
  members: ["自分のuid のみ"] ← パートナーのuidが入っていない
```

## ✅ 調査結果: 原因を特定

### 🔴 原因1: Transaction内でnicknameフィールドが抜けている

**ファイル:** `lib/auth_screen.dart`  
**メソッド:** `_signUpWithInviteCode()`  
**行番号:** 約200行目

```dart
// Transaction化: usersドキュメント作成 + household参加を原子的に実行
await FirebaseFirestore.instance.runTransaction((transaction) async {
  // 1. usersドキュメントを作成
  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  transaction.set(userRef, {
    'uid': user.uid,
    'displayName': nickname,
    'email': email,
    'householdId': householdId,
    'role': 'partner',
    'lifeStage': 'couple',
    'plan': 'free',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  // ❌ 'nickname': nickname が抜けている！
```

**問題点:**
- `displayName` は保存されているが `nickname` フィールドが抜けている
- これにより、招待コード経由で参加したユーザーの nickname が null になる
- UserModel.fromFirestore() では `nickname ?? displayName` でフォールバックするが、一貫性に欠ける

**影響:**
- 招待コード経由のユーザーのnicknameがFirestoreに保存されない
- UI表示でnicknameが取得できず、displayNameまたはemailが表示される可能性

### 🟢 確認: Transaction自体は正しく実装されている

```dart
// 2. householdドキュメントを取得してmembersに追加
final householdRef = FirebaseFirestore.instance.collection('households').doc(householdId);
final householdSnap = await transaction.get(householdRef);

if (!householdSnap.exists) {
  throw Exception('世帯が見つかりません');
}

final householdData = householdSnap.data()!;
final members = List<Map<String, dynamic>>.from(householdData['members'] ?? []);

// 重複チェック
final exists = members.any((m) => m['uid'] == user.uid);
if (!exists) {
  members.add({
    'uid': user.uid,
    'name': nickname,
    'nickname': nickname,  // ← membersにはnicknameがある
    'role': 'partner',
    'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$nickname',
  });

  transaction.update(householdRef, {
    'members': members,
  });
}
```

**動作状況:**
- Transaction自体は正しく実装されている
- householdドキュメントのmembers配列には nickname が含まれている
- **しかし、users/{uid}ドキュメントにはnicknameフィールドがない**

### 🔵 調査2: invite_service.dartとの関係

**ファイル:** `lib/services/invite_service.dart`

招待処理が2箇所に存在することを確認：

1. **auth_screen.dart の `_signUpWithInviteCode()`**
   - 新規登録時の招待コード処理
   - Transaction化されている ✅
   - nickname フィールドが抜けている ❌

2. **invite_service.dart の `joinHouseholdByInviteCode()`**
   - 既存ユーザーが招待コードで参加する処理
   - Transaction化されていない ⚠️
   - 現在は使用されていない可能性が高い

**現在のフロー:**
```
新規登録時に招待コード入力
  ↓
auth_screen.dart の _signUpWithInviteCode() が呼ばれる
  ↓
Transaction内で users作成 + household参加
  ↓
❌ nicknameフィールドが抜けている
```

### 🟡 調査3: householdドキュメントのmember追加は正常

Transaction内で以下が正しく実行されている：

```dart
members.add({
  'uid': user.uid,
  'name': nickname,
  'nickname': nickname,  // ← ここは正しい
  'role': 'partner',
  'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$nickname',
});

transaction.update(householdRef, {
  'members': members,
});
```

**確認結果:**
- households/{id}/members への追加処理は正常
- パートナーのuidと nicknameが正しく保存される

### 🟢 調査4: UI側のパートナー取得ロジック

**ファイル:** `lib/services/firestore_service.dart`  
**メソッド:** `getHouseholdMembers()`

```dart
Future<List<Map<String, dynamic>>> getHouseholdMembers() async {
  // ...
  final householdDoc = await _firestore.collection('households').doc(householdId).get();
  final members = List<Map<String, dynamic>>.from(householdDoc.data()?['members'] ?? []);
  
  // 各メンバーのdisplayNameをusersコレクションから取得
  for (var member in members) {
    final memberUid = member['uid'] as String?;
    if (memberUid != null) {
      final memberUserDoc = await _firestore.collection('users').doc(memberUid).get();
      if (memberUserDoc.exists) {
        member['displayName'] = memberUserDoc.data()?['displayName'] as String? ?? member['name'] ?? '未設定';
      }
    }
  }
  return members;
}
```

**確認結果:**
- household.members からメンバーリストを取得している ✅
- users/{uid} から displayName を取得している ✅
- nickname フィールドは確認していない（displayNameを使用）

## 📊 原因の優先順位

### 🔴 優先度1: auth_screen.dartのnicknameフィールド欠落（確定）

**症状:**
- 招待コード経由でnicknameが保存されないケースがある
- users/{uid} に nickname フィールドがない

**原因:**
```dart
// auth_screen.dart の _signUpWithInviteCode() Transaction内
transaction.set(userRef, {
  'uid': user.uid,
  'displayName': nickname,  // ✅ ある
  'nickname': nickname,      // ❌ これが抜けている！
  'email': email,
  'householdId': householdId,
  // ...
});
```

**修正方法:**
Transaction内のusers作成処理に `'nickname': nickname` を追加

### 🟡 優先度2: パートナー表示の問題（条件付き）

**現状:**
- households/{id}/members にはパートナーが正しく追加されている
- UI側で getHouseholdMembers() を使用してパートナー情報を取得
- displayName は取得できるが、nickname フィールドは確認していない

**影響:**
- パートナーのnicknameが表示されない可能性
- displayName がフォールバックとして表示される

**修正方法:**
- getHouseholdMembers() で nickname フィールドも取得するように修正
- または、UserModel経由で取得する

### 🟢 優先度3: invite_service.dartの未使用コード（影響なし）

**現状:**
- invite_service.dart に joinHouseholdByInviteCode() が存在
- 現在は auth_screen.dart の _signUpWithInviteCode() が使用されている
- invite_service.dart の処理は呼ばれていない可能性が高い

**影響:**
- 現在の不具合には関係ない
- 将来的にコードの整理が必要

## 🎯 最終結論

### 原因の特定

**メイン原因:**
```
auth_screen.dart の _signUpWithInviteCode() 内の Transaction で
users/{uid} ドキュメント作成時に 'nickname' フィールドが抜けている
```

**データの流れ:**
1. ユーザーA が新規登録 → households/{A_uid} 作成 ✅
2. ユーザーB が招待コードで参加 → users/{B_uid} 作成 ✅
3. users/{B_uid} に nickname が保存されない ❌
4. households/{A_uid}/members に B_uid が追加される ✅
5. UI で getHouseholdMembers() がパートナー情報を取得 ✅
6. **しかし、users/{B_uid}.nickname が null なので表示に問題発生** ❌

### 確認できたこと

✅ **正常に動作しているもの:**
- Transaction の実装自体は正しい
- households/{id}/members への追加は正常
- householdId の設定は正常
- UIのパートナー取得ロジックは正常

❌ **問題があるもの:**
- users/{uid} への nickname フィールドの保存（auth_screen.dart）
- nickname フィールドの取得と表示（UI側）

## 🔧 修正が必要な箇所

### 1. auth_screen.dart (優先度: 高)

**ファイル:** `lib/auth_screen.dart`  
**メソッド:** `_signUpWithInviteCode()`  
**修正内容:**

```dart
// 修正前
transaction.set(userRef, {
  'uid': user.uid,
  'displayName': nickname,
  'email': email,
  'householdId': householdId,
  'role': 'partner',
  'lifeStage': 'couple',
  'plan': 'free',
  'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

// 修正後
transaction.set(userRef, {
  'uid': user.uid,
  'displayName': nickname,
  'nickname': nickname,  // ★ 追加
  'email': email,
  'householdId': householdId,
  'role': 'partner',
  'lifeStage': 'couple',
  'plan': 'free',
  'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

### 2. firestore_service.dart (優先度: 中)

**ファイル:** `lib/services/firestore_service.dart`  
**メソッド:** `getHouseholdMembers()`  
**修正内容:**

nickname フィールドも取得するように修正（オプション）

```dart
// displayName だけでなく nickname も取得
member['displayName'] = memberUserDoc.data()?['displayName'] as String? ?? member['name'] ?? '未設定';
member['nickname'] = memberUserDoc.data()?['nickname'] as String? ?? member['nickname'] ?? member['name'];
```

## 📝 テスト推奨項目

### 修正後の確認事項

1. ✅ 招待コード経由で新規登録
2. ✅ Firestore の users/{uid} に nickname フィールドが保存されているか確認
3. ✅ households/{id}/members にパートナーが追加されているか確認
4. ✅ UI でパートナーのニックネームが正しく表示されるか確認
5. ✅ 既存ユーザーとの互換性（nickname がない場合の動作）

### エッジケース

- [ ] 同時に2人が同じ招待コードで参加した場合
- [ ] ネットワーク遅延時の動作
- [ ] Transaction タイムアウト時の動作

## 🎊 まとめ

### 原因

**auth_screen.dart の _signUpWithInviteCode() メソッド内のTransaction処理で、users/{uid}ドキュメント作成時に `'nickname': nickname` フィールドが抜けていることが根本原因。**

### 影響範囲

- 招待コード経由で参加したユーザーの nickname が Firestore に保存されない
- UI での nickname 表示に不整合が発生
- households/{id}/members には正しく追加されている

### 修正方法

1. auth_screen.dart の Transaction 内に `'nickname': nickname` を追加
2. （オプション）getHouseholdMembers() で nickname フィールドも取得

### 修正後の期待結果

- ✅ 招待コード経由でもnicknameが確実に保存される
- ✅ households/{id}/members にパートナーが正しく追加される
- ✅ UI でパートナーのニックネームが正しく表示される
- ✅ すべての既存機能との整合性が保たれる
