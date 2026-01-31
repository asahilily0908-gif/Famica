# Famica Universal Links完全セットアップガイド

## 概要
このガイドでは、FamicaアプリでUniversal Links（iOS）とApp Links（Android）を有効化し、招待URL（`https://famica.app/invite?hid=xxx`）からアプリを直接起動できるようにします。

---

## 前提条件

✅ すでに完了している項目：
- Flutter/Dartコードの実装
- `go_router`パッケージの追加
- Android App Links設定（AndroidManifest.xml）
- iOS設定（Runner.entitlements）
- Firebase Hosting設定（firebase.json）
- 検証ファイルの作成

---

## セットアップ手順

### ステップ1: Xcodeで Team ID を確認して置き換え

1. **Xcodeを開く**
```bash
open ios/Runner.xcodeproj
```

2. **Team IDを確認**
   - 左側のナビゲーターで「Runner」を選択
   - 「Signing & Capabilities」タブを開く
   - 「Team」フィールドに表示されているTeam IDをコピー
   - 例：`ABCDE12345` のような10文字の英数字

3. **apple-app-site-associationファイルを更新**

以下の2つのファイルを開いて、`TEAMID`を実際のTeam IDに置き換えます：

**ファイル1**: `public/apple-app-site-association`
**ファイル2**: `public/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "ABCDE12345.com.matsushima.famica",  // ← TEAMIDを置き換え
        "paths": [ "/invite/*", "/invite" ]
      }
    ]
  }
}
```

### ステップ2: Android SHA256フィンガープリントを取得して設定

1. **Debug Keystoreのフィンガープリントを取得**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

2. **SHA256フィンガープリントをコピー**
出力例：
```
Certificate fingerprints:
SHA256: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
```

3. **assetlinks.jsonを更新**

`public/.well-known/assetlinks.json`を開いて、`REPLACE_WITH_YOUR_SHA256_FINGERPRINT`を実際のSHA256に置き換えます：

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.matsushima.famica",
    "sha256_cert_fingerprints": [
      "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
    ]
  }
}]
```

**注意**: Release版をビルドする際は、Releaseキーストアのフィンガープリントも追加してください。

### ステップ3: XcodeでAssociated Domainsを追加

1. **Xcodeで設定**
   - Runner > Signing & Capabilities
   - 「+ Capability」をクリック
   - 「Associated Domains」を検索して追加
   - Domainsに以下を追加：
     ```
     applinks:famica.app
     ```

2. **Runner.entitlementsファイルを確認**
   
   `ios/Runner/Runner.entitlements`に以下が含まれていることを確認：
   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
       <string>applinks:famica.app</string>
   </array>
   ```

### ステップ4: Firebase CLIのインストール（未インストールの場合）

```bash
npm install -g firebase-tools
```

### ステップ5: Firebaseにログイン

```bash
firebase login
```

ブラウザが開いてGoogleアカウントでログインを求められます。

### ステップ6: Firebaseプロジェクトを初期化（初回のみ）

```bash
firebase init hosting
```

プロンプトで以下を選択：
- 「Use an existing project」を選択
- `famica-9b019`を選択
- Public directory: `public` （すでに設定されている）
- Single-page app: `No`
- GitHub自動デプロイ: `No`

### ステップ7: カスタムドメインの設定

1. **Firebase Consoleでカスタムドメインを追加**
   - https://console.firebase.google.com/project/famica-9b019/hosting/sites
   - 「カスタムドメインを追加」をクリック
   - `famica.app`を入力
   - DNSレコードの追加指示に従う

2. **DNSレコードの設定**
   
   ドメインレジストラ（お名前.comなど）で以下のレコードを追加：
   
   ```
   タイプ: A
   名前: @
   値: Firebase Hostingが提供するIPアドレス
   
   タイプ: TXT
   名前: @
   値: Firebase Hostingが提供する検証コード
   ```

3. **SSL証明書の発行を待つ**
   
   通常、数分～24時間で自動的にSSL証明書が発行されます。

### ステップ8: Firebase Hostingにデプロイ

```bash
firebase deploy --only hosting
```

成功すると、以下のURLが表示されます：
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/famica-9b019/overview
Hosting URL: https://famica.app
```

### ステップ9: 検証ファイルの確認

1. **iOS検証ファイル**
```bash
curl https://famica.app/.well-known/apple-app-site-association
curl https://famica.app/apple-app-site-association
```

両方のURLで同じJSONが返されることを確認。

2. **Android検証ファイル**
```bash
curl https://famica.app/.well-known/assetlinks.json
```

JSONが返されることを確認。

### ステップ10: アプリの再ビルド

```bash
cd /Users/matsushimaasahi/Developer/famica
flutter clean
flutter pub get
flutter run
```

---

## テスト方法

### iOS（シミュレータ）

```bash
xcrun simctl openurl booted "https://famica.app/invite?hid=test123"
```

✅ 期待される動作：
- Famicaアプリが起動
- InviteScreenが表示される
- householdId "test123"がパラメータとして渡される

### iOS（実機）

1. メモアプリやメッセージアプリにURLをペースト
   ```
   https://famica.app/invite?hid=test123
   ```

2. URLをタップ
3. Famicaアプリが起動することを確認

### Android

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://famica.app/invite?hid=test123"
```

---

## トラブルシューティング

### iOS: Universal Linksが動作しない

#### 1. apple-app-site-associationが正しく配信されているか確認

```bash
curl -I https://famica.app/.well-known/apple-app-site-association
```

以下を確認：
- HTTPステータスコードが`200 OK`
- `Content-Type: application/json`ヘッダーが含まれている
- HTTPSで配信されている（HTTPは不可）

#### 2. Team IDが正しいか確認

`public/apple-app-site-association`と`public/.well-known/apple-app-site-association`の両方で、`appID`が正しいか確認：
```json
"appID": "YOUR_TEAM_ID.com.matsushima.famica"
```

#### 3. Associated Domainsが設定されているか確認

Xcode > Runner > Signing & Capabilities > Associated Domainsに`applinks:famica.app`があることを確認。

#### 4. デバイスを再起動

iOSデバイスを再起動してキャッシュをクリア。

#### 5. Safariでテスト

SafariでURLを開いても動作しない場合があります。メモアプリやメッセージアプリからテストしてください。

### Android: App Linksが動作しない

#### 1. assetlinks.jsonが正しく配信されているか確認

```bash
curl -I https://famica.app/.well-known/assetlinks.json
```

#### 2. SHA256フィンガープリントが正しいか確認

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
```

出力されたSHA256が`assetlinks.json`に含まれているか確認。

#### 3. App Linksの検証

```bash
adb shell pm verify-app-links --re-verify com.matsushima.famica
adb shell pm get-app-links com.matsushima.famica
```

#### 4. パッケージ名の確認

`android/app/build.gradle.kts`で`applicationId`が`com.matsushima.famica`であることを確認。

---

## 本番リリース時の追加作業

### iOS

1. **App Store Connect設定**
   - Associated Domainsが有効化されていることを確認
   - TestFlightでテスト

2. **Release証明書でビルド**
   - Xcode > Product > Archive
   - App Store Connectにアップロード

### Android

1. **Release keystoreのSHA256を追加**

```bash
keytool -list -v -keystore /path/to/release.keystore -alias release_alias
```

出力されたSHA256を`public/.well-known/assetlinks.json`に追加：

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.matsushima.famica",
    "sha256_cert_fingerprints": [
      "DEBUG_SHA256_HERE",
      "RELEASE_SHA256_HERE"
    ]
  }
}]
```

2. **再デプロイ**

```bash
firebase deploy --only hosting
```

3. **Google Play Consoleでテスト**
   - 内部テストトラックにアップロード
   - App Linksが動作することを確認

---

## まとめ

✅ **完了チェックリスト**

- [ ] Team IDを確認してapple-app-site-associationを更新
- [ ] SHA256フィンガープリントを取得してassetlinks.jsonを更新
- [ ] XcodeでAssociated Domainsを追加
- [ ] Firebase CLIをインストール
- [ ] Firebaseにログイン
- [ ] カスタムドメイン（famica.app）を設定
- [ ] Firebase Hostingにデプロイ
- [ ] 検証ファイルがHTTPSで正しく配信されることを確認
- [ ] アプリを再ビルド
- [ ] iOS（シミュレータ/実機）でテスト
- [ ] Android（エミュレータ/実機）でテスト
- [ ] Release版のSHA256も追加（本番リリース時）

---

## 参考資料

- [Apple - Supporting Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Android - App Links](https://developer.android.com/training/app-links)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
- [go_router Deep Linking](https://pub.dev/packages/go_router#deep-linking)

---

## 次のステップ

Universal Linksが正常に動作したら：

1. 設定画面に「招待URLを生成」ボタンを追加
2. 既存の世帯データに招待URLを追加（マイグレーション）
3. 旧「6桁招待コード」UIを削除または置き換え
4. ユーザーテストを実施

詳細は`FAMICA_INVITE_URL_IMPLEMENTATION.md`を参照してください。
