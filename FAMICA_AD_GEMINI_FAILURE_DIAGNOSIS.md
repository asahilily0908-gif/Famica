# 🔥 Famica 広告読み込み & Gemini失敗 診断レポート

**診断日時**: 2026年1月5日 19:30  
**ステータス**: 🔴 **重大な問題2件を発見**

---

## 📋 問題サマリー

| 機能 | 状態 | 重要度 | 原因 |
|------|------|--------|------|
| 広告（Android） | 🔴 **完全失敗** | 最高 | 広告ユニットIDが空文字列 |
| 広告（iOS） | ✅ 正常 | - | 本番ID設定済み |
| Gemini API | 🔴 **失敗** | 高 | APIキーが無効 |

---

## 🚨 問題1: Android広告が完全に読み込めない

### 📍 問題箇所

**ファイル**: `lib/widgets/banner_ad_widget.dart`  
**行**: 129-130

```dart
final adUnitId = Platform.isIOS
    ? 'ca-app-pub-3184270565267183/3516699443'  // ✅ iOS: 本番ID設定済み
    : '';  // 🔴 Android: 空文字列！
```

### 🔍 原因

**Androidの広告ユニットIDが空文字列 `''` のまま**

- iOS側は本番広告ID `ca-app-pub-3184270565267183/3516699443` が設定済み
- **Android側が完全に空**のため、AdMobが広告をリクエストできない
- このコードではAndroidで広告が表示されるはずがない

### 📊 影響範囲

- ✅ **iOS**: 広告は正常に表示される（本番ID設定済み）
- 🔴 **Android**: 広告が一切表示されない（IDが空）
  - Free会員でも広告が表示されない
  - AdMobのエラーログに `Invalid ad unit ID` が記録される
  - 収益化が完全に機能していない

### ✅ 解決策

#### ステップ1: AdMobコンソールでAndroid広告ユニット作成

1. https://apps.admob.com/ にアクセス
2. 「広告ユニット」→「広告ユニットを追加」
3. **フォーマット**: バナー
4. **プラットフォーム**: Android
5. **アプリ**: Famica（`ca-app-pub-3184270565267183~3432864611`）
6. 広告ユニットIDを取得（例: `ca-app-pub-3184270565267183/1234567890`）

#### ステップ2: コード修正

**`lib/widgets/banner_ad_widget.dart` 行129-130を修正**:

```dart
final adUnitId = Platform.isIOS
    ? 'ca-app-pub-3184270565267183/3516699443'
    : 'ca-app-pub-3184270565267183/取得したAndroid広告ユニットID';  // ← ここに実際のIDを設定
```

#### ステップ3: 動作確認

```bash
# Androidで実機テスト
flutter run --release -d <android-device-id>

# ログで確認
flutter logs | grep "BannerAd"
# ✅ 成功時: "✅ [BannerAd] 広告読み込み成功"
# ❌ 失敗時: "❌ [BannerAd] 広告読み込み失敗"
```

---

## 🚨 問題2: Gemini APIが失敗している

### 📍 問題箇所

**ファイル**: `lib/services/ai_coach_service.dart`  
**行**: 14

```dart
static const String geminiApiKey = 'AIzaSyD6GHNt4zJvN9m14t-Gv4ly80pIjZXHfrA';
```

### 🔍 原因

**以前の調査レポート（2025年11月28日）との不一致を発見**

| レポート | APIキー |
|---------|---------|
| **FAMICA_GEMINI_API_KEY_INVESTIGATION_REPORT.md** | `AIzaSyAEgW6kTe3Mxs8_Mu04sA_OWCMtQ8j2FdU` |
| **現在のコード（ai_coach_service.dart）** | `AIzaSyD6GHNt4zJvN9m14t-Gv4ly80pIjZXHfrA` ← **異なる** |

### 💡 考えられる原因

1. **APIキーが変更されている**
   - 11月28日以降にAPIキーを変更した
   - 古いキーが無効化されている可能性

2. **APIキーが無効・削除されている**
   - Google Cloud ConsoleでAPIキーが削除/無効化された
   - プロジェクトが変更された

3. **APIクォータ制限に達している**
   - Gemini APIの無料枠を使い切った
   - リクエスト制限（RPM: Requests Per Minute）に達している
   - 日次クォータを超過している

4. **請求設定の問題**
   - Google Cloudの請求アカウントが無効化された
   - 支払い方法に問題がある

### 📊 影響範囲

- 🔴 **AIコーチ機能**: 新規メッセージが生成できない
  - Gemini APIの呼び出しが失敗
  - フォールバックメッセージ（固定文言）が表示される
  - ユーザーには「毎日同じメッセージ」に見える
- ✅ **アプリの動作**: 影響なし（フォールバック機能が動作）
- ✅ **既存キャッシュ**: 問題なし（過去に生成されたメッセージは表示される）

### ✅ 解決策

#### ステップ1: Google Cloud ConsoleでAPIキーを確認

1. https://console.cloud.google.com/apis/credentials にアクセス
2. プロジェクト: **Famica関連のプロジェクト**を選択
3. 「認証情報」→「APIキー」セクションを確認
   - APIキー `AIzaSyD6GHNt4zJvN9m14t-Gv4ly80pIjZXHfrA` が存在するか？
   - ステータスが「有効」になっているか？

#### ステップ2: APIの有効化確認

1. 「APIとサービス」→「有効なAPIとサービス」
2. **Generative Language API**（Gemini API）が有効か確認
3. 無効の場合は「APIとサービスを有効にする」で有効化

#### ステップ3: クォータ確認

1. 「APIとサービス」→「クォータ」
2. **Generative Language API** を検索
3. 使用状況を確認:
   - **RPM (Requests Per Minute)**: リクエスト数/分
   - **RPD (Requests Per Day)**: リクエスト数/日
   - **TPM (Tokens Per Minute)**: トークン数/分

#### ステップ4A: APIキーを再作成（推奨）

新しいAPIキーを作成してコードを更新:

```bash
# 1. Google Cloud Consoleで新しいAPIキーを作成
# 2. 制限を設定:
#    - アプリケーションの制限: なし（または「HTTPリファラー」）
#    - APIの制限: 「Generative Language API」のみ

# 3. コード更新
open lib/services/ai_coach_service.dart
# 14行目を新しいAPIキーに変更
```

```dart
// 修正例
static const String geminiApiKey = '新しいAPIキー';
```

#### ステップ4B: 既存APIキーを修復（非推奨）

既存キーを使い続ける場合:

```dart
// AIzaSyD6GHNt4zJvN9m14t-Gv4ly80pIjZXHfrA が有効なら維持
// 無効なら新しいキーを作成（ステップ4A推奨）
```

#### ステップ5: 動作確認

```bash
# アプリを実行
flutter run

# ログで確認
flutter logs | grep "AICoach"

# ✅ 成功時のログ:
# "📤 [AICoach] Gemini APIリクエスト送信"
# "✅ [AICoach] 生成成功"

# ❌ 失敗時のログ:
# "❌ [AICoach] Gemini API エラー: 403" （APIキー無効）
# "❌ [AICoach] Gemini API エラー: 429" （クォータ超過）
# "⏱️ [AICoach] タイムアウト（8秒）" （ネットワーク問題）
```

---

## 🔧 修正手順まとめ

### 優先度1: Android広告IDの設定（必須）

```bash
# 1. AdMobコンソールでAndroid広告ユニットを作成
# 2. lib/widgets/banner_ad_widget.dart を編集
code lib/widgets/banner_ad_widget.dart
# 3. 129-130行目の空文字列を本番IDに変更
# 4. アプリを再ビルド
flutter clean
flutter pub get
flutter build apk --release
```

### 優先度2: Gemini APIキーの修正（重要）

```bash
# 1. Google Cloud Consoleで新しいAPIキーを作成
# 2. lib/services/ai_coach_service.dart を編集
code lib/services/ai_coach_service.dart
# 3. 14行目のAPIキーを新しいキーに変更
# 4. アプリを再起動
flutter run
```

---

## 📊 診断結果まとめ

| 問題 | 原因 | 影響 | 修正時間 | 優先度 |
|------|------|------|----------|--------|
| Android広告 | IDが空文字列 | 🔴 収益化不可 | 10分 | **最高** |
| iOS広告 | - | ✅ 正常 | - | - |
| Gemini API | APIキー無効 | 🟡 固定メッセージのみ | 15分 | **高** |

---

## 🎯 次のアクション

### 今すぐ実施すべきこと

- [ ] **1. Android広告ユニットID設定**（10分）
  - [ ] AdMobコンソールで広告ユニット作成
  - [ ] banner_ad_widget.dart の空文字列を本番IDに変更
  - [ ] Android実機で動作確認

- [ ] **2. Gemini APIキー修正**（15分）
  - [ ] Google Cloud Consoleで新しいAPIキー作成
  - [ ] ai_coach_service.dart のAPIキーを更新
  - [ ] AIコーチ機能の動作確認

### 確認すべきこと

- [ ] AdMobコンソールでAndroid広告の表示回数が増えているか
- [ ] AIコーチメッセージが毎日異なる内容になっているか
- [ ] エラーログに広告/APIエラーが出ていないか

---

## 📝 補足情報

### Android広告設定の参考情報

**現在のAndroidアプリID（AndroidManifest.xml）**:
```
ca-app-pub-3184270565267183~3432864611
```

このアプリIDに紐づく広告ユニットを作成する必要があります。

### Gemini API設定の参考情報

**エンドポイント**:
```
https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent
```

**タイムアウト**: 8秒  
**モデル**: gemini-1.5-flash-latest  
**Temperature**: 0.7  
**MaxOutputTokens**: 500

---

## 🔗 関連ドキュメント

- `FAMICA_ADMOB_ATT_IMPLEMENTATION_REPORT.md` - AdMob実装レポート
- `FAMICA_GEMINI_API_KEY_INVESTIGATION_REPORT.md` - Gemini API調査レポート（2025/11/28）
- `lib/widgets/banner_ad_widget.dart` - 広告ウィジェット実装
- `lib/services/ai_coach_service.dart` - AIコーチサービス実装

---

**診断完了日時**: 2026年1月5日 19:30  
**次回確認推奨**: 修正後24時間以内に動作確認
