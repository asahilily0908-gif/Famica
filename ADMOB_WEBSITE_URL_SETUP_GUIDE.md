# AdMob デベロッパーウェブサイト URL 設定ガイド

**作成日**: 2026年2月1日  
**目的**: AdMob で app-ads.txt を認識させ、広告配信を最適化する

---

## 📋 概要

### 目的
- app-ads.txt を AdMob に認識させる
- 「No ad to show」エラーを解決
- プラットフォームの信頼性チェックを通過

### 設定する URL
```
https://asahilily0908-gif.github.io/Famica/
```

### app-ads.txt の場所
```
https://asahilily0908-gif.github.io/Famica/app-ads.txt
```

---

## 🔧 設定手順

### ステップ 1: AdMob にログイン

1. AdMob Console にアクセス: https://apps.admob.com/
2. Google アカウントでログイン
   - アカウント: `ca-app-pub-3184270565267183` に関連付けられたアカウント

---

### ステップ 2: アプリを選択

1. 左側メニューから **「アプリ」** をクリック
2. アプリ一覧から **「Famica」** を探す
   - iOS アプリと Android アプリの両方がある場合は、両方に設定が必要

---

### ステップ 3: アプリ設定を開く

1. Famica アプリをクリック
2. **「アプリの設定」** または **「App settings」** タブをクリック
   - 日本語 UI の場合: 「アプリの設定」
   - 英語 UI の場合: "App settings"

---

### ステップ 4: デベロッパーウェブサイト URL を入力

#### 探すフィールド名（UI によって異なる）:
- **日本語**: 
  - 「デベロッパーウェブサイト」
  - 「ウェブサイト URL」
  - 「アプリウェブサイト」
  
- **英語**:
  - "Developer website"
  - "Website URL"
  - "App website"

#### 入力する URL（正確にコピー）:
```
https://asahilily0908-gif.github.io/Famica/
```

**重要な注意事項**:
- ✅ 最後の `/` を含める
- ✅ `https://` を含める
- ❌ 余分なスペースを入れない
- ❌ 改行を入れない

---

### ステップ 5: 保存

1. **「保存」** または **「Save」** ボタンをクリック
2. 保存完了のメッセージを確認

---

### ステップ 6: iOS と Android 両方に設定（必要な場合）

Famica に iOS 版と Android 版がある場合：

1. iOS 版 Famica の設定
   - Bundle ID: `com.matsushima.famica`
   - 上記手順を実行

2. Android 版 Famica の設定
   - Package name: `com.matsushima.famica`
   - 上記手順を実行

---

## ✅ 確認チェックリスト

### 設定前の確認

- [ ] app-ads.txt が公開されている
  - URL: https://asahilily0908-gif.github.io/Famica/app-ads.txt
  - 内容: `google.com, pub-3184270565267183, DIRECT, f08c47fec0942fa0`

- [ ] AdMob アカウントにログインできる
  - Publisher ID: `ca-app-pub-3184270565267183`

### 設定後の確認

- [ ] iOS 版 Famica にウェブサイト URL を設定した
- [ ] Android 版 Famica にウェブサイト URL を設定した（該当する場合）
- [ ] URL が正確に入力されている（最後の `/` を含む）
- [ ] 保存が完了している

---

## 📊 反映までの時間

### Google のクロール頻度

AdMob が app-ads.txt を認識するまでの時間：

- **通常**: 数時間〜24時間
- **最大**: 48時間

### 確認方法

1. AdMob Console → アプリ → Famica
2. 「アプリの設定」セクションで以下を確認：
   - ✅ ウェブサイト URL が表示されている
   - ✅ app-ads.txt のステータスが「検出されました」または "Detected" になっている

---

## 🔍 トラブルシューティング

### ケース 1: app-ads.txt が検出されない

**確認項目**:

1. **URL が正しいか**
   ```
   正: https://asahilily0908-gif.github.io/Famica/
   誤: https://asahilily0908-gif.github.io/Famica  （最後の / がない）
   誤: http://asahilily0908-gif.github.io/Famica/  （http）
   ```

2. **app-ads.txt にアクセスできるか**
   - ブラウザで直接アクセス: https://asahilily0908-gif.github.io/Famica/app-ads.txt
   - 内容が表示されるか確認

3. **Publisher ID が一致しているか**
   - app-ads.txt の内容: `pub-3184270565267183`
   - AdMob アカウントの Publisher ID と一致しているか

4. **24時間以上経過しているか**
   - Google のクロールには時間がかかります
   - 48時間待ってから再確認

---

### ケース 2: ウェブサイト URL フィールドが見つからない

**探す場所**:

1. **アプリ詳細ページ**
   - AdMob → アプリ → Famica → アプリの設定

2. **セクション名**
   - 「アプリ情報」
   - "App information"
   - 「基本情報」
   - "Basic information"

3. **スクロールして探す**
   - ページの下部にあることもあります

---

### ケース 3: 保存できない

**考えられる原因**:

1. **URL の形式が不正**
   - `https://` で始まっているか
   - ドメインが有効か
   - 余分なスペースがないか

2. **権限がない**
   - AdMob アカウントの管理者権限があるか確認
   - 必要に応じて、アカウント所有者に依頼

---

## 📝 設定完了後のログ

設定を完了したら、以下の情報を記録してください：

### iOS アプリ
- [ ] 設定日時: ____________________
- [ ] 設定した URL: https://asahilily0908-gif.github.io/Famica/
- [ ] 保存確認: ✅
- [ ] app-ads.txt 検出日時: ____________________

### Android アプリ
- [ ] 設定日時: ____________________
- [ ] 設定した URL: https://asahilily0908-gif.github.io/Famica/
- [ ] 保存確認: ✅
- [ ] app-ads.txt 検出日時: ____________________

---

## 🎯 期待される効果

### 設定前
- ❌ 「No ad to show」エラーが頻繁に発生
- ❌ フィルレート（Fill Rate）が低い
- ❌ AdMob が app-ads.txt を検出できない

### 設定後（反映後）
- ✅ app-ads.txt が検出される
- ✅ プラットフォームの信頼性が向上
- ✅ フィルレートが改善される可能性がある
- ✅ 広告配信が最適化される

---

## 📚 関連リソース

### AdMob ヘルプ
- [app-ads.txt について](https://support.google.com/admob/answer/9363762)
- [アプリの設定を管理する](https://support.google.com/admob/answer/7356431)

### 関連ドキュメント（このプロジェクト）
- `IOS_ADMOB_ID_UPDATE_COMPLETE.md` - AdMob ID 設定完了レポート
- `app-ads.txt` - 本プロジェクトの app-ads.txt ファイル

---

## ⚠️ 重要な注意事項

### DO（すべきこと）
- ✅ 正確な URL を入力する
- ✅ iOS と Android 両方に設定する（該当する場合）
- ✅ 48時間待ってから効果を確認する
- ✅ app-ads.txt のアクセシビリティを定期的に確認する

### DON'T（してはいけないこと）
- ❌ URL を頻繁に変更しない
- ❌ 不正な URL を入力しない
- ❌ 設定後すぐに効果を期待しない（クロールに時間がかかる）
- ❌ app-ads.txt を削除しない

---

**最終更新**: 2026年2月1日  
**次回アクション**: AdMob Console で設定を実施 → 48時間後に効果を確認
