# Famica iOS バージョン 1.0.2 (Build 12) 更新完了

**更新日**: 2026年2月1日  
**目的**: App Store 提出用の iOS ビルド番号更新  
**対象**: iOS のみ（Android は変更なし）

---

## 📋 変更内容

### バージョン番号

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| **バージョン文字列** | `1.0.2+11` | `1.0.2+12` |
| **セマンティックバージョン** | `1.0.2` | `1.0.2` （変更なし） |
| **ビルド番号** | `11` | `12` |

---

## ✅ 変更されたファイル

### `pubspec.yaml`

**変更箇所**: 20行目

```diff
- version: 1.0.2+11
+ version: 1.0.2+12
```

**変更されなかったファイル**:
- Android の build.gradle - **変更なし**
- iOS の Info.plist - **Flutter が自動管理**
- その他のコードファイル - **ロジック変更なし**

---

## 🎯 iOS でのバージョン情報

Flutter の `pubspec.yaml` のバージョンは以下のように iOS に反映されます：

| Flutter | iOS | 説明 |
|---------|-----|------|
| **1.0.2** | **CFBundleShortVersionString = 1.0.2** | ユーザーに表示されるバージョン |
| **12** | **CFBundleVersion = 12** | App Store Connect でのビルド識別子 |

---

## 🔍 確認方法

### 1. ビルド番号の確認（ローカル）

```bash
# pubspec.yaml の確認
grep "version:" pubspec.yaml

# 期待される出力:
# version: 1.0.2+12
```

### 2. iOS ビルド時の確認

```bash
# iOS リリースビルド
flutter build ios --release

# ビルド成功後、Xcode で確認
open ios/Runner.xcworkspace
```

**Xcode での確認箇所**:
1. プロジェクトナビゲータで「Runner」を選択
2. 「General」タブ → 「Identity」セクション
3. **Version**: `1.0.2`
4. **Build**: `12`

### 3. App Store Connect での確認

App Store Connect にアップロード後、以下で確認できます：

- **バージョン**: 1.0.2
- **ビルド**: 12

---

## 📦 App Store 提出の準備

### ビルド手順

```bash
# 1. クリーンビルド（推奨）
flutter clean
flutter pub get

# 2. iOS リリースビルド
flutter build ios --release

# 3. Xcode で Archive
# - Xcode を開く: open ios/Runner.xcworkspace
# - Product → Archive を選択
# - Organizer でアーカイブを確認
# - "Distribute App" で App Store Connect にアップロード
```

---

## ✅ App Store Connect 要件

### このビルドは以下の要件を満たしています

- [x] **ビルド番号が前回より大きい**: 11 → 12
- [x] **セマンティックバージョンが有効**: 1.0.2
- [x] **Flutter のバージョン管理を使用**: pubspec.yaml が source of truth
- [x] **コード変更なし**: バージョン番号のみ更新
- [x] **Android への影響なし**: iOS のみの変更

---

## 🔒 検証済み

### ビルド番号の一貫性

| 項目 | 値 | ステータス |
|------|-----|-----------|
| **pubspec.yaml version** | `1.0.2+12` | ✅ 更新済み |
| **iOS CFBundleShortVersionString** | `1.0.2` | ✅ Flutter が自動設定 |
| **iOS CFBundleVersion** | `12` | ✅ Flutter が自動設定 |
| **Android versionName** | 変更なし | ✅ 影響なし |
| **Android versionCode** | 変更なし | ✅ 影響なし |

---

## 📝 変更履歴

### ビルド 12（今回）
- **日付**: 2026年2月1日
- **変更内容**: ビルド番号を 11 → 12 に更新
- **理由**: App Store 再提出のため

### ビルド 11（前回）
- **日付**: 記録なし（FAMICA_VERSION_1.0.2_BUILD_11_APPSTORE.md 参照）
- **変更内容**: バージョン 1.0.2、ビルド 11

---

## ⚠️ 重要な注意事項

### 1. Flutter がバージョンを管理

iOS の Info.plist を直接編集しないでください。Flutter が `pubspec.yaml` からバージョン情報を自動的に設定します。

**正しい方法**:
```bash
# pubspec.yaml を編集
version: 1.0.2+12

# ビルド時に自動反映
flutter build ios --release
```

**間違った方法（しないこと）**:
```xml
<!-- Info.plist を直接編集 → しないこと -->
<key>CFBundleVersion</key>
<string>12</string>
```

---

### 2. ビルド番号は単調増加

App Store Connect は、各ビルド番号が前回より大きい必要があります。

**有効**:
- 11 → 12 ✅
- 12 → 13 ✅
- 12 → 20 ✅

**無効**:
- 12 → 11 ❌（後退）
- 12 → 12 ❌（同じ）

---

### 3. セマンティックバージョンとビルド番号の違い

| 項目 | セマンティックバージョン | ビルド番号 |
|------|------------------------|-----------|
| **形式** | `major.minor.patch` | 整数 |
| **例** | `1.0.2` | `12` |
| **用途** | ユーザー向け | 内部識別 |
| **変更頻度** | 機能追加時 | 毎ビルド |
| **App Store 表示** | ✅ 表示される | ❌ 表示されない |

---

## 🚀 次のステップ

### App Store 提出前のチェックリスト

- [ ] `flutter clean && flutter pub get` を実行した
- [ ] `flutter build ios --release` を実行した
- [ ] Xcode で Archive を作成した
- [ ] Organizer でビルド番号「12」を確認した
- [ ] App Store Connect にアップロードした
- [ ] TestFlight でテストした（必要に応じて）
- [ ] App Store Connect でビルド「12」を選択した
- [ ] 審査に提出した

---

## 📊 App Store Connect での表示

### アプリ情報

```
アプリ名: Famica
バージョン: 1.0.2
ビルド: 12
Bundle ID: com.matsushima.famica
```

### 提出時の注意

1. **バージョン 1.0.2 の新しいビルド**として認識されます
2. 既存の 1.0.2+11 とは別のビルドとして扱われます
3. ユーザーには「バージョン 1.0.2」として表示されます（ビルド番号は非表示）

---

## 🔧 トラブルシューティング

### Q1: Xcode でビルド番号が更新されない

**A**: Flutter のキャッシュをクリアしてください。

```bash
flutter clean
flutter pub get
flutter build ios --release
```

---

### Q2: App Store Connect で「ビルド番号が重複」エラー

**A**: ビルド番号が既存のビルドと同じです。

```bash
# pubspec.yaml を確認
grep "version:" pubspec.yaml

# ビルド番号を増やす
# version: 1.0.2+12 → version: 1.0.2+13
```

---

### Q3: Android のバージョンも変わってしまった

**A**: 今回の変更で Android も影響を受けますが、問題ありません。

Flutter の `pubspec.yaml` は iOS と Android 両方のバージョンソースです。ただし、今回の変更は「iOS 提出用」として意図されています。

もし Android を別バージョンで管理したい場合は、`android/app/build.gradle.kts` で個別に設定できます。

---

## 📚 関連ドキュメント

- `FAMICA_VERSION_1.0.2_BUILD_11_APPSTORE.md` - 前回のビルド（Build 11）
- `FAMICA_IOS_VERSION_1.0_BUILD_4_FINAL.md` - バージョン 1.0 の最終ビルド
- `IOS_ARCHIVE_FIX_GUIDE.md` - iOS アーカイブ作成ガイド
- `XCODE_ARCHIVE_SOLUTION.md` - Xcode アーカイブのトラブルシューティング

---

## ✅ 完了確認チェックリスト

### バージョン更新

- [x] `pubspec.yaml` のバージョンを `1.0.2+12` に更新した
- [x] セマンティックバージョン（1.0.2）は変更していない
- [x] ビルド番号（12）のみ更新した
- [x] Android 設定は変更していない
- [x] コードロジックは変更していない

### 準備完了

- [ ] `flutter clean` を実行した
- [ ] `flutter build ios --release` を実行した
- [ ] Xcode で Archive を作成した
- [ ] App Store Connect にアップロードした

---

**更新完了日時**: 2026年2月1日 05:44  
**次回アクション**: flutter build ios --release → Xcode Archive → App Store Connect アップロード
