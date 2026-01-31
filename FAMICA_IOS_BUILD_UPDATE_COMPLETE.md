# Famica iOS ビルドバージョン更新完了レポート

## 実施日
2025年12月26日

## 目的
ATT + AdMob 対応後のコード変更に対応し、App Store Connect に新しいビルド (1.0.0 build 2) を提出できる状態にする。

## 実施内容

### 1. ✅ Flutter バージョン設定の更新
**ファイル**: `pubspec.yaml`

```yaml
# 変更前
version: 1.0.0+1

# 変更後
version: 1.0.0+2
```

- **Short Version**: 1.0.0 (変更なし)
- **Build Number**: 1 → 2

### 2. ✅ iOS Info.plist の確認
**ファイル**: `ios/Runner/Info.plist`

以下の設定が正しく構成されていることを確認：
```xml
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>
<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
```

✅ Flutterの設定が自動的に反映される仕組みが正しく構成されている

### 3. ✅ Xcodeプロジェクトの手動バージョン設定を削除
**ファイル**: `ios/Runner.xcodeproj/project.pbxproj`

以下の手動設定を**すべて削除**しました：

#### 削除した設定（Debug / Release / Profile 全構成）
- `MARKETING_VERSION = 2` → **削除**
- `CURRENT_PROJECT_VERSION = 2` → **削除**

これにより、`pubspec.yaml` の設定がすべての構成に正しく反映されるようになりました。

## 結果

### 現在の設定状態
- **pubspec.yaml**: `version: 1.0.0+2`
- **Info.plist**: Flutter変数を使用 `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`
- **project.pbxproj**: 手動バージョン設定なし（Flutter設定が優先）

### 期待される Archive 情報
Xcode Archive 時に以下の情報が表示されます：
- **Version**: 1.0.0
- **Build**: 2

## iOS リリース手順

### ステップ 1: クリーンビルド
```bash
# プロジェクトディレクトリで実行
flutter clean
flutter pub get
```

### ステップ 2: iOS Pods 更新
```bash
cd ios
pod install
cd ..
```

### ステップ 3: Release ビルド
```bash
flutter build ios --release
```

### ステップ 4: Xcode でアーカイブ
1. Xcode でプロジェクトを開く：
   ```bash
   open ios/Runner.xcworkspace
   ```

2. 以下を確認：
   - **Product** > **Scheme** > **Runner** を選択
   - デバイスターゲットを **Any iOS Device (arm64)** に設定

3. **Product** > **Archive** を実行

4. Organizer が開いたら、作成されたアーカイブを確認：
   - **Version**: 1.0.0
   - **Build**: 2

### ステップ 5: App Store Connect へ提出
1. Organizer で **Distribute App** をクリック
2. **App Store Connect** を選択
3. **Upload** を選択
4. 署名とプロビジョニングを確認
5. **Upload** をクリック

### ステップ 6: App Store Connect で確認
1. [App Store Connect](https://appstoreconnect.apple.com) にアクセス
2. **マイApp** > **Famica** を選択
3. **TestFlight** タブまたは **App Store** タブで新しいビルド (1.0.0 (2)) が表示されることを確認

## 注意事項

### ✅ 今後のバージョン更新方法
次回以降、バージョンを更新する際は：

1. **`pubspec.yaml` のみを編集**
   ```yaml
   version: 1.0.0+3  # build number を +1
   # または
   version: 1.0.1+4  # short version と build number を更新
   ```

2. **Xcodeプロジェクトは触らない**
   - `project.pbxproj` を直接編集しない
   - Xcodeの General タブで Version/Build を設定しない

3. **Flutter の設定が自動的に反映される**

### ⚠️ 重要な確認事項
- AdMob と ATT (App Tracking Transparency) の実装は既に完了済み
- Info.plist に `NSUserTrackingUsageDescription` が設定済み
- `GADApplicationIdentifier` が設定済み
- 課金機能 (in_app_purchase) は既存の実装をそのまま使用

### 🔒 変更しない項目
以下の機能は**一切変更していません**：
- アプリのロジック・機能
- 課金 (in_app_purchase) の実装
- AdMob の実装
- ATT の実装
- Firebase の設定

## トラブルシューティング

### Archive 時にバージョンが正しく表示されない場合

1. **Clean Build Folder**
   ```
   Xcode > Product > Clean Build Folder (⇧⌘K)
   ```

2. **Derived Data を削除**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. **再度 Flutter clean**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ios --release
   ```

4. **Xcode で再度 Archive**

### バージョンが古い値で表示される場合
- `ios/Flutter/Generated.xcconfig` を確認
- このファイルは自動生成されるため、手動で編集しない
- `flutter build ios` を実行すると自動的に更新される

## 完了チェックリスト

- [x] pubspec.yaml の version を 1.0.0+2 に更新
- [x] Info.plist が Flutter 変数を使用していることを確認
- [x] Xcodeプロジェクトの手動バージョン設定を削除（Debug）
- [x] Xcodeプロジェクトの手動バージョン設定を削除（Release）
- [x] Xcodeプロジェクトの手動バージョン設定を削除（Profile）
- [x] リリース手順ドキュメントを作成

## まとめ

✅ **App Store に 1.0.0 (2) として新ビルドを提出できる準備が完了しました**

次のステップ：
1. 上記の「iOS リリース手順」に従ってビルド・アーカイブを実行
2. App Store Connect にアップロード
3. TestFlight または App Store 審査に提出

---

**作成日**: 2025年12月26日  
**対象アプリ**: Famica  
**バージョン**: 1.0.0 (Build 2)  
**Bundle ID**: com.matsushima.famica
