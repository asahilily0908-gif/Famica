# Famica Phase 5: Firestore安定化＋ふたり画面統合 - 完了報告

## 📅 実装日時
2025年10月16日

## 🎯 実装目標
既にFirebase初期化とUI構成が安定したため、Firestoreのリアルタイム更新最適化と、ふたり画面のデータ集計ロジックを統合する。

## ✅ 実装完了項目

### 1️⃣ Firestoreのリアルタイム監視（StreamBuilder）最適化
- ✅ `lib/services/analytics_service.dart` 作成
  - memberIdごとの記録集計機能
  - リアルタイム統計データ取得（Stream）
  - 月別・全期間の集計対応
  - カテゴリ別集計
  - 月別推移データ（直近6ヶ月）

### 2️⃣ 記録の集計（memberIdごとに合計時間と回数）
- ✅ `MemberStats` クラス実装
  - 合計時間（totalMinutes）
  - 合計回数（totalCount）
  - カテゴリ別内訳（categoryBreakdown）
  - フォーマット済み時間表示
  - 平均時間計算

### 3️⃣ 「ふたり」タブでのグラフ／比率表示
- ✅ `lib/screens/couple_screen.dart` 作成
  - 円グラフ（PieChart）による分担比率表示
  - メンバー別詳細表示
  - カテゴリ別内訳（プログレスバー）
  - 月別/累計の切り替え機能
  - 月選択ナビゲーション

### 4️⃣ householdId単位でのデータ取得（認証済ユーザーのみに限定）
- ✅ AnalyticsServiceで`getCurrentUserHouseholdId()`使用
- ✅ Firestoreクエリは全てhouseholdId単位
- ✅ StreamBuilderによるリアルタイム更新


## 🔧 技術スタック更新

### 追加パッケージ
```yaml
dependencies:
  flutter_riverpod: ^2.4.9  # 状態管理
  fl_chart: ^0.65.0         # グラフ表示
```

### 主要ファイル構成
```
lib/
├── services/
│   ├── analytics_service.dart      # 📊 集計サービス（NEW）
│   └── firestore_service.dart      # 既存
├── screens/
│   ├── couple_screen.dart          # 💑 ふたり画面（NEW）
│   ├── main_screen.dart            # タブ統合済み
│   └── ...
├── constants/
│   └── famica_colors.dart          # 色定数追加
└── main.dart                        # Riverpod統合済み
```

## 🎨 UI実装詳細

### ふたり画面（CoupleScreen）
1. **ヘッダー**
   - タイトル「ふたりの記録」
   - 月別/累計切り替えボタン
   - 月選択ナビゲーション（月別時のみ）

2. **家事分担比率カード**
   - 円グラフによる視覚化
   - メンバー別色分け
   - パーセント表示
   - 合計時間・合計回数の表示

3. **メンバー別詳細カード**
   - メンバーごとのカード表示
   - 合計時間・合計回数
   - メンバーカラー統一

4. **カテゴリ別内訳カード**
   - メンバーごとのカテゴリ分析
   - プログレスバーによる比率表示
   - パーセント数値表示

## 📊 データフロー

```
Firestore (households/{householdId}/records)
  ↓ Stream
AnalyticsService.getMemberStatsForMonth()
  ↓ StreamBuilder
CoupleScreen
  ↓ UI更新
円グラフ + 詳細カード + カテゴリ内訳
```

## 🔄 リアルタイム更新

### StreamBuilderパターン
```dart
StreamBuilder<Map<String, MemberStats>>(
  stream: _analyticsService.getMemberStatsForMonth(_selectedMonth),
  builder: (context, snapshot) {
    // リアルタイム統計データの表示
  },
)
```

### 自動更新トリガー
- 記録追加時 → 自動で「ふたり」画面更新
- 記録削除時 → 自動で「ふたり」画面更新
- メンバー追加時 → 自動で統計再計算

## 🎯 Phase 5の目標達成状況

| 要件 | 状態 | 詳細 |
|------|------|------|
| Firestoreリアルタイム監視最適化 | ✅ 完了 | StreamBuilder + asyncMap実装 |
| 記録集計ロジック | ✅ 完了 | memberIdごと、カテゴリ別集計 |
| ふたり画面のグラフ表示 | ✅ 完了 | 円グラフ、プログレスバー実装 |
| householdId単位データ取得 | ✅ 完了 | 全クエリでhouseholdId使用 |

## 🚀 今後の拡張予定

### 短期（Phase 6想定）
- [ ] 月別推移グラフの追加
- [ ] 画面キャプチャ機能（統計のシェア）
- [ ] データエクスポート機能（CSV）

### 中期
- [ ] 目標設定機能（分担比率の目標）
- [ ] 通知機能（記録リマインダー）
- [ ] アチーブメント機能

### 長期
- [ ] 家計簿機能との連携
- [ ] AI による分担提案
- [ ] 複数世帯の比較機能

## 📝 使用方法

### 1. ふたり画面の表示
1. アプリ起動
2. ボトムナビゲーションの「ふたり」タブをタップ
3. 月別/累計を切り替えて表示

### 2. 統計の確認
- **円グラフ**: 全体の分担比率を一目で把握
- **メンバー別詳細**: 個人の活動量を確認
- **カテゴリ別内訳**: どの家事に時間をかけているか分析

### 3. 月の切り替え
- 月別表示時、左右の矢印で過去の月を参照可能
- 現在月より未来は選択不可

## 🎨 デザイン仕様

### カラーパレット
- プライマリ: `#FF6B9D` (ピンク)
- セカンダリ: `#FF8FAB` (明るいピンク)
- テキストダーク: `#2D2D2D`
- テキストライト: `#757575`

### グラフ色
- メンバー1: プライマリ（ピンク）
- メンバー2: セカンダリ（明るいピンク）
- メンバー3: パープル（`#9C27B0`）
- メンバー4: ピンク（`#E91E63`）

## 🔧 技術的ポイント

### 1. asyncMapの活用
```dart
.snapshots()
.asyncMap((snapshot) async {
  // household情報を非同期で取得
  final householdDoc = await _firestore
      .collection('households')
      .doc(householdId)
      .get();
  
  // 集計処理
  return stats;
});
```

### 2. Riverpod統合
```dart
void main() async {
  // ...
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3. fl_chartの円グラフ
```dart
PieChart(
  PieChartData(
    sections: members.map((member) {
      return PieChartSectionData(
        value: member.totalMinutes.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        color: _getMemberColor(index),
        // ...
      );
    }).toList(),
  ),
)
```

## ⚠️ 注意事項

1. **Firestoreインデックス**: 月別クエリにインデックスが必要な場合がある
2. **パフォーマンス**: メンバー数が多い場合、集計処理に時間がかかる可能性

## 🎉 Phase 5 完了！

Famica Phase 5「Firestore安定化＋ふたり画面統合」が無事完了しました。

リアルタイム更新による快適な統計表示、視覚的にわかりやすいグラフ表示により、
カップルの家事分担状況をより明確に把握できるようになりました。

次のPhase 6では、月別推移グラフやデータ共有機能などの拡張を予定しています。

---

**実装者**: Cline AI Assistant  
**完了日時**: 2025年10月16日 17:58
**Git ブランチ**: phase5-couple-screen-integration
