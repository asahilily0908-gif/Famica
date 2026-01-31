# Famica 招待URL機能実装完了レポート

## 実装日
2025年11月7日

## 概要
Firebase Dynamic Links廃止に伴い、App Links（Android）/ Universal Links（iOS）を使用した招待URL機能を実装しました。

---

## 実装内容

### 1. 追加されたファイル

#### 新規作成
- `lib/services/household_service.dart` - 招待URL生成・管理サービス
- `lib/screens/invite_screen.dart` - 招待URL受け取り画面
- `lib/router.dart` - ディープリンクルーティング設定
- `ios/Runner/Runner.entitlements` - iOS Universal Links設定

#### 修正
- `pubspec.yaml` - go_routerパッケージ追加（v14.6.2）
- `lib/main.dart` - MaterialApp.routerへ変更、ルーティング統合
- `lib/services/invite_service.dart` - joinHouseholdByIdメソッド追加
- `android/app/src/main/AndroidManifest.xml` - App Links intent-filter追加
- `ios/Runner/Info.plist` - 確認（変更不要）

### 2. 招待URL形式
```
https://famica.app/invite?hid={householdId}
```

### 3. Firestoreデータ構造の拡張
```javascript
households/{householdId} {
  ...既存フィールド,
  inviteLink: "https://famica.app/invite?hid=xxx",  // 追加
  inviteLinkUpdatedAt: Timestamp                     // 追加
}
```

---

## 技術仕様

### App Links（Android）設定
**ファイル**: `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data 
        android:scheme="https"
        android:host="famica.app"
        android:pathPrefix="/invite"/>
</intent-filter>
```

### Universal Links（iOS）設定
**ファイル**: `ios/Runner/Runner.entitlements`

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:famica.app</string>
</array>
```

### ルーティング設定
**ファイル**: `lib/router.dart`

- go_routerを使用したディープリンク対応ルーティング
- 認証状態に応じた自動リダイレクト
- `/invite?hid={householdId}`パラメータ解析

---

## 使用方法

### 1. 招待URLの生成

```dart
import 'package:famica/services/household_service.dart';

final service = HouseholdService();

// 招待URLを生成してFirestoreに保存
final inviteUrl = await service.generateInviteLink(householdId);
// 結果: https://famica.app/invite?hid=xxx
```

### 2. 招待URLの共有

生成された招待URLをLINE、メール、その他のメッセージアプリで共有します。

### 3. 招待URLからの参加

1. 受信者が招待URLをタップ
2. アプリが起動（未インストールの場合はApp Store/Play Storeへ）
3. `InviteScreen`が表示され、世帯情報を確認
4. 「参加する」ボタンをタップ
5. 自動的に世帯のメンバーとして登録

---

## 必要な追加設定

### 1. ドメイン検証ファイルの配置

#### Android (.well-known/assetlinks.json)
`https://famica.app/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.matsushima.famica",
    "sha256_cert_fingerprints": [
      "YOUR_SHA256_CERT_FINGERPRINT"
    ]
  }
}]
```

**SHA256フィンガープリントの取得方法**:
```bash
# Release keystore
keytool -list -v -keystore <your-release-keystore> -alias <your-key-alias>

# Debug keystore（開発用）
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
# パスワード: android
```

#### iOS (.well-known/apple-app-site-association)
`https://famica.app/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.matsushima.famica",
      "paths": ["/invite", "/invite/*"]
    }]
  }
}
```

**注意**: 
- TEAM_IDはApple Developer Accountのチームです
- ファイルは拡張子なし、Content-Type: application/jsonで配信

### 2. Xcodeプロジェクト設定（iOS）

1. Xcodeで`ios/Runner.xcodeproj`を開く
2. Runner > Signing & Capabilities
3. 「+ Capability」をクリック
4. 「Associated Domains」を追加
5. `applinks:famica.app`を追加

**または**、既に`Runner.entitlements`に設定済みです。

### 3. DNS設定の確認

- `famica.app`ドメインで`.well-known`ディレクトリにアクセス可能であることを確認
- HTTPSが必須（HTTPでは動作しません）

---

## テスト方法

### Android

#### 開発環境でのテスト
```bash
# App Linksの検証
adb shell pm verify-app-links --re-verify com.matsushima.famica

# App Links状態の確認
adb shell pm get-app-links com.matsushima.famica

# 手動でディープリンクをテスト
adb shell am start -a android.intent.action.VIEW \
  -d "https://famica.app/invite?hid=test123"
```

#### ブラウザからのテスト
1. Androidデバイスでブラウザを開く
2. `https://famica.app/invite?hid=test123`にアクセス
3. アプリが起動することを確認

### iOS

#### シミュレータでのテスト
```bash
# Safariから招待URLを開く
xcrun simctl openurl booted "https://famica.app/invite?hid=test123"
```

#### 実機でのテスト
1. メモアプリやメッセージアプリに招待URLをペースト
2. URLをタップ
3. アプリが起動することを確認

**注意**: 
- 実機テストにはアプリがApp Storeで公開されている必要があります
- TestFlightでのテストも可能ですが、Associated Domainsの設定が必要です

---

## 既存機能との互換性

### 招待コード方式は維持
- 6桁の招待コード方式は引き続き使用可能
- 招待URLと招待コードの両方をサポート
- 既存のユーザーは影響を受けません

### 設定画面の更新（推奨）
`lib/screens/settings_screen.dart`または`lib/screens/family_invite_screen.dart`に以下を追加：

```dart
// 招待URL生成ボタン
ElevatedButton.icon(
  icon: Icon(Icons.link),
  label: Text('招待URLを生成'),
  onPressed: () async {
    final service = HouseholdService();
    final url = await service.generateInviteLink(householdId);
    
    // URLをクリップボードにコピー
    await Clipboard.setData(ClipboardData(text: url));
    
    // 共有ダイアログを表示
    Share.share(url, subject: 'Famicaに参加しよう！');
  },
)
```

---

## マイグレーション

既存の世帯に招待URLフィールドを追加：

```dart
final service = HouseholdService();
await service.migrateExistingHouseholds();
```

または、Firebaseコンソールで手動実行：
```javascript
// Cloud Firestoreコンソール > データ > households
// 各ドキュメントに以下のフィールドを追加
inviteLink: "https://famica.app/invite?hid={householdId}"
inviteLinkUpdatedAt: <現在のタイムスタンプ>
```

---

## トラブルシューティング

### Android App Linksが動作しない

1. **assetlinks.jsonの検証**
```bash
# ファイルがアクセス可能か確認
curl https://famica.app/.well-known/assetlinks.json
```

2. **SHA256フィンガープリントの確認**
   - Release/Debug keystoreのフィンガープリントが正しいか確認
   - 複数のkeystoreを使用している場合は全て追加

3. **App Linksの再検証**
```bash
adb shell pm verify-app-links --re-verify com.matsushima.famica
```

### iOS Universal Linksが動作しない

1. **apple-app-site-associationの検証**
```bash
# ファイルがアクセス可能か確認
curl https://famica.app/.well-known/apple-app-site-association
```

2. **Team IDの確認**
   - Xcode > Runner > Signing & Capabilities
   - Team IDが正しいか確認

3. **Associated Domainsの確認**
   - `applinks:famica.app`が正しく設定されているか確認

4. **デバイスの再起動**
   - iOS端末を再起動してキャッシュをクリア

### ディープリンクが認識されない

1. **パッケージの確認**
```bash
flutter pub get
```

2. **ビルドの再実行**
```bash
flutter clean
flutter pub get
flutter run
```

---

## セキュリティ考慮事項

### Firestoreセキュリティルール
現在のルールは招待URL機能に対応済み：

- ✅ 認証済みユーザーは全ての世帯情報を読み取り可能（招待URL検証のため）
- ✅ 自分をメンバーに追加する操作は許可（`isSelfJoining()`）
- ✅ 世帯の作成は認証済みユーザーのみ
- ✅ 既存メンバーのみが世帯情報を更新可能

### 推奨事項
- 招待URLの有効期限を設ける（将来の拡張）
- 招待URLの使用回数制限（将来の拡張）
- スパム対策として、同一ユーザーによる複数世帯への参加を制限

---

## 今後の拡張案

1. **招待URL有効期限**
   - `inviteLinkExpiresAt`フィールドを追加
   - 期限切れURLは無効化

2. **招待URL使用回数制限**
   - 使用回数カウンターを追加
   - 一度のみ使用可能なURLを生成

3. **招待メッセージのカスタマイズ**
   - 招待者の名前やメッセージを含める
   - OGPタグでリッチプレビュー

4. **QRコード生成**
   - 招待URLからQRコードを生成
   - 対面での招待を容易に

---

## まとめ

✅ App Links / Universal Links実装完了  
✅ go_routerによるディープリンク対応  
✅ 招待URL生成・管理サービス追加  
✅ Firestoreセキュリティルール対応済み  
⚠️ ドメイン検証ファイルの配置が必要  
⚠️ App Store / Play Storeへの公開が必要  

招待URL機能は実装完了しましたが、本番環境で動作させるには以下が必要です：

1. `famica.app`ドメインに検証ファイルを配置
2. アプリをApp Store / Play Storeで公開
3. 既存世帯データのマイグレーション実行

---

## 参考リンク

- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [go_router Deep Linking](https://pub.dev/packages/go_router#deep-linking)
- [Flutter Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)
