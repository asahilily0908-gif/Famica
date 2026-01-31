# 6ヶ月チャート - ユーザー別表示＆トグル機能実装完了

## 📋 実装概要
過去記録（6ヶ月分）チャートを以下の要件で修正しました：

1. **ユーザー別月次カウント（2系列）に復元**
2. **チャート表示の改善（大きいドット、アニメーションなし）**
3. **トグルUI追加（ライン⇔ドーナツ切り替え）**

---

## ✅ 実装内容

### 1. ユーザー別2系列の復元

#### Before（誤った実装）
```dart
// 合計のみの1系列
LineSeries<_TotalRecordChartData, String>(
  dataSource: chartData,  // 合計データ
  color: FamicaColors.primary,
  ...
)
```

#### After（正しい実装）
```dart
// ピンク系列（自分）
LineSeries<_UserRecordChartData, String>(
  dataSource: myChartData,  // myCount
  name: widget.myName,
  color: const Color(0xFFFF6FA5),  // ピンク
  ...
),
// ブルー系列（パートナー）
LineSeries<_UserRecordChartData, String>(
  dataSource: partnerChartData,  // partnerCount
  name: widget.partnerName,
  color: const Color(0xFF4A90E2),  // ブルー
  ...
),
```

**✅ データソース:**
- `myCount`: 自分の記録回数（ピンク）
- `partnerCount`: パートナーの記録回数（ブルー）
- 元のmonthlyDataから直接取得（データモデル変更なし）

---

### 2. チャート表示の改善

#### ドットサイズ拡大
```dart
markerSettings: const MarkerSettings(
  isVisible: true,
  height: 12,  // 8px → 12px (1.5倍)
  width: 12,
  borderWidth: 2.5,
),
```

#### アニメーション完全無効化
```dart
animationDuration: 0,  // floatアニメーションなし
```

---

### 3. トグルUI実装

#### A. StatefulWidgetへ変更
```dart
class SixMonthChartWidget extends StatefulWidget { ... }
class _SixMonthChartWidgetState extends State<SixMonthChartWidget> {
  bool _showLineChart = true;  // true: グラフ, false: 内訳
  ...
}
```

#### B. トグルボタンUI（右上）
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      _buildToggleButton(
        icon: Icons.show_chart,
        label: 'グラフ',
        isSelected: _showLineChart,
        onTap: () => setState(() => _showLineChart = true),
      ),
      _buildToggleButton(
        icon: Icons.pie_chart,
        label: '内訳',
        isSelected: !_showLineChart,
        onTap: () => setState(() => _showLineChart = false),
      ),
    ],
  ),
)
```

#### C. 表示切り替え
```dart
if (_showLineChart)
  _buildPerUserRecordCountChart()  // 折れ線グラフ（2系列）
else
  _buildUserBreakdownChart(),       // ドーナツ内訳
```

---

### 4. 凡例追加

グラフ上部に凡例を表示：
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _buildLegendItem(widget.myName, const Color(0xFFFF6FA5)),    // ピンク
    const SizedBox(width: 20),
    _buildLegendItem(widget.partnerName, const Color(0xFF4A90E2)), // ブルー
  ],
)
```

---

## 📊 データフロー確認

### monthlyDataの構造
```dart
List<Map<String, dynamic>> monthlyData = [
  {
    'monthLabel': '1月',
    'myCount': 15,        // 自分の記録回数
    'partnerCount': 12,   // パートナーの記録回数
  },
  ...
];
```

### チャートデータ変換
```dart
// 自分のデータ系列
final myChartData = widget.monthlyData.map((data) {
  return _UserRecordChartData(
    month: data['monthLabel'] as String,
    count: ((data['myCount'] as num?)?.toInt() ?? 0).toDouble(),
  );
}).toList();

// パートナーのデータ系列
final partnerChartData = widget.monthlyData.map((data) {
  return _UserRecordChartData(
    month: data['monthLabel'] as String,
    count: ((data['partnerCount'] as num?)?.toInt() ?? 0).toDouble(),
  );
}).toList();
```

**✅ データモデルは変更なし** - 既存のmonthlyDataをそのまま使用

---

## 🎨 UI仕様

### 色設定
- **自分**: `Color(0xFFFF6FA5)` - ピンク
- **パートナー**: `Color(0xFF4A90E2)` - ブルー

### トグルボタン
- **選択時**: `FamicaColors.primary` 背景 + 白文字
- **非選択時**: 透明背景 + グレー文字

### グラフ設定
- **ドットサイズ**: 12x12px
- **線の太さ**: 2.5px
- **アニメーション**: 無効（0ms）

---

## 🔄 変更ファイル

### 修正ファイル
1. `lib/widgets/six_month_chart_widget.dart` ✅
   - StatelessWidget → StatefulWidget
   - 合計系列（1本）→ ユーザー別系列（2本）
   - トグルUI追加
   - ドットサイズ拡大、アニメーション無効化

### データ集計ファイル（変更なし）
- データモデルは既存のmyCount/partnerCountを使用
- 集計ロジックの変更は不要

---

## ✅ 確認事項

### 折れ線グラフ
- ✅ ピンクとブルーの2本の線が表示される
- ✅ ドットが大きく見やすい（12x12px）
- ✅ アニメーションなし（即座に表示）
- ✅ 凡例が表示される（ユーザー名 + 色）

### トグルボタン
- ✅ 右上に「グラフ」「内訳」ボタンが表示
- ✅ 選択状態が視覚的にわかる
- ✅ タップで表示が切り替わる

### ドーナツ内訳
- ✅ ユーザー別のドーナツチャートが表示
- ✅ カテゴリ別の割合が表示

---

## 🎯 実装完了

要件通りの実装が完了しました：

1. ✅ **元のユーザー別月次カウント（2系列）に復元**
   - ピンク（自分）+ ブルー（パートナー）
   - データモデル変更なし

2. ✅ **チャート表示改善**
   - ドットサイズ: 12x12px に拡大
   - アニメーション完全無効化

3. ✅ **トグルUI追加**
   - 右上に切り替えボタン
   - グラフ ⇔ 内訳の切り替え

**LINE CHART HAS TWO SERIES: ピンク（myCount）+ ブルー（partnerCount）** ✅

---

## 📝 備考

- データ集計ロジックは変更していません
- monthlyDataにmyCount/partnerCountが含まれていることを前提
- 色はユーザーブレイクダウンと統一（ピンク/ブルー）
