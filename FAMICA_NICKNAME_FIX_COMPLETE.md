# Famica ニックネーム表示不具合 修正完了報告

## 📅 実施日時
2025年11月5日

## ❌ 不具合内容

### 現象
ホーム画面に表示される名前が、Firestoreのnicknameではなく、メールアドレスの@より前の文字列（例：asahi9131）になってしまう問題。

### 原因
1. **Firestore users/{uid} に nickname フィールドが保存されていなかった**
   - `FirestoreService.createOrUpdateUser()` メソッドで nickname フィールドを保存していなかった
   - displayName のみ保存されており、nickname は null のまま

2. **UserModel に nickname フィールドが定義されていなかった**
   - モデルクラスに nickname プロパティが存在しなかった
   - UI側で nickname を取得できず、フォールバックでメールアドレスが表示されていた

## ✅ 修正内容

### 1. firestore_service.dart の修正

#### createOrUpdateUser メソッドに nickname フィールドを追加

```dart
// ユーザー情報の作成または更新
Future<void> createOrUpdateUser({
  required String uid,
  required String email,
  required String displayName,
  String? householdId,
  String role = '未設定',
  String lifeStage = 'couple',
  String plan = 'free',
}) async {
  try {
    await _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'nickname': displayName, // ★ nicknameフィールドを追加
      'email': email,
      'householdId': householdId ?? uid,
      'role': role,
      'lifeStage': lifeStage,
      'plan': plan,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    print('✅ users/${uid} 保存完了: nickname=$displayName, householdId=${householdId ?? uid}');
  } catch (e) {
    print('❌ ユーザー情報作成エラー: $e');
    rethrow;
  }
}
```

**修正ポイント:**
- `'nickname': displayName` を追加
- デバッグ用のログ出力を追加

### 2. UserModel の修正

#### nickname フィールドを追加し、全メソッドに反映

```dart
/// ユーザー情報モデル
class UserModel {
  final String uid;
  final String displayName;
  final String nickname; // ★ nicknameフィールドを追加
  final String email;
  final String? householdId;
  final String role;
  final String lifeStage;
  final String plan;
  final DateTime? createdAt;
  final String? title;
  final int totalThanksReceived;

  UserModel({
    required this.uid,
    required this.displayName,
    String? nickname, // オプショナルで受け取る
    required this.email,
    this.householdId,
    this.role = '未設定',
    this.lifeStage = 'couple',
    this.plan = 'free',
    this.createdAt,
    this.title,
    this.totalThanksReceived = 0,
  }) : nickname = nickname ?? displayName; // nicknameがnullならdisplayNameを使用

  /// Firestoreドキュメントから UserModel を作成
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final displayName = data['displayName'] as String? ?? '未設定';
    final nickname = data['nickname'] as String?; // Firestoreからnicknameを取得
    
    return UserModel(
      uid: doc.id,
      displayName: displayName,
      nickname: nickname ?? displayName, // nicknameがnullならdisplayNameを使用
      email: data['email'] as String? ?? '',
      householdId: data['householdId'] as String?,
      role: data['role'] as String? ?? '未設定',
      lifeStage: data['lifeStage'] as String? ?? 'couple',
      plan: data['plan'] as String? ?? 'free',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      title: data['title'] as String?,
      totalThanksReceived: data['totalThanksReceived'] as int? ?? 0,
    );
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'nickname': nickname, // ★ nicknameを追加
      'email': email,
      'householdId': householdId,
      'role': role,
      'lifeStage': lifeStage,
      'plan': plan,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'title': title,
      'totalThanksReceived': totalThanksReceived,
    };
  }

  /// コピーを作成（一部フィールドを変更）
  UserModel copyWith({
    String? displayName,
    String? nickname, // ★ nicknameを追加
    String? email,
    String? householdId,
    String? role,
    String? lifeStage,
    String? plan,
    DateTime? createdAt,
    String? title,
    int? totalThanksReceived,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname, // ★ nicknameを追加
      email: email ?? this.email,
      householdId: householdId ?? this.householdId,
      role: role ?? this.role,
      lifeStage: lifeStage ?? this.lifeStage,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      totalThanksReceived: totalThanksReceived ?? this.totalThanksReceived,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, nickname: $nickname, householdId: $householdId, role: $role)';
  }
}
```

**修正ポイント:**
- `nickname` プロパティを追加
- コンストラクタで `nickname` を受け取り、null の場合は `displayName` をデフォルト値として使用
- `fromFirestore`、`toMap`、`copyWith`、`toString` メソッドすべてに nickname を追加

## 🎯 修正後の動作フロー

### 新規登録時
1. ユーザーがニックネームを入力（例：「あさひ」）
2. Firebase Authentication でユーザー作成
3. `createOrUpdateUser()` が呼ばれる
4. Firestore `users/{uid}` に以下が保存される：
   ```json
   {
     "uid": "abc123",
     "displayName": "あさひ",
     "nickname": "あさひ",  // ★ 確実に保存される
     "email": "asahi@example.com",
     "householdId": "abc123",
     "role": "main",
     "lifeStage": "couple",
     "plan": "free",
     "createdAt": Timestamp
   }
   ```
5. `currentUserProvider` が users/{uid} を監視
6. `UserModel.fromFirestore()` で nickname を取得
7. ホーム画面に「あさひ」と表示される ✅

### 招待コード経由での参加時
1. ユーザーがニックネームを入力（例：「りり」）
2. Firebase Authentication でユーザー作成
3. Transaction 内で `users/{uid}` に nickname が保存される
4. `currentUserProvider` が users/{uid} を監視
5. `UserModel.fromFirestore()` で nickname を取得
6. ホーム画面に「りり」と表示される ✅

### 既存ユーザーの場合
- Firestore に nickname フィールドが存在しない場合
  - `UserModel.fromFirestore()` で `nickname ?? displayName` により displayName がフォールバック値として使用される
  - メールアドレスではなく displayName が
