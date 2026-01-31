# 🧹 Famica サブスクリプション完全削除レポート

**実行日:** 2026年1月22日  
**作業内容:** Famica Plusサブスクリプション機能の完全削除と広告付き無料版への移行

---

## ✅ 削除されたファイル

以下のファイルが完全に削除されました：

1. **lib/screens/paywall_screen.dart** - Paywallデザイン画面
2. **lib/services/plan_service.dart** - プラン管理サービス（InAppPurchase統合）
3. **lib/utils/plan_utils.dart** - プラン判定ユーティリティ
4. **lib/widgets/trial_status_banner.dart** - トライアルステータスバナー

---

## 📝 修正されたファイル

### 1. **lib/screens/settings_screen.dart**
- PlanServiceのimport削除
- PaywallScreenのimport削除
- TrialStatusBannerのimport削除
- Plus会員管理UI削除
- トライアル状態表示削除
- 「Plusプランを解約する」ボタン削除
- Plus/Freeステータスバナー削除
- シンプルな設定画面に変更（パートナー招待・ニックネーム・法務ページ・ログアウト・アカウント削除のみ）

### 2. **lib/widgets/banner_ad_widget.dart**
- PlanService削除
- isPlusUser()判定削除
- **全ユーザーに広告を表示**（Plus/Free判定なし）
- BannerAdWrapperクラス削除
- シンプルなBannerAdWidgetのみ残存

### 3. **lib/screens/main_screen.dart**
- FirestoreAuth/Firestoreのプラン監視コード削除
- BannerAdWrapper → BannerAdWidget に変更
- プラン状態変更検知ロジック削除
- シンプルな画面構成に変更

---

## ⚠️ 未完了の修正（継続作業が必要）

以下のファイルにはまだPlanService参照が残っている可能性があります：

### **要修正ファイル：**

1. **lib/screens/couple_screen.dart**
   - PlanService import削除
   - PaywallScreen import削除
   - TrialStatusBanner削除
   - `_buildAICoachSection()`のPlus判定削除
   - `_generateAndShowAIReport()`のPlus判定削除
   - `_sendThanksCard()`のPlus判定削除
   - AI機能を全ユーザーに開放

2. **lib/services/ai_coach_service.dart**
   - `getTodayCoachMessages(isPlusUser:)`パラメータを削除または常にtrueに
   - Plus/Free判定ロジック削除
   - 全ユーザーに全メッセージを表示

3. **lib/widgets/ai_coach_card.dart**
   - `isPlusUser`パラメータ削除
   - Plus専用カード表示ロジック削除

4. **lib/widgets/famica_header.dart**
   - Plus/Trialバッジ表示削除

5. **lib/screens/ai_suggestion_screen.dart**
   - PlanService import削除
   - PaywallScreen import削除
   - Plus判定削除

6. **lib/services/ai_service.dart**
   - Plus判定削除（既にfunctions側でチェックしているため）

7. **functions/index.js**
   - `generateAISuggestion` および `generateWeeklyReport` 関数のPlus判定削除
   - 全ユーザーがAI機能を利用可能に

8. **pubspec.yaml**
   - `in_app_purchase` パッケージ削除（依存関係から削除）

---

## 🎯 完了した作業

### ✅ UI削除
- ✅ Paywall画面削除
- ✅ Plus管理UI削除
- ✅ トライアルバナー削除
- ✅ Plan比較UI削除
- ✅ 「Plusを解約する」ボタン削除
- ✅ ⭐ Plusバッジ削除（settings画面から）

### ✅ ロジック削除
- ✅ PlanService完全削除
- ✅ plan_utils完全削除
- ✅ InAppPurchase初期化削除（main_screen）
- ✅ purchaseStream監視削除
- ✅ restorePurchases削除
- ✅ cancelPlusPlan削除
- ✅ Firestore plan監視削除（main_screen）

### ✅ 広告動作
- ✅ 全ユーザーに広告表示（Plus判定削除）
- ✅ BannerAdWidgetをシンプル化

### ✅ ルーティング
- ✅ router.dartにPaywall関連ルートなし（確認済み）

---

## 🔧 次のステップ（開発者が実施）

### **優先度: 高**

1. **couple_screen.dart修正**
   ```dart
   // 削除すべきimport
   import '../services/plan_service.dart';
   import 'paywall_screen.dart';
   import '../widgets/trial_status_banner.dart';
   
   // 修正すべきメソッド
   - _buildAICoachSection() - isPlusUser判定削除
   - _generateAndShowAIReport() - Paywall遷移削除
   - _sendThanksCard() - Plus判定削除
   ```

2. **ai_coach_service.dart修正**
   ```dart
   // getTodayCoachMessages()のシグネチャ変更
   Future<Map<String, String>> getTodayCoachMessages() async {
     // isPlusUserパラメータ削除
     // すべてのユーザーに4メッセージ返す
   }
   ```

3. **functions/index.js修正**
   ```javascript
   // Plus判定削除
   // if (userData.plan !== 'plus') { ... } を削除
   ```

4. **pubspec.yaml修正**
   ```yaml
   dependencies:
     # in_app_purchase: ^3.1.11  ← 削除
   ```

5. **flutter pub get実行**
   ```bash
   cd /Users/matsushimaasahi/Developer/famica
   flutter pub get
   flutter clean
   flutter build ios --release  # または flutter build appbundle
   ```

---

## 🧪 テストチェックリスト

実装完了後、以下を確認してください：

### **起動確認**
- [ ] アプリが起動する
- [ ] PlanServiceエラーが出ない
- [ ] InAppPurchaseエラーが出ない
- [ ] 広告が表示される

### **機能確認**
- [ ] AI家事コーチが全ユーザーで表示される
- [ ] 感謝メッセージ送信ができる
- [ ] 6ヶ月グラフが表示される
- [ ] 設定画面が正しく表示される

### **削除確認**
- [ ] PaywallScreen への遷移がない
- [ ] Plus/Freeの表示がない
- [ ] トライアルの表示がない
- [ ] サブスクリプション管理UIがない

---

## 📊 影響範囲

### **変更なし（安全）**
- ✅ 記録機能（QuickRecordScreen）
- ✅ 手紙機能（LetterScreen）
- ✅ データ構造（Firestore schema）
- ✅ 認証（AuthScreen）

### **変更あり**
- ⚠️ 広告：全ユーザー表示
- ⚠️ AI機能：全ユーザー利用可能（要修正完了後）
- ⚠️ 設定画面：シンプル化

---

## 💰 収益モデル変更

### **Before（削除前）**
- サブスクリプション課金（月額/年額）
- トライアル7日間
- Plus機能：広告なし・AI全機能・6ヶ月グラフ

### **After（削除後）**
- 広告収益のみ
- 全機能無料
- AI機能無料
- 6ヶ月グラフ無料

---

## ⚠️ 既存ユーザーへの影響

### **Plus会員だったユーザー**
- Firestoreの `users/{uid}.plan` が "plus" のまま残存
- 実害なし（Plus判定ロジックが削除されているため）
- 広告が表示されるようになる

### **Free会員だったユーザー**
- 変更なし
- 全機能が利用可能になる

---

## 🔐 セキュリティ

### **Firestore Rules**
- `plan`フィールドは残存しているが、読み書きロジックがないため影響なし
- 必要に応じて将来的に削除可能

### **Cloud Functions**
- ✅ Plus判定削除必須（functions/index.js）

---

## 📱 リリース前の最終確認

1. ✅ ファイル削除（4ファイル）
2. ⏳ import文修正（継続中）
3. ⏳ Plus判定削除（継続中）
4. ⏳ pubspec.yaml修正（未完了）
5. ⏳ Cloud Functions修正（未完了）
6. ⏳ ビルド確認（未完了）
7. ⏳ 実機テスト（未完了）

---

## 📝 まとめ

**現状:**
- ✅ メインファイル（settings, banner_ad, main_screen）は修正完了
- ⚠️ couple_screen等の大きなファイルは未修正
- ⚠️ AI関連サービスは未修正
- ⚠️ Cloud Functionsは未修正

**次の作業:**
1. couple_screen.dartの修正
2. ai_coach_service.dartの修正
3. functions/index.jsの修正
4. pubspec.yamlの修正
5. ビルド＆テスト

**推定作業時間:** 残り1〜2時間

---

**作成者:** Claude (Cline)  
**日付:** 2026年1月22日 21:19
