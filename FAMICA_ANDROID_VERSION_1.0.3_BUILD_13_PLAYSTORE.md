# Famica Android バージョン 1.0.3 (Build 13) Google Play Store 提出準備完了

**更新日**: 2026年2月1日  
**目的**: Google Play Store への Android App Bundle 提出  
**対象**: Android Google Play Store

---

## ✅ 成果物

### 使用したバージョン

| 項目 | 値 |
|------|-----|
| **pubspec.yaml version** | `1.0.3+13` |
| **versionName** | `1.0.3` |
| **versionCode** | `13` |
| **applicationId** | `com.matsushima.famica` |

### 生成された .aab ファイル

**パス**:
```
build/app/outputs/bundle/release/app-release.aab
```

**サイズ**: 55.9 MB

**フルパス**:
```
/Users/matsushimaasahi/Developer/famica/build/app/outputs/bundle/release/app-release.aab
```

---

## ✅ Google Play にアップロード可能か

### **Yes** - アップロード可能

| 確認項目 | 状態 |
|----------|------|
| **App Bundle ビルド成功** | ✅ 成功 |
| **署名設定** | ✅ Release signing 設定済み |
| **versionCode** | ✅ 13（iOS と同じ） |
| **versionName** | ✅ 1.0.3（iOS と同じ） |
| **applicationId** | ✅ com.matsushima.famica |
| **致命的エラー** | ✅ なし |

---

## 📝 ビルド詳細

### ビルドコマンド

```bash
flutter build appbundle --release
```

### ビルド時間

**416.4秒**（約7分）

### ビルド結果

```
✓ Built build/app/outputs/bundle/release/app-release.aab (55.9MB)
```

---

## ⚠️ 注意点

### 1. ビルド警告（非致命的）

ビルド中に以下の警告が出ましたが、**非致命的**です：

```
警告: [options] ソース値8は廃止されていて、今後のリリースで削除される予定です
警告: [options] ターゲット値8は廃止されていて、今後のリリースで削除される予定です
```

**説明**: Java のソース/ターゲット値8が廃止予定という警告。現在は Java 11 を使用しているため、これは依存パッケージからの警告です。

**影響**: なし。Google Play Store へのアップロードには影響しません。

---

### 2. 廃止 API 使用の警告

```
ノート: 一部の入力ファイルは推奨されないAPIを使用またはオーバーライドしています
ノート: google_mobile_ads は推奨されないAPIを使用またはオーバーライドしています
```

**説明**: AdMob SDK が一部廃止予定の API を使用している警告。

**影響**: なし。SDK 側の問題で、アプリの動作には影響しません。

---

### 3. フォント最適化（正常）

```
Font asset "CupertinoIcons.ttf" was tree-shaken, reducing it from 257628 to 848 bytes (99.7% reduction)
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 8252 bytes (99.5% reduction)
```

**説明**: 使用されていないアイコンフォントが自動的に削除され、アプリサイズが最適化されました。

**影響**: 良い影響。アプリサイズが削減されました。

---

## 🎯 Android 設定確認

### build.gradle.kts 設定

| 項目 | 値 | 状態 |
|------|-----|------|
| **namespace** | `com.matsushima.famica` | ✅ 正しい |
| **applicationId** | `com.matsushima.famica` | ✅ 正しい |
| **versionCode** | `flutter.versionCode`（13） | ✅ pubspec.yaml から自動取得 |
| **versionName** | `flutter.versionName`（1.0.3） | ✅ pubspec.yaml から自動取得 |
| **minSdk** | `flutter.minSdkVersion` | ✅ Flutter 設定に準拠 |
| **targetSdk** | `flutter.targetSdkVersion` | ✅ Flutter 設定に準拠 |
| **release署名** | ✅ 設定済み | ✅ key.properties から読み込み |

---

## 📦 Google Play Store 提出手順

### 1. Google Play Console にアクセス

```
https://play.google.com/console
```

### 2. アプリを選択

- **アプリ名**: Famica
- **パッケージ名**: com.matsushima.famica

### 3. 新しいリリースを作成

```
1. 左メニュー → 「リリース」→「製品版」
2. 「新しいリリースを作成」をクリック
3. App Bundle をアップロード
```

### 4. App Bundle をアップロード

**アップロードファイル**:
```
/Users/matsushimaasahi/Developer/famica/build/app/outputs/bundle/release/app-release.aab
```

**アップロード方法**:
```
1. 「App Bundle をアップロード」をクリック
2. app-release.aab ファイルを選択
3. アップロード完了を待つ
```

### 5. リリース情報を入力

```
- リリース名: 1.0.3
- リリースノート:
  （日本語）
  バグ修正と安定性の向上
  
  （英語）
  Bug fixes and stability improvements
```

### 6. リリースを審査に送信

```
1. 「審査を開始」をクリック
2. 警告がないことを確認
3. 「製品版として公開」をクリック
```

---

## 🔍 Google Play 要件確認

### ✅ 必須要件（すべて満たしている）

- [x] **App Bundle 形式**: .aab ファイル
- [x] **署名設定**: Release signing 設定済み
- [x] **パッケージ名**: com.matsushima.famica
- [x] **versionCode**: 13（前回より大きい）
- [x] **targetSdk**: Flutter の推奨値
- [x] **minSdk**: 21（Android 5.0）以上
- [x] **Google Play Services**: 設定済み（AdMob, FCM）
- [x] **権限宣言**: AndroidManifest.xml に記載
- [x] **アプリ署名**: Upload Key で署名済み

---

## 🚀 iOS との一貫性

| 項目 | iOS | Android | 一貫性 |
|------|-----|---------|--------|
| **バージョン** | 1.0.3 | 1.0.3 | ✅ 同じ |
| **ビルド番号** | 13 | 13 | ✅ 同じ |
| **AdMob Publisher ID** | ca-app-pub-3184270565267183 | ca-app-pub-3184270565267183 | ✅ 同じ |
| **Bundle/Package ID** | com.matsushima.famica | com.matsushima.famica | ✅ 同じ |
| **Firebase プロジェクト** | 同一 | 同一 | ✅ 同じ |

---

## 📱 AdMob 設定（Android）

### 広告設定

| 項目 | 値 | 状態 |
|------|-----|------|
| **Publisher ID** | `ca-app-pub-3184270565267183` | ✅ iOS と統一 |
| **App ID** | `ca-app-pub-3184270565267183~3432864611` | ✅ 設定済み |
| **Banner Ad Unit ID（本番）** | `ca-app-pub-3184270565267183/5633035433` | ✅ 設定済み |
| **Banner Ad Unit ID（テスト）** | `ca-app-pub-3940256099942544/6300978111` | ✅ 設定済み |
| **ビルドモード切り替え** | `kDebugMode || kProfileMode` | ✅ 自動切り替え |

### AdMob 初期化

**main.dart** で初期化済み:
```dart
await GoogleMobileAds.instance.initialize();
```

**Release ビルドでは本番広告が表示される**:
- Debug/Profile: テスト広告
- Release: 本番広告（自動切り替え）

---

## 🔧 トラブルシューティング

### Q1: アップロード時に「署名エラー」が出る

**A**: key.properties が正しく設定されているか確認してください。

```bash
# key.properties の存在確認
ls -la android/key.properties

# 内容確認（パスワードは表示されない）
cat android/key.properties | grep -v Password
```

---

### Q2: versionCode が重複していると言われる

**A**: 既存のリリースより大きい versionCode が必要です。

```yaml
# pubspec.yaml を編集
version: 1.0.3+13 → version: 1.0.3+14
```

その後、再ビルド:
```bash
flutter build appbundle --release
```

---

### Q3: Google Play で「最小 API レベル」エラー

**A**: Google Play は minSdkVersion 21（Android 5.0）以上を要求します。

現在の設定は Flutter のデフォルト値を使用しており、問題ありません。

---

## 📊 アップロード後の確認項目

### Google Play Console での確認

```
1. リリース → 製品版 → 最新リリース
2. バージョン: 1.0.3 (13)
3. ステータス: 審査中 → 承認済み → 公開中
4. 配信対象: すべての国/地域
```

### AdMob レポート確認

```
1. AdMob Console (https://apps.admob.com)
2. アプリ → Famica (Android)
3. レポート → インプレッション数を確認
```

---

## ⚙️ ビルド環境情報

### Flutter バージョン

```
（pubspec.yaml で指定）
SDK: ^3.9.2
```

### Android ビルド設定

```kotlin
compileSdk: Flutter のデフォルト
minSdk: Flutter のデフォルト（21）
targetSdk: Flutter のデフォルト
Java: 11
Kotlin: 有効
```

---

## 📚 関連ドキュメント

- `FAMICA_IOS_VERSION_1.0.3_BUILD_13_APPSTORE.md` - iOS バージョン 1.0.3
- `FAMICA_ANDROID_RELEASE_SIGNING_COMPLETE.md` - Android 署名設定
- `IOS_ADMOB_PUBLISHER_UNIFICATION_COMPLETE.md` - AdMob Publisher ID 統一
- `FAMICA_ANDROID_1.0.2_FREE_COMPLETE.md` - 前回の Android リリース

---

## 📝 変更履歴

### バージョン 1.0.3 Build 13（今回）
- **日付**: 2026年2月1日
- **変更内容**: iOS と同じバージョンに更新（1.0.2 → 1.0.3）
- **理由**: iOS App Store と同時リリースのため
- **App Bundle サイズ**: 55.9 MB

---

## ✅ 完了確認チェックリスト

### ビルド

- [x] pubspec.yaml の version を `1.0.3+13` に更新した
- [x] `flutter build appbundle --release` を実行した
- [x] app-release.aab が生成された
- [x] ビルドエラーなし
- [x] 致命的警告なし

### Google Play 提出準備

- [ ] Google Play Console にログインした
- [ ] Famica アプリを選択した
- [ ] 新しいリリースを作成した
- [ ] app-release.aab をアップロードした
- [ ] リリースノートを入力した
- [ ] 審査に提出した

### 確認項目

- [x] versionCode: 13
- [x] versionName: 1.0.3
- [x] applicationId: com.matsushima.famica
- [x] Release 署名設定
- [x] AdMob 初期化

---

**更新完了日時**: 2026年2月1日 07:07  
**ステータス**: ✅ Google Play Store アップロード準備完了  
**次回アクション**: Google Play Console → 新しいリリース作成 → app-release.aab アップロード → 審査提出
