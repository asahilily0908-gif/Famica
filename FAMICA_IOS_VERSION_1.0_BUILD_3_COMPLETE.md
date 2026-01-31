# Famica iOS Version 1.0 (Build 3) 設定完了レポート

## 実施日時
2025年12月26日 17:28

## 目的
iOS アプリを **Version 1.0 (Build 3)** として確実にアーカイブし、App Store Connect に提出できる状態にする。

---

## ✅ 実施した変更

### 1. Flutter バージョン設定
**ファイル**: `pubspec.yaml`

```yaml
version: 1.0.0+3
```

- **CFBundleShortVersionString**: 1.0.0 → **1.0**
- **CFBundleVersion**: 1 → **3**

---

### 2. iOS Info.plist 設定（確認済み）
**ファイル**: `ios/Runner/Info.plist`

```xml
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>

<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
```

✅ **正しく構成済み** - Flutter変数を使用してバージョンを自動取得

---

### 3. Xcode プロジェクト設定（明示的に設定）
**ファイル**: `ios/Runner.xcodeproj/project.pbxproj`

#### すべての構成（Debug / Release / Profile）に追加：

```
MARKETING_VERSION = 1.0;
CURRENT_PROJECT_VERSION = 3;
```

**変更箇所：**
- ✅ Debug 構成: MARKETING_VERSION = 1.0, CURRENT_PROJECT_VERSION = 3
- ✅ Release 構成: MARKETING_VERSION = 1.0, CURRENT_PROJECT_VERSION = 3
- ✅ Profile 構成: MARKETING_VERSION = 1.0, CURRENT_PROJECT_VERSION = 3

---

## 📋 変更されたファイル一覧

1. **pubspec.yaml**
   - `version: 1.0.0+1` → `version: 1.0.0+3`

2. **ios/Runner.xcodeproj/project.pbxproj**
   - Debug: MARKETING_VERSION = 1.0, CURRENT_PROJECT_VERSION = 3 を追加
   - Release: MARKETING_VERSION = 1.0, CURRENT_PROJECT_VERSION = 3 を追加
   - Profile: MARKETING_VERSION = 1.0, CURRENT_PROJECT_VERSION = 3 を追加

3. **ios/Runner/Info.plist**
   - 変更なし（すでに正しく構成済み）

---

## 🔧 クリーンリビルド手順（必須）

以下の順序で実行してください：

```bash
# 1. Flutter クリーン
flutter clean
flutter pub get

# 2. iOS Pods 更新
cd ios
pod install
cd ..

# 3. Derived Data 削除（推奨）
rm -rf ~/Library/Developer/Xcode/DerivedData

# 4. Release ビルド
flutter build ios --release
```

### Xcode でアーカイブ

```bash
# Xcode を開く
open ios/Runner.xcworkspace
```

1. **Product** > **Clean Build Folder** (⇧⌘K)
2. デバイスターゲットを **Any iOS Device (arm64)** に設定
3. **Product** > **Archive** を実行
4. Organizer で以下を確認：
   - **Version: 1.0**
   - **Build: 3**

---

## ✅ 期待される結果

### Archive 時の表示
```
Version: 1.0
Build: 3
```

### App Store Connect での表示
```
Version: 1.0.0 (3)
または
Version: 1.0 (3)
```

---

## 🔒 バージョン管理の仕組み

### レイヤー構造

```
┌─────────────────────────────────────┐
│  pubspec.yaml                       │
│  version: 1.0.0+3                   │
│  ├─ 1.0.0 → FLUTTER_BUILD_NAME     │
│  └─ 3     → FLUTTER_BUILD_NUMBER   │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Info.plist                         │
│  CFBundleShortVersionString =       │
│    $(FLUTTER_BUILD_NAME)            │
│  CFBundleVersion =                  │
│    $(FLUTTER_BUILD_NUMBER)          │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  project.pbxproj (明示的設定)       │
│  MARKETING_VERSION = 1.0            │
│  CURRENT_PROJECT_VERSION = 3        │
│  ※ すべての構成で統一              │
└─────────────────────────────────────┘
```

### なぜ両方設定するのか？

1. **Flutter の設定**（pubspec.yaml）
   - ビルド時に `FLUTTER_BUILD_NAME` と `FLUTTER_BUILD_NUMBER` が自動生成される
   - `flutter build ios` コマンドで反映

2. **Xcode の設定**（project.pbxproj）
   - Xcode から直接 Archive する際に使用される
   - Flutter 設定が反映されない場合のフォールバック
   - **明示的に設定することで確実性が向上**

3. **Info.plist**
   - ビルド時に変数が展開される
   - 最終的なアプリバイナリに埋め込まれる

---

## ⚠️ 将来のバージョン更新手順

### 次回（Build 4）にする場合：

1. **pubspec.yaml を更新**
   ```yaml
   version: 1.0.0+4
   ```

2. **project.pbxproj を更新**
   - Debug: `CURRENT_PROJECT_VERSION = 4;`
   - Release: `CURRENT_PROJECT_VERSION = 4;`
   - Profile: `CURRENT_PROJECT_VERSION = 4;`

3. **クリーンビルド** （上記手順を実行）

### マイナーバージョン更新（1.1.0）の場合：

1. **pubspec.yaml**
   ```yaml
   version: 1.1.0+5
   ```

2. **project.pbxproj**
   - Debug: `MARKETING_VERSION = 1.1;` と `CURRENT_PROJECT_VERSION = 5;`
   - Release: `MARKETING_VERSION = 1.1;` と `CURRENT_PROJECT_VERSION = 5;`
   - Profile: `MARKETING_VERSION = 1.1;` と `CURRENT_PROJECT_VERSION = 5;`

---

## 🚫 バージョンリセットの原因と対策

### 原因となりうる操作：

1. ❌ **Xcode の General タブで Version/Build を直接編集**
   - → 手動編集は避ける

2. ❌ **flutter clean 後に iOS プロジェクトを開く前にビルド**
   - → 必ず `flutter build ios` を実行してから Xcode で Archive

3. ❌ **project.pbxproj の設定が競合**
   - → 今回の設定で明示的に固定したため解決済み

### 対策：

✅ **pubspec.yaml と project.pbxproj の両方を必ず更新する**
✅ **クリーンビルド手順を必ず実行する**
✅ **Archive 前に必ず Version/Build を確認する**

---

## 📝 チェックリスト

### 設定完了
- [x] pubspec.yaml を `1.0.0+3` に更新
- [x] project.pbxproj の Debug 構成を設定
- [x] project.pbxproj の Release 構成を設定
- [x] project.pbxproj の Profile 構成を設定
- [x] Info.plist の設定を確認（変更不要）

### 次のステップ
- [ ] `flutter clean && flutter pub get` を実行
- [ ] `cd ios && pod install` を実行
- [ ] Derived Data を削除
- [ ] `flutter build ios --release` を実行
- [ ] Xcode で Clean Build Folder
- [ ] Xcode で Archive を実行
- [ ] Organizer で **Version: 1.0, Build: 3** を確認
- [ ] App Store Connect へアップロード

---

## 🎯 最終確認

### Archive 前の確認事項

1. **Xcode Organizer で表示される値：**
   ```
   Version: 1.0
   Build: 3
   ```

2. **App Store Connect での受け入れ：**
   - 新しいビルドとして認識される
   - Version 1.0 (3) として表示される

3. **既存のビルドとの関係：**
   - Build 1: すでに提出済み（存在する場合）
   - Build 2: 存在しない or 破棄済み
   - **Build 3: 新規ビルド（今回）** ✨

---

## 📞 トラブルシューティング

### Archive 時に Version が 1.0 (3) にならない場合

1. **Derived Data を完全削除**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

2. **Flutter と iOS を完全クリーン**
   ```bash
   flutter clean
   cd ios
   rm -rf Pods
   rm -rf Podfile.lock
   rm -rf .symlinks
   pod install
   cd ..
   flutter build ios --release
   ```

3. **Xcode で Clean Build Folder**
   ```
   Product > Clean Build Folder (⇧⌘K)
   ```

4. **再度 Archive**

### それでも問題が続く場合

- `ios/Flutter/Generated.xcconfig` を確認
  - FLUTTER_BUILD_NAME=1.0.0
  - FLUTTER_BUILD_NUMBER=3
  - この値が正しければ、上記のクリーン手順を再実行

---

## ✅ まとめ

### 実施内容
1. ✅ Flutter バージョン設定: `1.0.0+3`
2. ✅ Xcode プロジェクト設定: すべての構成で `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 3`
3. ✅ Info.plist: 正しく構成済み（変更不要）

### 次のアクション
1. クリーンビルド手順を実行
2. Xcode で Archive
3. **Version: 1.0, Build: 3** を確認
4. App Store Connect へアップロード

---

**作成日時**: 2025年12月26日 17:28  
**対象アプリ**: Famica  
**バージョン**: 1.0 (Build 3)  
**Bundle ID**: com.matsushima.famica  
**ビルドターゲット**: iOS 16.0+
