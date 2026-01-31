# 🚀 Famica Phase 4: 実機テスト & リリース準備ガイド

## 📅 作成日時
2025年10月19日 午後8:59

---

## 🎯 Phase 4 目的
FamicaをTestFlightおよびPlay Store内部テスト環境で実機検証し、
正式リリース準備を完了させる。

---

## ✅ Phase 4 完了事項

### 1. iOS設定完了
**ファイル**: `ios/Runner/Info.plist`

**追加項目**:
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>記念日や感謝の通知を受け取るために使用します</string>

<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

**説明**:
- 通知権限リクエスト時に表示されるメッセージ
- バックグラウンド通知サポート

---

## 📱 iOS TestFlight リリース手順

### Step 1: Xcode設定
```bash
# プロジェクトを開く
open ios/Runner.xcworkspace
```

**設定項目**:
1. **General**
   - Bundle Identifier: com.matsushima.famica
   - Version: 1.0.0
   - Build: 1

2. **Signing & Capabilities**
   - Team: 自分のApple Developer Team選択
   - Automatically manage signing: ON
   - Bundle Identifier確認

3. **Capabilities追加**
   - Push Notifications
   - Background Modes
     - Remote notifications
     - Background fetch

### Step 2: アーカイブ作成
```bash
# Flutterでビルド
flutter build ios --release

# Xcodeでアーカイブ
# Product > Archive
# Archive成功後、Organizer起動
```

### Step 3: App Store Connect登録
1. **App Store Connectにログイン**
   - https://appstoreconnect.apple.com

2. **マイApp**
   - 「+」ボタン → 新規App

3. **App情報**
   - 名前: Famica
   - プライマリ言語: 日本語
   - バンドルID: com.matsushima.famica
   - SKU: famica-ios-001

4. **App情報入力**
   - カテゴリ: ライフスタイル
   - サブカテゴリ: カップル / 家族
   - 価格: 無料

### Step 4: TestFlightアップロード
```bash
# Xcodeから
# Organizer > Distribute App > App Store Connect
# Upload

# または Xcodeアカウント設定から
# Xcode > Preferences > Accounts
# Apple ID追加 → チーム選択
```

### Step 5: TestFlight招待
1. **内部テスター追加**
   - App Store Connect > TestFlight
   - 内部テスト > テスター追加
   - メールアドレス入力

2. **外部テスター（任意）**
   - 外部テスト > 新規グループ
   - テスター招待（最大10,000人）

---

## 🤖 Android Play Console リリース手順

### Step 1: キーストア作成
```bash
# キーストア生成
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# パスワード設定（メモ必須）
# CN=Matsushima, OU=Famica, O=Matsushima, L=Tokyo, ST=Tokyo, C=JP
```

### Step 2: キーストア設定
**ファイル**: `android/key.properties` (作成)
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=<path-to-upload-keystore.jks>
```

**ファイル**: `android/app/build.gradle.kts` (既存)
```kotlin
// signingConfigs追加（既に設定済みの場合はスキップ）
android {
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))

            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Step 3: リリースビルド作成
```bash
# AAB（App Bundle）生成
flutter build appbundle --release

# 出力先
# build/app/outputs/bundle/release/app-release.aab
```

### Step 4: Play Console登録
1. **Play Consoleにログイン**
   - https://play.google.com/console

2. **アプリ作成**
   - 「アプリを作成」ボタン
   - アプリ名: Famica
   - デフォルトの言語: 日本語
   - アプリまたはゲーム: アプリ
   - 無料または有料: 無料

3. **ストアの設定**
   - アプリカテゴリ: ライフスタイル
   - 対象年齢: 全年齢
   - コンテンツレーティング: 完了必須

4. **内部テスト**
   - テスト > 内部テスト
   - リリース作成
   - AABアップロード
   - リリースノート入力

### Step 5: テスター招待
```bash
# 内部テストリンク
https://play.google.com/apps/internaltest/<package-name>

# テスター追加
# Play Console > 内部テスト > テスターリスト
# メールアドレス or Googleグループ追加
```

---

## 📋 App Store / Play Store 申請情報

### アプリ説明（日本語）
```
【Famica - ふたりのがんばりを10秒で記録】

カップルや夫婦のための家事・育児記録アプリ。
感謝の気持ちを伝え合い、ふたりの絆を深めましょう。

▼ 主な機能
・📝 10秒で記録: 家事・育児をワンタップで記録
・❤️ 感謝を伝える: パートナーにありがとうを送る
・📊 見える化: 月別サマリーでふたりの貢献を可視化
・💑 記念日管理: 大切な日を通知でリマインド
・🏆 達成バッジ: 継続でバッジ獲得、モチベーションアップ
・📱 SNS共有: 記念日やバッジをSNSでシェア

▼ こんな方におすすめ
・家事の分担を見える化したい
・パートナーに感謝を伝えたい
・記念日を忘れたくない
・ふたりの記録を残したい

▼ Famica Plus（プレミアムプラン）
・AI改善提案: データ分析で家事分担の改善案を提案
・7日間無料トライアル
・月額480円 / 年額4,800円

▼ プライバシー
・データはFirebase（Google Cloud）に安全に保存
・パートナー以外には公開されません
・いつでもデータ削除可能
```

### スクリーンショット（必須）
```
iPhone (6.5インチ)
1. ホーム画面（記録一覧）
2. クイック記録画面
3. 感謝送信画面
4. 月別サマリー
5. 記念日一覧

Android
1. ホーム画面（記録一覧）
2. クイック記録画面
3. 感謝送信画面
4. 月別サマリー
5. 記
