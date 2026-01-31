# Famica Permission-Denied 根本原因診断レポート

## 📋 実施日時
2025年11月8日 20:28

## 🎯 目的
継続して発生している`[cloud_firestore/permission-denied]`エラーの根本原因を特定する。

## 🔍 実施した調査

### 1. Firestoreアクセス箇所の特定
全てのFirestoreアクセス箇所を検索した結果：
- **households コレクション**: 複数箇所でアクセス
- **records コレクション**: サブコレクションとしてアクセス
- **gratitudeMessages コレクション**: ルートコレクションとしてアクセス
- **costs コレクション**: サブコレクションとしてアクセス

**合計83箇所のFirestoreアクセスを確認**

### 2. ログ追加箇所

#### ✅ 追加完了
1. **lib/services/invite_service.dart**
   - `getHouseholdIdByInviteCode()`: 招待コード検索
   
2. **lib/services/household_service.dart**
   - `getHouseholdInfo()`: 世帯情報取得
   
3. **lib/auth_screen.dart**
   - `_signUpWithInviteCode()`: 招待コード経由の登録

## 📊 現在のFirestoreセキュリティルール

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 🔹 usersコレクション
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 🔹 householdsコレクション
    match /households/{householdId} {
      // ✅ 認証済みユーザーなら全てのhousehold操作を許可
      allow read, write, create, update: if request.auth != null;

      // 🔹 household以下の全サブコレクション
      match /{document=**} {
        allow read, write: if request.auth != null;
      }
    }

    // 🔹 fallback（開発・申請用の保険的許可）
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🚀 テスト手順

### Step 1: アプリの再ビルド

```bash
# キャッシュクリア
flutter clean

# 依存関係の再取得
flutter pub get

# アプリの実行
flutter run
```

### Step 2: 招待コード機能のテスト

#### テストケース1: 新規ユーザー登録（招待コードなし）
1. アプリを起動
2. メールアドレスとパスワードを入力
3. 新規登録モードに切り替え
4. ニックネームとカップル名を入力
5. 登録ボタンをタップ

**確認するログ:**
```
🔧 新規登録開始
✅ Firebase Auth登録完了: uid=xxx
✅ displayName設定完了: xxx
🔧 ユーザー情報作成開始: xxx
✅ users/xxx 作成完了
✅ households/xxx 作成完了
✅ デフォルトテンプレート作成完了
```

#### テストケース2: 招待コード経由での登録
1. アプリを起動
2. メールアドレスとパスワードを入力
3. 新規登録モードに切り替え
4. ニックネームを入力
5. 「招待コードを持っています」をチェック
6. 招待コードを入力（例: ABC123）
7. 登録ボタンをタップ

**確認するログ:**
```
🔧 招待コード経由の登録開始: ABC123
🔥 招待コード検索開始: ABC123
🔥 Auth UID: 未認証
📊 検索結果件数: 1
✅ 招待コード確認: ABC123 → householdId: xxx
✅ Firebase Auth登録完了: uid=xxx
✅ displayName設定完了: xxx
✅ users/xxx 作成完了 (nickname: xxx)
✅ households/xxx/members に追加完了
```

#### テストケース3: 招待URL経由での参加
1. 招待URLをタップ
2. アプリが起動し、InviteScreenが表示される
3. 「参加する」ボタンをタップ

**確認するログ:**
```
🔥 Firestore path: households/xxx
🔥 Auth UID: yyy
📊 Document exists: true
✅ Household data retrieved successfully
=== 招待URL参加処理開始 ===
householdId: xxx
userId: yyy
✅ トランザクション内の更新処理完了
✅ household参加成功: xxx
```

### Step 3: エラー発生時の確認ポイント

もし`permission-denied`エラーが発生した場合、以下を確認：

#### 1. 認証状態の確認
```
🔥 Auth UID: [表示される値]
```
- 「未認証」と表示される場合 → 認証前にFirestoreアクセスしている
- UIDが表示される場合 → 認証は成功している

#### 2. Firestoreパスの確認  
```
🔥 Firestore path: households/xxx
```
- householdIdが正しく取得できているか
- パスが正しい形式か

#### 3. 検索結果の確認
```
📊 検索結果件数: X
```
- 0件の場合 → 招待コードが存在しない
- 1件以上の場合 → 招待コードは存在するがアクセス権限がない

#### 4. エラーの詳細
```
🔥 Firestore Error: [エラーメッセージ]
📍 Stack trace: [スタックトレース]
```

## 🔍 考えられる原因

### 1. 認証タイミングの問題
❌ **問題**: Firebase Authenticationの認証完了前にFirestoreにアクセスしている
✅ **対策**: 既に実装済み - 招待コード検索前にAuth UIDをログ出力

### 2. セキュリティルールの遅延反映
❌ **問題**: Firestoreルールのデプロイ後、反映に時間がかかる
✅ **対策**: 既にデプロイ完了（数分待機が必要）

### 3. usersコレクションの未作成
❌ **問題**: householdに参加する前にusersドキュメントが作成されていない
✅ **対策**: 既に実装済み - usersドキュメントを先に作成

### 4. トランザクションの順序問題
❓ **可能性**: トランザクション内でのFirestoreアクセスの順序
🔍 **要確認**: ログから実際の実行順序を確認

### 5. Firestore Emulatorsの使用
❓ **可能性**: 開発環境でEmulatorを使用している場合、ルールが異なる
🔍 **要確認**: `FirebaseFirestore.instance.useFirestoreEmulator()`の呼び出し有無

## 📝 次のステップ

### 1. ログ収集
上記のテストケースを実行し、**完全なログ**を収集してください。

### 2. ログの分析
以下の情報を特定：
- エラー発生箇所（どのファイルのどの関数か）
- 認証状態（Auth UIDの値）
- Firestoreパス
- エラーメッセージの詳細

### 3. 追加調査（必要に応じて）
ログから特定の問題箇所が判明した場合：
- その箇所に追加のログを挿入
- 認証状態の確認コードを追加
- タイムアウト処理の追加

## ✅ テスト完了後の報告フォーマット

```
## テスト結果

### 環境
- Flutter バージョン: [version]
- デバイス: [iOS/Android, version]
- Firestore環境: [Production/Emulator]

### テストケース1: 新規ユーザー登録
結果: [成功/失敗]
ログ:
```
[ここにログを貼り付け]
```

### テストケース2: 招待コード経由での登録  
結果: [成功/失敗]
ログ:
```
[ここにログを貼り付け]
```

### テストケース3: 招待URL経由での参加
結果: [成功/失敗]
ログ:
```
[ここにログを貼り付け]
```

### エラー詳細（発生した場合）
エラーメッセージ:
```
[エラーメッセージ全文]
```

スタックトレース:
```
[スタックトレース全文]
```
```

## 🎯 期待される結果

- ✅ 全てのテストケースでpermission-deniedが発生しない
- ✅ 招待コード検索が成功する
- ✅ householdへの参加が成功する
- ✅ ログから実行フローが確認できる

## 💡 ヒント

もしまだpermission-deniedが発生する場合、以下を確認：

1. **Firebaseコンソールでルールを確認**
   - https://console.firebase.google.com/
   - Firestore Database → ルール
   - 最新のルールが表示されているか

2. **認証状態の確認**
   - Firebase Authentication → ユーザー
   - テストユーザーが作成されているか

3. **Firestoreデータの確認**
   - Firestore Database → データ
   - householdsコレクションに該当のドキュメントが存在するか
   - inviteCodeフィールドが正しく設定されているか

4. **ネットワーク接続の確認**
   - インターネット接続が安定しているか
   - Firebaseへの接続が成功しているか
