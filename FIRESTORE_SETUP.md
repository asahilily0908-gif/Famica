# 🔥 Famica Firestore初期化ガイド

このガイドでは、Famica v3.0の新しいFirestore構造を初期化する手順を説明します。

## 📋 前提条件

- Node.js (v14以上) がインストールされていること
- Firebase Consoleへのアクセス権限があること
- Firebase Admin SDK サービスアカウントキーを取得済みであること

## 🚀 初期化手順

### 1. サービスアカウントキーの取得

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクトを選択
3. 「プロジェクトの設定」→「サービスアカウント」タブを選択
4. 「新しい秘密鍵の生成」をクリック
5. ダウンロードしたJSONファイルを `scripts/serviceAccountKey.json` として保存

### 2. 依存関係のインストール

```bash
cd scripts
npm install
```

### 3. ユーザーIDの確認と更新

`scripts/init_firestore.js` の20行目を編集：

```javascript
const currentUserId = 'YOUR_ACTUAL_USER_ID'; // 実際のユーザーIDに置き換え
```

現在のユーザーIDは、Firebase ConsoleのAuthenticationセクションで確認できます。

### 4. Firestore初期化スクリプトの実行

```bash
npm run init
```

### 5. Firestoreセキュリティルールのデプロイ

#### 方法A: Firebase CLIを使用（推奨）

```bash
# プロジェクトルートディレクトリで実行
firebase deploy --only firestore:rules
```

#### 方法B: Firebase Consoleから手動デプロイ

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクトを選択
3. 「Firestore Database」→「ルール」タブを選択
4. `firestore.rules` の内容をコピー＆ペースト
5. 「公開」ボタンをクリック

### 6. 必要なインデックスの作成

以下のクエリでインデックスが必要になる場合、Firebase Consoleで自動的に作成を促されます：

- `/households/{householdId}/records` の `month` と `createdAt` の複合インデックス

## 📊 作成されるデータ構造

### `/users/{userId}`
```
{
  displayName: "松島",
  email: "asahi9131@icloud.com",
  householdId: "{userId}",
  role: "夫",
  lifeStage: "couple",
  plan: "free",
  createdAt: timestamp
}
```

### `/households/{householdId}`
```
{
  name: "松島家",
  inviteCode: "ABC123",
  lifeStage: "couple",
  members: [
    {
      uid: "{userId}",
      name: "松島",
      role: "夫",
      avatar: "https://..."
    }
  ],
  createdAt: timestamp
}
```

### `/households/{householdId}/quickTemplates/{templateId}`
8個のデフォルトテンプレート：
- 家事: 食事準備、掃除、洗濯、買い物
- 介護: 介護サポート、通院付き添い
- 育児: おむつ交換、寝かしつけ

### `/households/{householdId}/records/{recordId}`
2個のサンプル記録が作成されます。

## 🔍 動作確認

1. Flutterアプリを再起動
2. ログイン画面でログイン
3. 記録入力画面が表示されることを確認
4. Firebase Consoleで以下を確認：
   - `/users` コレクションにユーザー情報が存在
   - `/households` コレクションに世帯情報が存在
   - サブコレクションにデータが作成されている

## 🛠️ トラブルシューティング

### エラー: "Error: Could not load the default credentials"

サービスアカウントキーが正しく配置されていません。
`scripts/serviceAccountKey.json` が存在することを確認してください。

### エラー: "PERMISSION_DENIED"

Firestoreルールが正しくデプロイされていません。
手順5を再度実行してください。

### データが表示されない

1. Firebase Consoleでデータが作成されているか確認
2. ユーザーIDが正しいか確認（スクリプト内とアプリで使用しているユーザーIDが一致しているか）
3. アプリを完全に再起動

## 📝 注意事項

- このスクリプトは開発環境用です
- 本番環境では適切なバックアップを取ってから実行してください
- サービスアカウントキーは機密情報です。Gitにコミットしないでください

## 🔐 セキュリティ

`.gitignore` に以下が含まれていることを確認：
```
scripts/serviceAccountKey.json
```

## 📚 参考資料

- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Data Model](https://firebase.google.com/docs/firestore/data-model)
