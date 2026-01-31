# Famica Android アイコン・スプラッシュ画面更新完了レポート

## 実施日
2026年1月21日

## 対応内容

### 1. 背景
Google Playストアのクローズドテストにて、以下の指摘を受けました：
- 起動時のスプラッシュ画面がFlutterのデフォルトのまま
- アプリアイコンもデフォルト（Flutterロゴ）のまま

### 2. 実施した作業

#### 2.1 ロゴ画像の準備
- Famicaのロゴ画像（ピンクのハートと「Famica」テキスト）を `assets/images/famica_logo.png` に配置

#### 2.2 パッケージの追加
以下のパッケージを `pubspec.yaml` の `dev_dependencies` に追加：
- `flutter_launcher_icons: ^0.13.1`
- `flutter_native_splash: ^2.3.10`

#### 2.3 アイコン設定（Android専用）
```yaml
flutter_launcher_icons:
  android: true
  ios: false  # iOS側は変更しない
  image_path: "assets/images/famica_logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/famica_logo.png"
```

#### 2.4 スプラッシュ画面設定（Android専用）
```yaml
flutter_native_splash:
  android: true
  ios: false  # iOS側は変更しない
  color: "#FFFFFF"
  image: assets/images/famica_logo.png
  android_12:
    color: "#FFFFFF"
    image: assets/images/famica_logo.png
```

#### 2.5 生成コマンドの実行
```bash
# パッケージのインストール
flutter pub get

# アイコンの生成
flutter pub run flutter_launcher_icons

# スプラッシュ画面の生成
flutter pub run flutter_native_splash:create
```

#### 2.6 バージョンアップ
- バージョンコードを `1.0.1+8` から `1.0.1+9` に更新

#### 2.7 リリースビルド
```bash
flutter build appbundle --release
```

成功：`build/app/outputs/bundle/release/app-release.aab` (57.0MB)

### 3. 重要ポイント

#### iOS設定の保護
- `pubspec.yaml` の設定で **必ず `ios: false` を指定**
- iOS側のアイコンとスプラッシュ画面は既に調整済みのため、一切変更を加えていません
- これにより、iOS側のXcode設定が上書きされることを防ぎました

### 4. 生成されたAndroidリソース

#### アイコン
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`
- `android/app/src/main/res/values/colors.xml`

#### スプラッシュ画面
- `android/app/src/main/res/drawable/splash.png`
- `android/app/src/main/res/drawable-*/splash.png`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/values-v31/styles.xml`
- `android/app/src/main/res/values-night-v31/styles.xml`

### 5. 納品物

#### リリース用ファイル
- **ファイル名**: `app-release.aab`
- **場所**: `build/app/outputs/bundle/release/app-release.aab`
- **サイズ**: 57.0MB
- **バージョン**: 1.0.1 (versionCode: 9)

#### 設定変更箇所
- `pubspec.yaml`: バージョン更新、パッケージ追加、アイコン・スプラッシュ設定追加
- Android側のリソースファイル（アイコンとスプラッシュ画面）

### 6. 次のステップ

Google Play Consoleでの作業：
1. [Google Play Console](https://play.google.com/console) にアクセス
2. 「内部テスト」または「クローズドテスト」トラックを選択
3. 「新しいリリースを作成」をクリック
4. `build/app/outputs/bundle/release/app-release.aab` をアップロード
5. リリースノートに以下を記載：
   ```
   - アプリアイコンをFamicaのロゴに変更
   - スプラッシュ画面をFamicaのロゴに変更
   ```
6. 審査のために送信

### 7. 確認事項

テスターに以下を確認してもらいます：
- ✅ アプリアイコンがFamicaのロゴ（ピンクのハート）になっているか
- ✅ 起動時にFamicaのロゴが表示されるか
- ✅ その他の機能に問題がないか

### 8. pubspec.yaml の更新箇所まとめ

```yaml
# バージョン
version: 1.0.1+9  # 1.0.1+8 から更新

# dev_dependencies に追加
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.10

# Flutter Launcher Icons 設定（Android専用）
flutter_launcher_icons:
  android: true
  ios: false  # iOS側は変更しない
  image_path: "assets/images/famica_logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/famica_logo.png"

# Flutter Native Splash 設定（Android専用）
flutter_native_splash:
  android: true
  ios: false  # iOS側は変更しない
  color: "#FFFFFF"
  image: assets/images/famica_logo.png
  android_12:
    color: "#FFFFFF"
    image: assets/images/famica_logo.png
```

## 完了
Android版のアプリアイコンとスプラッシュ画面の更新が完了しました。iOS側の設定は一切変更されていません。
