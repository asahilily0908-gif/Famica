# Xcode Archive 完全解決ガイド

## 問題の根本原因

### 1. Dynamic vs Static Linkage
**問題:**
- `use_frameworks!` のデフォルトは **Dynamic Frameworks**
- Xcode Archiveでは **Module stability** が厳しくチェックされる
- share_plus等のプラグインがDouble-quoted includeを使用
- Archiveビルド時にモジュール境界でエラー発生

**解決:**
```ruby
use_frameworks! :linkage => :static
```
Static linkageに変更することで：
- すべてのFrameworkが静的リンク
- Module境界の問題が解消
- Archive時の安定性向上

---

### 2. Firebase + gRPC + BoringSSL の競合
**問題:**
- Firebaseが内部でgRPC-C++を使用
- BoringSSLとの依存関係が複雑
- Dynamic frameworksでは衝突しやすい

**解決:**
- Static linkageで依存関係を単純化
- `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` でモジュール互換性確保

---

### 3. share_plus のヘッダー問題
**問題:**
```
error: double-quoted include "FPPSharePlusPlugin.h" in framework header
'Flutter/Flutter.h' file not found
```

**根本原因:**
- share_plusのヘッダーファイルがFramework内部でDouble-quoted includeを使用
- XcodeのArchiveビルドは **Framework header validation** が厳格
- Modular headersとの互換性問題

**解決:**
```ruby
config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
config.build_settings['DEFINES_MODULE'] = 'YES'
config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
```

---

## 修正後のPodfile（完全版）

```ruby
platform :ios, '16.0'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist"
  end
  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  # ⭐ CRITICAL: Static linkage for Archive compatibility
  use_frameworks! :linkage => :static
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # ⭐ Archive build fixes
    target.build_configurations.each do |config|
      # Bitcode無効化（Xcode 14+で非推奨）
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Module定義を有効化
      config.build_settings['DEFINES_MODULE'] = 'YES'
      
      # Non-modular includesを許可（share_plus対策）
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
      
      # ライブラリ配布用ビルド（互換性向上）
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      
      # iOS最小バージョンの統一
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
```

---

## 実行手順（コマンド一覧）

### STEP 1: 完全クリーン

```bash
cd /Users/matsushimaasahi/Developer/famica

# Flutter clean
flutter clean

# iOS artifacts削除
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ios/Flutter/Flutter.framework ios/Flutter/Flutter.podspec

# Xcode DerivedData削除
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# CocoaPods cache削除
pod cache clean --all
```

### STEP 2: 再インストール

```bash
# Flutter dependencies
flutter pub get

# CocoaPods
cd ios
pod install --repo-update
cd ..
```

### STEP 3: テストビルド

```bash
# Release buildをテスト（code sign無し）
flutter build ios --release --no-codesign
```

**期待結果:** エラーなく完了

### STEP 4: Xcode Archive

```bash
# Workspaceを開く（必須）
open ios/Runner.xcworkspace
```

**Xcodeで:**
1. Target: "Any iOS Device (arm64)" を選択
2. Menu: Product → Clean Build Folder (⌘⇧K)
3. Menu: Product → Archive
4. 完了を待つ（5-10分）

---

## よくあるエラーと対処法

### エラー1: "Semantic Issue" でFlutter.h not found

**原因:** `.xcodeproj`を開いている  
**解決:** 必ず`.xcworkspace`を開く

```bash
open ios/Runner.xcworkspace  # ✅ 正しい
open ios/Runner.xcodeproj    # ❌ 間違い
```

---

### エラー2: share_plus のdouble-quoted include

**原因:** Dynamic frameworks使用  
**解決:** Podfileで`use_frameworks! :linkage => :static`確認

---

### エラー3: Module 'share_plus' not found

**原因:** DerivedData破損  
**解決:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
# Xcodeを再起動
# Product → Clean Build Folder
# 再度Archive
```

---

### エラー4: Code signing required

**原因:** 証明書未設定  
**解決:**
1. Xcode → Runner target → Signing & Capabilities
2. Team: Apple Developer Teamを選択
3. Signing Certificate: "Apple Distribution"を選択

---

## Archive成功後の手順

### 1. Organizer確認

Archive完了後、自動的に **Xcode Organizer** が開きます。

### 2. App Store Connect へアップロード

1. Organizerで最新のArchiveを選択
2. "Distribute App"ボタンをクリック
3. "App Store Connect"を選択
4. "Upload"を選択
5. Automatic signingを選択
6. "Upload"ボタンをクリック

### 3. 処理待ち

- アップロード: 5-10分
- Processing: 10-30分
- App Store Connectで確認可能になるまで待機

---

## 技術的な詳細

### Static vs Dynamic Linkage

| 項目 | Dynamic | Static (推奨) |
|------|---------|---------------|
| リンク | 実行時 | コンパイル時 |
| サイズ | 小 | 大 |
| 安定性 | 低 | 高 |
| Archive | 失敗しやすい | 成功しやすい |
| share_plus | ❌ エラー | ✅ 動作 |

### Build Settings 詳細

```ruby
# Bitcode無効化
'ENABLE_BITCODE' = 'NO'
# → Xcode 14+で非推奨、Archiveの互換性向上

# Module定義
'DEFINES_MODULE' = 'YES'
# → Framework自体がModuleとして認識される

# Non-modular includes許可
'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' = 'YES'
# → share_plusのdouble-quoted includeを許可

# Distribution build
'BUILD_LIBRARY_FOR_DISTRIBUTION' = 'YES'
# → Module stabilityを確保、異なるSwiftバージョン間の互換性

# Deployment target統一
'IPHONEOS_DEPLOYMENT_TARGET' = '16.0'
# → すべてのPodで統一、Warning回避
```

---

## チェックリスト

Archive前の確認：

- [ ] Podfileで`use_frameworks! :linkage => :static`設定済み
- [ ] `post_install`で5つのbuild_settings設定済み
- [ ] `flutter clean`実行済み
- [ ] `pod install`実行済み
- [ ] `flutter build ios --release --no-codesign`成功
- [ ] `Runner.xcworkspace`を開いている（.xcodeprojではない）
- [ ] Xcodeで"Any iOS Device (arm64)"を選択
- [ ] Signing & Capabilitiesでチーム設定済み

Archive成功確認：

- [ ] Xcode OrganizerにArchiveが表示される
- [ ] "Distribute App"ボタンが有効
- [ ] App Store Connectへのアップロードが完了
- [ ] App Store Connectで"Processing"状態を確認

---

## トラブルシューティング最終手段

すべて失敗する場合：

```bash
# 完全削除
cd /Users/matsushimaasahi/Developer/famica
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/CocoaPods

# Flutter再セットアップ
flutter clean
flutter pub get

# CocoaPods完全再インストール
cd ios
pod deintegrate
pod setup
pod install --repo-update
cd ..

# テストビルド
flutter build ios --release --no-codesign

# Xcode完全再起動
killall Xcode
open ios/Runner.xcworkspace
```

---

## 成功の確認方法

1. **Xcodeで Archive完了**
   - エラーなく完了
   - Organizerに表示される

2. **App Store Connectアップロード成功**
   - "Upload Successful"メッセージ
   - Organizerの履歴に記録

3. **App Store Connectで確認**
   - 10-30分後にビルドが表示
   - TestFlightで配信可能

---

## まとめ

**最重要ポイント:**
1. `use_frameworks! :linkage => :static` でStatic linkageに変更
2. `post_install`で5つのbuild_settings追加
3. 必ず`.xcworkspace`を開く
4. 完全クリーン → 再インストールを実行

**これらを実施すればXcode Archiveは必ず成功します。**
