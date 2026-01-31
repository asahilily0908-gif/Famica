# AIコーチカード空文字列問題：修正完了レポート

## 🎯 修正概要

**問題**: ソロ利用時にAIコーチカード（💕 相手への気づき など）が空文字列で表示され、「カードが出ていないように見える」状態だった

**原因**: ソロ利用（PartnerStatus.noPartner）時に空文字列がFirestoreにキャッシュ保存され、それが再利用されていた

**修正**: 空文字列の保存を防止し、キャッシュ読み込み時に欠損を検出してフォールバックで補完する仕組みを実装

---

## ✅ 実装した修正

### 1. キャッシュ読み込み時の検証強化

#### 修正前
```dart
if (safeMessages.isEmpty || 
    !safeMessages.containsKey('message1') ||
    safeMessages['message1']!.trim().isEmpty) {
  // フォールバック
}
return safeMessages;
```

#### 修正後
```dart
if (safeMessages.isEmpty || 
    !safeMessages.containsKey('message1') ||
    safeMessages['message1']!.trim().isEmpty) {
  print('⚠️ [AICoach] キャッシュが不正（message1が空） - フォールバック使用');
  return _getDefaultMessages(isPlusUser, partnerStatus: partnerStatus);
}

// ★Plusユーザーの場合、message2〜4も検証
if (isPlusUser) {
  final requiredKeys = ['message2', 'message3', 'message4'];
  final missingKeys = requiredKeys.where((key) => 
    !safeMessages.containsKey(key) || 
    safeMessages[key]!.trim().isEmpty
  ).toList();
  
  if (missingKeys.isNotEmpty) {
    print('⚠️ [AICoach] キャッシュに欠損あり（$missingKeys） - フォールバックで補完');
    // 欠損しているメッセージをフォールバックで補完
    final fallbackMessages = _getDefaultMessages(isPlusUser, partnerStatus: partnerStatus);
    for (final key in missingKeys) {
      safeMessages[key] = fallbackMessages[key]!;
    }
  }
}

return safeMessages;
```

**効果**:
- message1だけでなく、message2〜4の空も検出
- 欠損したメッセージだけをフォールバックで補完
- 既存の正常なメッセージは保持

---

### 2. 空文字列の保存防止

#### 修正前
```dart
Future<void> _saveCoachMessages(...) async {
  try {
    final Map<String, dynamic> dataToSave = {};
    messages.forEach((key, value) {
      dataToSave[key] = value.toString();
    });
    // 保存処理...
  }
}
```

#### 修正後
```dart
Future<void> _saveCoachMessages(...) async {
  try {
    // ★【重要】空文字列を含むメッセージは保存しない
    final hasEmptyValue = messages.values.any((v) => v.trim().isEmpty);
    if (hasEmptyValue) {
      print('⚠️ [AICoach] 空文字列を含むため保存をスキップ');
      return;
    }
    
    final Map<String, dynamic> dataToSave = {};
    messages.forEach((key, value) {
      dataToSave[key] = value.toString();
    });
    // 保存処理...
  }
}
```

**効果**:
- 空文字列を含むMapは一切保存しない
- 以後、空キャッシュが作成されることを防止
- 次回アクセス時に正常な生成が行われる

---

## 🔧 既存の3状態ロジック（変更なし）

以下のロジックは既に実装済みで、今回の修正で変更なし：

### ソロ利用時の固定メッセージ
```dart
Map<String, String> _getDefaultMessages(bool isPlusUser, {PartnerStatus partnerStatus = PartnerStatus.noPartner}) {
  if (isPlusUser) {
    String message2;
    
    if (partnerStatus == PartnerStatus.noPartner) {
      // 状態1: ソロ利用 → 招待ガイド
      message2 = '👥 パートナーを招待すると\n・相手への気づきカード\n・ふたりの褒めポイント\nが表示されます';
    } else if (partnerStatus == PartnerStatus.invitedNoRecords) {
      // 状態2: 招待済み・記録なし → ソフトガイド
      message2 = 'パートナーはまだ記録を始めていないようです。\n最初の一歩は少しハードルが高いもの。\n声をかけて、一緒に始めてみませんか？';
    } else {
      // 状態3: 招待済み・記録あり → 通常のコーチング
      message2 = '家事は見えにくい頑張りが多いものです。パートナーも、あなたと同じように日々動いてくれています。一言『ありがとう』を伝えるだけでも、関係は少し楽になります。';
    }
    
    return {
      'message1': '今日も家事の記録、おつかれさまです。小さな家事でも、積み重ねることに意味があります。できたことに目を向けてみましょう。',
      'message2': message2,
      'message3': '家事を続けてきた時間そのものが、ふたりの成果です。完璧じゃなくても、続けてきたことは立派な前進。これまでの積み重ねを、少し振り返ってみましょう。',
      'message4': '今日は新しいことを増やさなくても大丈夫。今やっている家事を、ひとつだけ意識して続けてみましょう。それだけでも、負担の偏りに気づけることがあります。',
    };
  } else {
    return {
      'message1': '今日も家事の記録、おつかれさまです。小さな家事でも、積み重ねることに意味があります。できたことに目を向けてみましょう。',
    };
  }
}
```

---

## 📊 動作フロー（修正後）

```
1. getTodayCoachMessages() 呼び出し
   ↓
2. Firestoreキャッシュ確認
   ├─ キャッシュなし → 生成へ
   └─ キャッシュあり
      ↓
      ★message1の検証
      ├─ 空 or なし → フォールバック返却
      └─ OK
         ↓
         ★Plusの場合、message2〜4の検証
         ├─ 欠損あり → フォールバックで補完
         └─ すべてOK → そのまま返却
   ↓
3. 生成処理（必要な場合）
   ↓
4. 保存前チェック
   ★空文字列を含む？
   ├─ Yes → 保存スキップ（ログ出力）
   └─ No → Firestoreに保存
   ↓
5. メッセージ返却
```

---

## 🎉 達成した目標

### ✅ 完了した要件
1. **空文字列の保存防止**
   - `messages.values.any((v) => v.trim().isEmpty)` でチェック
   - 空を含む場合は保存をスキップ

2. **キャッシュ読み込み時の補完**
   - message2〜4が空の場合を検出
   - フォールバックで補完

3. **ソロ利用時の固定メッセージ**
   - 既に実装済みの3状態ロジックを活用
   - message2〜4に必ず意味のある文言

4. **UI側は変更なし**
   - AICoachSection / couple_screen.dart は未修正
   - サービス層のみで問題を解決

### 🚫 再発防止策
- 空文字列を含むMapは**絶対に保存しない**
- キャッシュ読み込み時に**必ず検証**
- 欠損があれば**自動補完**
- すべてのエラーケースで**フォールバック使用**

---

## 📝 変更ファイル

- `lib/services/ai_coach_service.dart`
  - `getTodayCoachMessages()` - キャッシュ検証ロジック強化
  - `_saveCoachMessages()` - 空文字列保存防止

---

## 🧪 テスト項目

### 手動テスト
1. **ソロ利用 + Plus会員**
   - [ ] AIコーチカード4枚すべてにテキストが表示される
   - [ ] message2が「👥 パートナーを招待すると...」と表示される
   - [ ] カード枠が空にならない

2. **キャッシュ取得時**
   - [ ] キャッシュログが出ても、カードは正常に表示される
   - [ ] 欠損したメッセージはフォールバックで補完される

3. **エラー時**
   - [ ] Gemini API失敗時もフォールバックが表示される
   - [ ] 空UIや空カードが発生しない

### 確認コマンド
```bash
flutter run
# CoupleScreenを開いてAIコーチカードを確認
```

---

## 🚀 リリース準備

### 確認事項
- [x] コンパイルエラーなし（30件の警告はprintのみ）
- [x] 空文字列保存防止実装
- [x] キャッシュ検証ロジック実装
- [x] フォールバック補完実装
- [x] UI側は未修正（サービス層のみで解決）

### 次のステップ
1. 実機でテスト（ソロ利用 + Plus会員）
2. キャッシュがある状態でのテスト
3. 問題なければリリース可能

---

## 📄 関連ドキュメント

- `AICOACH_DISPLAY_ISSUE_ROOT_CAUSE_ANALYSIS.md` - 根本原因分析
- `FAMICA_PARTNER_INSIGHT_3STATE_COMPLETE.md` - 3状態ロジック実装

---

**実装日**: 2025年12月16日
**実装者**: Claude (Cline)
**修正内容**: AIコーチカード空文字列問題の完全修正
