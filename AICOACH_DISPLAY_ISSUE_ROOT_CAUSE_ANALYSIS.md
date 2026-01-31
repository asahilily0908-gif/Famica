# AIコーチカード非表示問題：根本原因分析レポート

## 🔍 分析対象
CoupleScreenにおいてAIコーチカード（💕 相手への気づき など）が表示されない問題の構造的原因を特定

---

## ✅ 確認済み：問題なし

### 1. AICoachSection Widget (`lib/widgets/ai_coach_card.dart`)

**結論**: このWidget自体には非表示になる条件が**存在しない**

#### 確認事項
```dart
@override
Widget build(BuildContext context) {
  return Container(  // ← 必ず Container を返す
    // ... 常に描画される
  );
}
```

- ✅ 早期 return なし
- ✅ 条件分岐による非表示なし
- ✅ `if (!hasData) return SizedBox.shrink()` のような分岐なし

#### メッセージの扱い
```dart
message: (messages['message1'] ?? '').toString(),
```

- null coalescing演算子 (`??`) で空文字列にフォールバック
- さらに `.toString()` で安全に変換
- **結果**: messagesが空でもカードは描画される（ただし空文字列として）

#### Plus/Free判定
```dart
if (isPlusUser) {
  // 4枚のカード
} else {
  // 1枚のカード + アップグレード誘導
}
```

- どちらの分岐も必ず何かを表示
- 非表示にする条件なし

---

## 🚨 疑わしい箇所

### 2. couple_screen.dart の `_buildAICoachSection()`

#### 現在の実装構造
```dart
Widget _buildAICoachSection() {
  return FutureBuilder<bool>(  // ← Plus判定
    future: PlanService().isPlusUser(),
    builder: (context, planSnapshot) {
      final isPlusUser = planSnapshot.data ?? false;
      
      return FutureBuilder<PartnerStatus>(  // ← パートナー状態判定
        future: _getPartnerStatus(),
        builder: (context, partnerSnapshot) {
          final partnerStatus = partnerSnapshot.data ?? PartnerStatus.noPartner;
          
          return FutureBuilder<Map<String, String>>(  // ← AIメッセージ取得
            future: AICoachService().getTodayCoachMessages(isPlusUser: isPlusUser).timeout(...),
            builder: (context, coachSnapshot) {
              // ここで messages を決定
              Map<String, String> messages;
              
              if (coachSnapshot.connectionState == ConnectionState.waiting) {
                messages = _getUIFallbackMessages(isPlusUser, partnerStatus);
              } else if (coachSnapshot.hasError) {
                messages = _getUIFallbackMessages(isPlusUser, partnerStatus);
              } else if (coachSnapshot.hasData) {
                messages = coachSnapshot.data ?? _getUIFallbackMessages(isPlusUser, partnerStatus);
                if (messages.isEmpty || !messages.containsKey('message1')) {
                  messages = _getUIFallbackMessages(isPlusUser, partnerStatus);
                }
              } else {
                messages = _getUIFallbackMessages(isPlusUser, partnerStatus);
              }
              
              return AICoachSection(  // ← 必ず呼ばれる
                isPlusUser: isPlusUser,
                messages: messages,
                onUpgrade: () { ... },
              );
            },
          );
        },
      );
    },
  );
}
```

#### ✅ 確認結果
- **早期returnなし**: すべての分岐で `AICoachSection` を返している
- **非表示条件なし**: `SizedBox.shrink()` や `Container()` への分岐なし
- **必ず描画**: どの状態でも `AICoachSection` Widget が構築される

---

## 🎯 根本原因の仮説

### 仮説1: 空文字列メッセージによる「見えない表示」

#### 状況
```dart
message: (messages['message1'] ?? '').toString(),
```

messagesが以下の状態の場合：
```dart
{
  'message1': '',  // 空文字列
  'message2': '',
  'message3': '',
  'message4': '',
}
```

#### 結果
- カードは**描画される**
- しかし**空文字列を表示**
- ユーザーには「カードが表示されていない」ように見える

#### この状況が発生する条件
1. `AICoachService.getTodayCoachMessages()` が空Mapを返す
2. `_getUIFallbackMessages()` が空文字列を含むMapを返す
3. Firestoreキャッシュから空データを取得

---

### 仮説2: messages Mapのキー不一致

#### 想定されるシナリオ
AICoachServiceが返すMapのキー構造が期待と異なる場合：

```dart
// 期待: { 'message1': '...', 'message2': '...', ... }
// 実際: { 'msg1': '...', 'msg2': '...', ... }  // キー名が違う
// または: { 'coaching1': '...', ... }
```

#### 結果
```dart
messages['message1'] ?? ''  // ← キーがないので ''
```

- すべてのメッセージが空文字列になる
- カードは描画されるが空

---

### 仮説3: Timestamp/Dynamic型の混入による変換失敗

#### AICoachServiceの保存処理
```dart
// lib/services/ai_coach_service.dart
messages.forEach((key, value) {
  dataToSave[key] = value.toString();
});
dataToSave['createdAt'] = FieldValue.serverTimestamp();
```

#### Firestoreから読み込み時
```dart
final userMessages = data[user.uid] as Map<String, dynamic>;
userMessages.forEach((key, value) {
  if (key != 'createdAt' && value != null && value.toString().trim().isNotEmpty) {
    safeMessages[key] = value.toString();
  }
});
```

#### 潜在的な問題
- `createdAt` はTimestamp型
- `value.toString()` で変換されるが、空文字列判定で弾かれる可能性
- または、Timestamp型が文字列として表示される（例: "Timestamp(seconds=...)"）

---

## 📋 次の調査ステップ（優先順位順）

### 1. messagesの実際の内容を確認（最優先）

#### 確認方法
`couple_screen.dart` の `_buildAICoachSection()` 内に以下を追加：

```dart
builder: (context, coachSnapshot) {
  Map<String, String> messages;
  // ... messages決定ロジック ...
  
  // ★デバッグログ追加
  debugPrint('🔍 [AICoach Debug] isPlusUser: $isPlusUser');
  debugPrint('🔍 [AICoach Debug] partnerStatus: $partnerStatus');
  debugPrint('🔍 [AICoach Debug] messages keys: ${messages.keys}');
  debugPrint('🔍 [AICoach Debug] message1: "${messages['message1']}"');
  debugPrint('🔍 [AICoach Debug] message2: "${messages['message2']}"');
  debugPrint('🔍 [AICoach Debug] message3: "${messages['message3']}"');
  debugPrint('🔍 [AICoach Debug] message4: "${messages['message4']}"');
  
  return AICoachSection(...);
}
```

#### 期待される結果
- messagesが空Mapか
- キー名が正しいか（message1, message2...）
- 値が空文字列か、意味のあるテキストか

---

### 2. _getUIFallbackMessages() の返り値を確認

#### 確認方法
```dart
Map<String, String> _getUIFallbackMessages(bool isPlusUser, PartnerStatus partnerStatus) {
  final result = { ... };
  
  // ★デバッグログ追加
  debugPrint('🔍 [Fallback] isPlusUser: $isPlusUser, partnerStatus: $partnerStatus');
  debugPrint('🔍 [Fallback] result: $result');
  
  return result;
}
```

---

### 3. AICoachService.getTodayCoachMessages() の返り値を確認

#### 確認方法
`lib/services/ai_coach_service.dart` の `getTodayCoachMessages()` 内：

```dart
Future<Map<String, String>> getTodayCoachMessages({required bool isPlusUser}) async {
  try {
    // ... ロジック ...
    
    // ★返却直前にログ追加
    debugPrint('🔍 [Service] Returning messages: $messages');
    return messages;
    
  } catch (e) {
    debugPrint('❌ [Service] Error: $e');
    return _getDefaultMessages(isPlusUser, partnerStatus: PartnerStatus.noPartner);
  }
}
```

---

### 4. Firestoreキャッシュの内容を確認

#### 確認方法
```dart
if (coachDoc.exists) {
  final data = coachDoc.data();
  debugPrint('🔍 [Firestore Cache] document data: $data');
  
  if (data != null && data.containsKey(user.uid)) {
    final userMessages = data[user.uid] as Map<String, dynamic>;
    debugPrint('🔍 [Firestore Cache] userMessages: $userMessages');
    // ...
  }
}
```

---

## 🎯 最も可能性の高い原因（推定）

### **原因: 空文字列メッセージの描画**

#### 根拠
1. AICoachSection Widgetには非表示条件がない
2. couple_screen.dartにも早期returnがない
3. しかし、ユーザーには「表示されていない」ように見える

#### 結論
**カードは描画されているが、空文字列を表示しているため視覚的に「ない」ように見える**

#### この状況が発生する流れ
```
1. AICoachService.getTodayCoachMessages() 呼び出し
   ↓
2. 何らかの理由で空Mapまたは空文字列を含むMapを返す
   ├─ Gemini APIエラー → _getDefaultMessages() → 正常な文言を返すはず
   ├─ Firestoreキャッシュが空 → フォールバック → 正常な文言を返すはず  
   └─ パース失敗 → フォールバック → 正常な文言を返すはず
   ↓
3. messages = { 'message1': '', 'message2': '', ... }
   ↓
4. AICoachCard(message: '')  ← 空文字列を表示
   ↓
5. カード枠は表示されるが、テキストが空で「ない」ように見える
```

---

## 🚨 確定させるべきこと

### 必須の確認事項
1. **messages変数の実際の値** （デバッグログで確認）
2. **_getUIFallbackMessages() が空文字列を返していないか**
3. **AICoachService が空Mapを返していないか**

### 確認方法
上記の「次の調査ステップ」のデバッグログを追加して実行

---

## 📝 まとめ

### 現時点で確定していること
- ✅ AICoachSection Widget自体には非表示条件がない
- ✅ couple_screen.dartの_buildAICoachSection()にも早期returnがない
- ✅ すべての分岐でAICoachSectionは構築される

### 未確定（次の調査が必要）
- ❓ messagesの実際の内容（空文字列か？）
- ❓ _getUIFallbackMessages()の返り値
- ❓ AICoachServiceの返り値

### 最も可能性が高い原因
**カードは描画されているが、空文字列メッセージを表示しているため「ない」ように見える**

---

**次のアクション**: デバッグログを追加して実際のmessages内容を確認する
