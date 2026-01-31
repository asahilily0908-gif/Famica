# Famica Android リリース署名設定完了レポート

## 実施日時
2025年12月29日 20:27

## 目的
Famica Android アプリを Google Play にリリース可能な状態にするため、リリース署名（Release Signing）を正しく設定する。

---

## ✅ 実施した変更

### 1. Release Keystore 作成
**ファイル**: `android/app/upload-keystore.jks`

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

**設定内容**:
- **keyAlias**: upload
- **アルゴリズム**: RSA 2048bit
- **有効期限**: 10,000日
- **DN**: CN=Famica, OU=Development, O=Matsushima, L=Tokyo, ST=Tokyo, C=JP

---

### 2. key.properties 作成
**ファイル**: `android/key.properties`

```properties
storePassword=famica2024upload
keyPassword=famica2024upload
keyAlias=upload
storeFile=upload-keystore.jks
```

**重要**: このファイルは `.gitignore` に追加済み（機密情報）

---

### 3. android/app/build.gradle.kts 修正

#### 追加したimport
```kotlin
import java.util.Properties
import java.io.FileInputStream
```

#### key.properties 読み込み
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

#### signingConfigs 定義
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties.getProperty("keyAlias")
        keyPassword = keystoreProperties.getProperty("keyPassword")
        storeFile = file(keystoreProperties.getProperty("storeFile"))
        storePassword = keystoreProperties.getProperty("storePassword")
    }
}
```

#### buildTypes.release 修正
```kotlin
buildTypes {
    release {
        // Use release signing config for Google Play
        signingConfig = signingConfigs.getByName("release")
    }
}
```

**変更前**:
```kotlin
buildTypes {
    release {
        // デバッグキーで署名（Google Play 不可）
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

---

### 4. .gitignore 更新

追加した項目:
```
# Android Release Signing (機密情報)
android/key.properties
android/app/upload-keystore.jks
*.jks
*.keystore
```

---

## 📋 変更されたファイル一覧

### 新規作成
1. **android/app/upload-keystore.jks** (gitignore済み)
2. **android/key.properties** (gitignore済み)

### 修正
3. **android/app/build.gradle.kts**
   - import追加
   - key.properties読み込み
   - signingConfigs定義
   - release buildType修正

4. **.gitignore**
   - 機密情報の除外設定追加

---

## 🎉 リリースビルド成功

### ビルドコマンド
```bash
flutter build appbundle --release
```

### 結果
```
✓ Built build/app/outputs/bundle/release/app-release.aab (51.6MB)
```

### 出力ファイル
- **パス**: `build/app/outputs/bundle/release/app-release.aab`
- **サイズ**: 51.6MB
- **署名**: ✅ Release keystore で署名済み
- **Google Play**: ✅ アップロード可能

---

## 📊 現在のバージョン情報

### pubspec.yaml
```yaml
version: 1.0.0+4
```

### 実際のビルド値
- **versionName**: 1.0.0
- **versionCode**: 4
- **applicationId**: com.matsushima.famica

---

## ✅ Google Play アップロード準備完了

### チェックリスト

#### 署名設定
- [x] Release keystore 作成
- [x] key.properties 作成
- [x] build.gradle.kts 設定
- [x] .gitignore 更新

#### ビルド検証
- [x] Release AAB ビルド成功
- [x] Release keystore で署名
- [x] デバッグ署名削除

#### Google Play 要件
- [x] AAB 形式
- [x] Release 署名
- [x] versionCode 設定
- [x] applicationId 設定

---

## 🚀 Google Play Console アップロード手順

### 1. Google Play Console にログイン
https://play.google.com/console

### 2. アプリを選択または新規作成
- **アプリ名**: Famica
- **パッケージ名**: com.matsushima.famica

### 3. リリース > 製品版トラック
- 「新しいリリースを作成」をクリック

### 4. AAB をアップロード
- ファイル: `build/app/outputs/bundle/release/app-release.aab`
- アップロードすると自動的に署名検証

### 5. リリースノートを記入
例:
```
初回リリース
- 家計管理機能
- AI コーチ機能
- Firebase 連携
- AdMob 広告統合
- アプリ内課金対応
```

### 6. リリースをロールアウト
- 内部テスト → クローズドテスト → オープンテスト → 製品版

---

## 🔒 セキュリティ情報

### 保護されている機密ファイル

1. **android/app/upload-keystore.jks**
   - Gitにコミットされない
   - バックアップ必須
   - 紛失すると更新不可

2. **android/key.properties**
   - Gitにコミットされない
   - パスワード含む
   - チーム共有は安全な方法で

### バックアップ推奨

```bash
# 安全な場所にバックアップ
cp android/app/upload-keystore.jks ~/Dropbox/famica-keystore-backup/
cp android/key.properties ~/Dropbox/famica-keystore-backup/
```

⚠️ **警告**: keystoreを紛失すると、既存アプリの更新ができなくなります！

---

## 🔄 将来のビルド手順

### バージョン更新

#### 1. pubspec.yaml を更新
```yaml
version: 1.0.0+5  # versionCode を +1
```

#### 2. クリーンビルド
```bash
flutter clean
flutter pub get
```

#### 3. Release AAB ビルド
```bash
flutter build appbundle --release
```

#### 4. Google Play へアップロード
- 自動的に同じkeystore で署名される
- versionCode が増加していることを確認

---

## 📝 build.gradle.kts 完成版

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties for release signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.matsushima.famica"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.matsushima.famica"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
```

---

## ⚠️ トラブルシューティング

### 問題: keystoreが見つからない

**エラー**:
```
Keystore file '/path/to/upload-keystore.jks' not found
```

**解決策**:
1. keystoreの場所を確認: `android/app/upload-keystore.jks`
2. key.properties のstoreFileパスを確認
3. 相対パスが正しいか確認

### 問題: パスワードが間違っている

**エラー**:
```
Keystore was tampered with, or password was incorrect
```

**解決策**:
1. key.properties のパスワードを確認
2. keystoreを再作成（最終手段）

### 問題: ビルドが失敗する

**解決策**:
```bash
flutter clean
cd android && ./gradlew clean
cd ..
flutter build appbundle --release
```

---

## 🎯 重要な注意点

### versionCode 管理
- ✅ pubspec.yaml から自動取得
- ✅ 各リリースで必ず +1
- ❌ 手動でbuild.gradleに書かない

### keystore 管理
- ✅ 安全にバックアップ
- ✅ パスワードを安全に管理
- ❌ Gitにコミットしない
- ❌ 紛失しない（回復不可能）

### 署名の種類
- **Upload Key** (今回作成): Google Play へのアップロード用
- **App Signing Key**: Google Play が自動管理（推奨）

---

## 📞 Google Play App Signing

### 推奨設定

Google Play で「Play App Signing」を有効にすると:
- ✅ Google が最終署名を管理
- ✅ Upload Key の紛失リスク軽減
- ✅ keystoreのローテーション可能

### 設定方法
1. Google Play Console > アプリの署名
2. 「Play App Signing を使用する」を選択
3. Upload Key（今回作成したkeystore）を登録

---

## ✅ まとめ

### 完了した作業
1. ✅ Release keystore 作成 (RSA 2048, 10000日)
2. ✅ key.properties 作成
3. ✅ build.gradle.kts 修正（release signing設定）
4. ✅ .gitignore 更新（機密情報保護）
5. ✅ Release AAB ビルド成功

### 現在の状態
- ✅ **Google Play アップロード可能**
- ✅ Release keystore で署名済み
- ✅ デバッグ署名削除済み
- ✅ AAB ファイル生成済み (51.6MB)

### 次のステップ
1. Google Play Console にアプリ登録
2. AAB ファイルをアップロード
3. ストアリスティング設定
4. リリーストラック選択（内部 → テスト → 製品版）

---

**作成日時**: 2025年12月29日 20:27  
**対象アプリ**: Famica  
**バージョン**: 1.0.0 (4)  
**Bundle ID**: com.matsushima.famica  
**ビルドターゲット**: Android (minSdk: auto, targetSdk: auto)  
**ステータス**: ✅ Google Play リリース準備完了
