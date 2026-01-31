# 🎉 Famica v3.0 移行完了ガイド

Famica v3.0への完全移行が完了しました！このドキュメントでは、実装内容の確認と次のステップを説明します。

---

## ✅ 実装完了項目

### 1. **新しいFirestore構造**
- `/users/{uid}` - ユーザー情報
- `/households/{householdId}` - 世帯情報
- `/households/{householdId}/records/{recordId}` - 記録
- `/households/{householdId}/thanks/{thanksId}` - 感謝
- `/households/{householdId}/quickTemplates/{templateId}` - テンプレート

### 2. **作成・更新されたファイル**

#### コアサービス
- ✅ `lib/services/firestore_service.dart` - Firestore操作の統一インターフェース
- ✅ `lib/constants/famica_colors.dart` - カラーパレット＆テーマ

#### 画面
- ✅ `lib/main.dart` - Famicaテーマ適用
- ✅ `lib/auth_screen.dart` - 認証画面（世帯情報自動作成対応）
- ✅ `lib/screens/record_input_screen.dart` - 記録入力画面
- ✅ `lib/screens/record_list_screen.dart` - 記録一覧画面（月次サマリー付き）

#### Firestore設定
- ✅ `firestore.rules` - セキュリティルール
- ✅ `scripts/init_firestore.js` - 初期化スクリプト
- ✅ `scripts/package.json` - Node.js依存関係
- ✅ `FIRESTORE_SETUP.md` - セットアップガイド

---

## 🎨 UI/UXの変更点

### カラーパレット
- **背景**: `#FCE8EE` (ピンクグラデーション)
- **テキスト**: `#4A154B` (ダークパープル)
- **アクセント**: `#FF6B9D` (ピンク)
- **感謝**: `#FFD700` (ゴールド)

### カテゴリーカラー
- **家事**: 緑 `#4CAF50`
- **介護**: 青 `#2196F3`
- **育児**: オレンジ `#FF9800`
- **その他**: 紫 `#9C27B0`

### UIコンポーネント
- カード角丸: 16px
- フォント: Noto Sans JP
- ボタンスタイル: Elevated with rounded corners
- スナックバー: Floating with rounded corners

---

## 📊 データ構造の変更

### 旧構造 (omoiai)
```
/records/{recordId}
  - category, type, value, unit, note, cost, role, createdAt
```

### 新構造 (Famica v3.0)
```
/users/{uid}
  - displayName, email, householdId, role, lifeStage, plan, createdAt

/households/{householdId}
  - name, inviteCode, lifeStage, members[], createdAt
  
  /records/{recordId}
    - memberId, memberName, category, task, timeMinutes, cost
    - note, month, thankedBy[], createdAt, updatedAt
  
  /thanks/{thanksId}
    - fromUid, fromName, toUid, toName, recordId
    - emoji, message, createdAt
  
  /quickTemplates/{templateId}
    - task, defaultMinutes, category, icon, order, lifeStage
```

---

## 🚀 次のステップ

### ステップ1: Firestoreの初期化

1. **Firebase Consoleでサービスアカウントキーを取得**
   ```
   Firebase Console → プロジェクトの設定 → サービスアカウント
   → 新しい秘密鍵の生成
   ```

2. **ダウンロードしたJSONファイルを配置**
   ```bash
   mv ~/Downloads/serviceAccountKey.json scripts/serviceAccountKey.json
   ```

3. **Node.js依存関係をインストール**
   ```bash
   cd scripts
   npm install
   ```

4. **初期化スクリプトを実行**
   ```bash
   npm run init
   ```

### ステップ2: Firestoreルールのデプロイ

**方法A: Firebase CLI（推奨）**
```bash
firebase deploy --only firestore:rules
```

**方法B: Firebase Console**
1. Firebase Console → Firestore Database → ルール
2. `firestore.rules` の内容をコピー＆ペースト
3. 「公開」をクリック

### ステップ3: アプリの実行とテスト

1. **アプリをクリーンビルド**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **動作確認チェックリスト**
   - [ ] ログイン画面が新デザインで表示される
   - [ ] 新規登録でusers・householdsドキュメントが作成される
   - [ ] 記録入力画面でカテゴリー・タスクが選択できる
   - [ ] 記録を追加すると成功メッセージが表示される
   - [ ] 記録一覧で月次サマリー（時間・コスト）が表示される
   - [ ] 記録一覧でカテゴリー別の色分けが確認できる

---

## 🐛 トラブルシューティング

### エラー: "householdId取得エラー"
**原因**: usersドキュメントが存在しない  
**解決**: 一度ログアウトして再ログインすると自動作成されます

### エラー: "PERMISSION_DENIED"
**原因**: Firestoreルールが正しくデプロイされていない  
**解決**: `firebase deploy --only firestore:rules` を実行

### エラー: "Missing index"
**原因**: Firestoreインデックスが未作成  
**解決**: エラーメッセージのリンクからインデックスを自動作成

### 記録が表示されない
**原因**: 
1. 記録が存在しない
2. householdIdが一致していない
3. monthフィルターが正しくない

**解決**:
1. Firebase Consoleでデータを確認
2. ログを確認: `flutter run --verbose`
3. 初期化スクリプトでサンプルデータを作成

---

## 📋 実装されていない機能（Phase 2）

以下の機能は今回のPhase 1では実装されていません：

- [ ] 感謝ダイアログ（レコードタップで感謝を送信）
- [ ] 感謝通知（FCM経由でプッシュ通知）
- [ ] 月次サマリー画面（詳細な統計・グラフ）
- [ ] オンボーディング（初回起動時の設定ウィザード）
- [ ] 家族招待機能（inviteCodeでメンバー追加）
- [ ] クイックテンプレート管理画面
- [ ] プロフィール編集画面
- [ ] 設定画面

これらの機能は必要に応じて実装してください。

---

## 📝 Firebase Consoleでの確認ポイント

### 1. Authentication
- ユーザーが正しく登録されているか確認
- メール・パスワード認証が有効になっているか確認

### 2. Firestore Database
```
✅ /users/{uid}
   - displayName, email, householdId などが存在

✅ /households/{householdId}
   - name, members, inviteCode などが存在

✅ /households/{householdId}/records
   - 記録が正しく保存されているか
   - month, memberId, timeMinutes が正しいか
```

### 3. Firestore Rules
```
ルールタブで以下を確認:
- users: 本人のみアクセス可
- households: メンバーのみアクセス可
- records: 世帯メンバーのみアクセス可
```

---

## 🎯 重要な変更点のまとめ

### 1. 認証フロー
- ログイン時に自動的に users と households ドキュメントを作成
- householdId = uid として初期化

### 2. 記録の保存先
```dart
// 旧
FirebaseFirestore.instance.collection('records').add({...})

// 新
FirebaseFirestore.instance
  .collection('households')
  .doc(householdId)
  .collection('records')
  .add({...})
```

### 3. データ取得
```dart
// 月次記録の取得
_firestoreService.getMonthlyRecords('2025-10')
  .where('month', isEqualTo: '2025-10')
  .orderBy('createdAt', descending: true)
```

### 4. テーマ適用
```dart
// main.dart
MaterialApp(
  theme: FamicaTheme.lightTheme,  // Famicaテーマを適用
  ...
)
```

---

## 🔐 セキュリティ注意事項

1. **serviceAccountKey.json は機密情報**
   - `.gitignore` に追加済み
   - 絶対にGitにコミットしない
   - 本番環境では環境変数を使用

2. **Firestoreルール**
   - 必ず本番環境にデプロイ
   - テストモードのまま運用しない

3. **APIキー**
   - `firebase_options.dart` は公開情報
   - Firestore Rulesで適切にアクセス制御

---

## 📚 参考資料

- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Firebase Integration](https://firebase.google.com/docs/flutter/setup)
- [Material 3 Design](https://m3.material.io/)

---

## 🎉 完了！

Famica v3.0への移行が完了しました！

次のコマンドでアプリを起動してテストしてください：
```bash
flutter run
```

問題が発生した場合は、このドキュメントのトラブルシューティングセクションを参照してください。
