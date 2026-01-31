# 🔍 Famica アプリ Gemini API キー使用箇所 調査レポート

## 📋 調査概要

Famica Flutter アプリにおける Gemini API（Google Generative AI）の使用箇所と、API キーの管理方法を完全に特定しました。

---

## 1️⃣ Gemini API キーの場所

### ✅ 特定完了

**ファイル**: `lib/services/ai_coach_service.dart`  
**行数**: 12行目  
**API キー**: `AIzaSyAEgW6kTe3Mxs8_Mu04sA_OWCMtQ8j2FdU`

```dart
// Gemini API設定
static const String geminiApiKey = 'AIzaSyAEgW6kTe3Mxs8_Mu04sA_OWCMtQ8j2FdU';
static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
```

### 🔍 検索結果サマリー

| 検索対象 | 結果 |
|---------|------|
| `/lib` ディレクトリ | ✅ `ai_coach_service.dart` で発見 |
| `/functions` ディレクトリ | ❌ Gemini は未使用（OpenAI のみ） |
| `/assets` ディレクトリ | ❌ 設定ファイル無し |

---

## 2️⃣ API キーの読み込み方法

### 📌 結論: **ソースコード内に直接ハードコード**

| 方式 | 使用状況 |
|------|---------|
| ✅ ソースコード内定数 | **使用中** (`ai_coach_service.dart` 12行目) |
| ❌ `.env` ファイル | 使用していない |
| ❌ `--dart-define` | 使用していない |
| ❌ Firebase Functions | Gemini は未使用（OpenAI のみ） |
| ❌ Firestore ドキュメント | 使用していない |
| ❌ 設定ファイル (json/yaml) | 使用していない |

### 🎯 特徴

- **シンプル**: 環境変数や外部設定なし
- **注意点**: ソースコードに含まれるため、Git 履歴にも残る
- **使用モデル**: `gemini-1.5-flash-latest`

---

## 3️⃣ API キー変更手順

### 🛠️ 変更が必要なファイル

**1つのファイルのみ変更すれば完了**

```
lib/services/ai_coach_service.dart
```

### 📝 修正手順

#### ステップ 1: ファイルを開く

```bash
open lib/services/ai_coach_service.dart
```

#### ステップ 2: 12行目を編集

**修正前**:
```dart
static const String geminiApiKey = 'AIzaSyAEgW6kTe3Mxs8_Mu04sA_OWCMtQ8j2FdU';
```

**修正後**:
```dart
static const String geminiApiKey = '新しいAPIキーをここに入力';
```

#### ステップ 3: アプリを再ビルド

```bash
# iOS
flutter clean
flutter pub get
flutter build ios

# Android
flutter clean
flutter pub get
flutter build apk
```

---

## 4️⃣ コード修正例（Before/After）

### 📄 Before（現在の実装）

```dart
class AICoachService {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Gemini API設定
  static const String geminiApiKey = 'AIzaSyAEgW6kTe3Mxs8_Mu04sA_OWCMtQ8j2FdU';
  static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  // ... 以下省略
}
```

### 📄 After（セキュアな実装例）

もしセキュリティを強化する場合は、以下のように環境変数化を推奨：

```dart
class AICoachService {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Gemini API設定（環境変数から取得）
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // デフォルト値は空文字
  );
  static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  // ... 以下省略
}
```

**ビルド時に API キーを渡す**:
```bash
flutter build apk --dart-define=GEMINI_API_KEY=新しいAPIキー
```

---

## 5️⃣ Plus ユーザー判定との連携

### ✅ 正しく機能しています

#### 🔗 連携フロー

```
1. AICoachCard (UI)
   ↓
2. AICoachService.getTodayCoachMessages(isPlusUser: bool)
   ↓
3. PlanService.isPlusUser() で Plus 判定
   ↓
4. Plus: 4枚のカード生成
   Free: 1枚のカード生成
```

#### 📊 プラン別の機能

| プラン | カード数 | 内容 |
|--------|---------|------|
| **Free** | 1枚 | 今日のひとこと（自分向け） |
| **Plus** | 4枚 | ① 今日のひとこと<br>② 相手への気づきカード<br>③ 6ヶ月の褒めポイント<br>④ これからの行動ヒント |

#### 🧩 実装箇所

**PlanService (`lib/services/plan_service.dart`)**:
```dart
/// 現在のユーザーがPlus会員かどうか
Future<bool> isPlusUser() async {
  final user = _auth.currentUser;
  if (user == null) return false;
  
  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final plan = userDoc.data()?['plan'] as String?;
  
  // Plus会員の場合、トライアル期限もチェック
  if (plan == 'plus') {
    // トライアル期限切れチェック...
    return true;
  }
  
  return false;
}
```

**AICoachService (`lib/services/ai_coach_service.dart`)**:
```dart
/// 今日のAI家事コーチメッセージを取得
Future<Map<String, String>> getTodayCoachMessages({required bool isPlusUser}) async {
  // isPlusUser に応じて生成するメッセージ数を変更
  final messages = await _generateCoachMessages(householdId, isPlusUser);
  return messages;
}
```

### ✅ 連携確認完了

- Plus ユーザー判定は `PlanService` で一元管理
- Firestore の `users/{uid}` ドキュメントの `plan` フィールドで判定
- トライアル期限切れも適切にチェック
- AI メッセージ生成時に正しく分岐

---

## 🎯 最終まとめ

### 📍 Gemini API キーはここにあった

```
lib/services/ai_coach_service.dart の 12行目
```

### 🔧 変更方法はこちら

1. **ファイルを開く**: `lib/services/ai_coach_service.dart`
2. **12行目を編集**: API キーを新しい値に置き換え
3. **アプリを再ビルド**: `flutter clean && flutter build`

### ✅ Plus ユーザー判定との連携

- **正常に機能中**
- Free: 1枚、Plus: 4枚のカード生成
- `PlanService.isPlusUser()` で判定

---

## 📝 推奨事項

### 🔒 セキュリティ強化（オプション）

現在は API キーがソースコードに含まれています。以下の対応を検討してください：

1. **環境変数化**: `--dart-define` を使用
2. **.gitignore 追加**: API キーを含むファイルを除外
3. **Firebase Remote Config**: 動的に API キーを取得

### 📋 Git 履歴のクリーンアップ（必要に応じて）

API キーがコミット履歴に残っている場合：

```bash
# 注意: 履歴を書き換えるため、チーム全体で調整が必要
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/services/ai_coach_service.dart" \
  --prune-empty --tag-name-filter cat -- --all
```

---

## 📌 調査完了日時

**2025年11月28日 13:51 (JST)**

---

## 🔗 関連ファイル

- `lib/services/ai_coach_service.dart` - Gemini API 呼び出し
- `lib/services/plan_service.dart` - Plus ユーザー判定
- `lib/widgets/ai_coach_card.dart` - AI コーチカード UI
- `functions/index.js` - Firebase Functions（OpenAI のみ使用）
