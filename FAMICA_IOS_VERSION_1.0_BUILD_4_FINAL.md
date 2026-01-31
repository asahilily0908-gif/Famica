# Famica iOS Version 1.0 (Build 4) 完全設定レポート

## 実施日時
2025年12月26日 21:42

## 目的
iOS アプリを **Version 1.0 (Build 4)** として確実にアーカイブし、App Store Connect に新しいビルドとして提出する。

---

## ✅ 実施した変更

### 1. Flutter バージョン設定
**ファイル**: `pubspec.yaml`

```yaml
version: 1.0.0+4
```

- **FLUTTER_BUILD_NAME**: 1.0.0
- **FLUTTER_BUILD_NUMBER**: 4

---

### 2. iOS Info.plist 設定
**ファイル**: `ios/Runner/Info.plist`

```xml
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>

<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
```

✅ **正しく構成済み** - ビルド変数を使用してバージョンを自動取得

---

### 3. Xcode プロジェクト設定（明示的に固定）
**ファイル**: `ios/Runner.xcodeproj/project.pbxproj`

#### すべての構成に設定：

```
MARKETING_VERSION = 1.0;
CURRENT_PROJECT_VERSION = 4;
```

**設定済み構成：**
- ✅ **Debug**: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 4`
- ✅ **Release**: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 4`
- ✅ **Profile**: `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 4`

---

## 📋 変更されたファイル一覧

### 変更されたファイル

1. **pubspec.yaml**
   - `version: 1.0.0+3` → `version: 1.0.0+4`

2. **ios/Runner.xcodeproj/project.pbxproj**
   - Debug: `CURRENT_PROJECT_VERSION = 3` → `CURRENT_PROJECT_VERSION = 4`
   - Release: `CURRENT_PROJECT_VERSION = 3` → `CURRENT_PROJECT_VERSION = 4`
   - Profile: `CURRENT_PROJECT_VERSION = 3` → `CURRENT_PROJECT_VERSION = 4`
   - ※ `MARKETING_VERSION = 1.0` はすべて維持

### 変更なしのファイル

3. **ios/Runner/Info.plist**
   - 変更なし（すでに正しく構成済み）

---

## 🔧 必須：クリーンリビルド手順

以下の順序で **必ず実行** してください：

```bash
# ステップ 1: Flutter クリーン
flutter clean
flutter pub get

# ステップ 2: iOS Pods 更新
cd ios
pod install
cd ..

# ステップ 3: Derived Data 削除（強く推奨）
rm -rf ~/Library/Developer/Xcode/DerivedData

# ステップ 4: Release ビルド
flutter build ios --release
```

### Xcode でアーカイブ

```bash
# Xcode を開く
open ios/Runner.xcworkspace
```

**Xcode 操作手順：**

1. **Product** > **Clean Build Folder** (⇧⌘K)
2. デバイスターゲットを **Any iOS Device (arm64)** に設定
3. **Product** > **Archive** を実行
4. Organizer で以下を確認：
   - ✅ **Version: 1.0**
   - ✅ **Build: 4**

---

## ✅ 期待される結果

### Archive 時の表示
```
Version: 1.0
Build: 4
```

### App Store Connect での表示
```
Version: 1.0 (4)
または
Version: 1.0.0 (4)
```

---

## 🎯 バージョン管理の仕組み

### 3層構造によるバージョン管理

```
┌─────────────────────────────────────┐
│  Layer 1: pubspec.yaml              │
│  version: 1.0.0+4                   │
│  ├─ 1.0.0 → FLUTTER_BUILD_NAME     │
│  └─ 4     → FLUTTER_BUILD_NUMBER   │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Layer 2: Info.plist                │
│  CFBundleShortVersionString =       │
│    $(FLUTTER_BUILD_NAME)            │
│  CFBundleVersion =                  │
│    $(FLUTTER_BUILD_NUMBER)          │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Layer 3: project.pbxproj           │
│  MARKETING_VERSION = 1.0            │
│  CURRENT_PROJECT_VERSION = 4        │
│  ※ 明示的設定で確実性を保証       │
└─────────────────────────────────────┘
```

### なぜ3層すべてに設定するのか？

1. **pubspec.yaml（Flutter）**
   - `flutter build` で `FLUTTER_BUILD_NAME` と `FLUTTER_BUILD_NUMBER` 生成
   - Flutter 標準の設定方法

2. **Info.plist（動的変数）**
   - ビルド時にFlutter変数を展開
   - 最終的なバイナリに埋め込まれる

3. **project.pbxproj（明示的設定）**
   - Xcode から直接 Archive する際の値
   - Flutter設定が反映されない場合のフォールバック
   - **二重設定により確実性が向上**

---

## ⚠️ 将来のバージョン更新手順

### 次回（Build 5）にする場合：

#### ステップ1: pubspec.yaml を更新
```yaml
version: 1.0.0+5
```

#### ステップ2: project.pbxproj を更新
3つの構成すべてを更新：
- Debug: `CURRENT_PROJECT_VERSION = 5;`
- Release: `CURRENT_PROJECT_VERSION = 5;`
- Profile: `CURRENT_PROJECT_VERSION = 5;`

#### ステップ3: クリーンリビルド
上記の「クリーンリビルド手順」を実行

### マイナーバージョン更新（1.1.0）の場合：

#### ステップ1: pubspec.yaml
```yaml
version: 1.1.0+6
```

#### ステップ2: project.pbxproj
- Debug: `MARKETING_VERSION = 1.1;` と `CURRENT_PROJECT_VERSION = 6;`
- Release: `MARKETING_VERSION = 1.1;` と `CURRENT_PROJECT_VERSION = 6;`
- Profile: `MARKETING_VERSION = 1.1;` と `CURRENT_PROJECT_VERSION = 6;`

---

## 🚫 バージョンリセットの原因と対策

### ❌ やってはいけないこと

1. **Xcode の General タブで Version/Build を手動変更**
   - → 手動変更は禁止（この設定が優先される）

2. **flutter clean 後、すぐに Xcode で Archive**
   - → 必ず `flutter build ios --release` を実行してから Archive

3. **pubspec.yaml だけ更新して project.pbxproj を更新しない**
   - → 両方を必ず更新する

### ✅ 正しい手順

1. **pubspec.yaml と project.pbxproj の両方を更新**
2. **クリーンリビルド手順を必ず実行**
3. **Archive 前に Organizer で Version/Build を確認**

---

## 📝 完全チェックリスト

### 設定完了確認
- [x] pubspec.yaml を `1.0.0+4` に更新
- [x] project.pbxproj の Debug 構成を `CURRENT_PROJECT_VERSION = 4` に設定
- [x] project.pbxproj の Release 構成を `CURRENT_PROJECT_VERSION = 4` に設定
- [x] project.pbxproj の Profile 構成を `CURRENT_PROJECT_VERSION = 4` に設定
- [x] Info.plist の設定を確認（Flutter変数使用を確認）

### 次のステップ（ユーザー実施）
- [ ] `flutter clean && flutter pub get` を実行
- [ ] `cd ios && pod install && cd ..` を実行
- [ ] Derived Data を削除: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- [ ] `flutter build ios --release` を実行
- [ ] Xcode を開く: `open ios/Runner.xcworkspace`
- [ ] Product > Clean Build Folder を実行
- [ ] Product > Archive を実行
- [ ] Organizer で **Version: 1.0, Build: 4** を確認 ✨
- [ ] App Store Connect へアップロード
- [ ] App Store Connect で新しいビルド 1.0 (4) を確認

---

## 📞 トラブルシューティング

### 問題: Archive 時に Build が 4 にならない

#### 解決策 1: Derived Data を完全削除
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### 解決策 2: Flutter と iOS を完全クリーン
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

#### 解決策 3: Xcode で Clean Build Folder
```
Xcode > Product > Clean Build Folder (⇧⌘K)
```

#### 解決策 4: 再度 Archive
- すべてのクリーン手順を実行後、再度 Archive

### 問題: それでも Build が 4 にならない

#### 確認: ios/Flutter/Generated.xcconfig
このファイルに以下が含まれているか確認：
```
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=4
```

この値が正しい場合、上記のクリーン手順を再実行してください。

---

## 🎯 最終確認

### Archive 成功の条件

1. **Xcode Organizer で表示される値：**
   ```
   Version: 1.0
   Build: 4
   ```

2. **App Store Connect での認識：**
   - 新しいビルドとして受け入れられる
   - Version 1.0 (4) として表示される

3. **既存ビルドとの関係：**
   - Build 1, 2, 3: 既存（または不在）
   - **Build 4: 新規ビルド（今回）** ✨

---

## 📊 バージョン履歴

| Build | Version | 状態 | 日付 |
|-------|---------|------|------|
| 1     | 1.0     | 提出済み | - |
| 2     | 1.0     | （未使用） | - |
| 3     | 1.0     | 設定済み | 2025/12/26 17:28 |
| **4** | **1.0** | **設定済み** | **2025/12/26 21:42** |

---

## 🔐 設定の安全性

### 多層防御により保証される項目

1. ✅ **pubspec.yaml**: Flutter標準の設定
2. ✅ **Info.plist**: ビルド変数による動的設定
3. ✅ **project.pbxproj**: Xcode直接設定による確実性
4. ✅ **すべての構成（Debug/Release/Profile）**: 統一された設定

### 結果

- バージョンが予期せずリセットされることはない
- Archive 時に常に正しいバージョンが表示される
- App Store Connect が新しいビルドとして認識する

---

## ✅ まとめ

### 実施内容
1. ✅ Flutter バージョン設定: `1.0.0+4`
2. ✅ Xcode プロジェクト設定: すべての構成で `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 4`
3. ✅ Info.plist: 正しく構成済み（変更不要）

### 次のアクション
1. **クリーンリビルド手順を実行**（必須）
2. **Xcode で Archive を実行**
3. **Version: 1.0, Build: 4 を確認** ✨
4. **App Store Connect へアップロード**

---

**作成日時**: 2025年12月26日 21:42  
**対象アプリ**: Famica  
**バージョン**: 1.0 (Build 4)  
**Bundle ID**: com.matsushima.famica  
**ビルドターゲット**: iOS 16.0+  
**確認ステータス**: ✅ 設定完了
