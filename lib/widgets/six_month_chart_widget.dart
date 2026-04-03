import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/famica_colors.dart';
import '../l10n/app_localizations.dart';

/// 過去記録（6ヶ月分）ウィジェット
class SixMonthChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> monthlyData;
  final String myName;
  final String partnerName;
  final Map<String, Map<String, int>> categoryData;
  final Map<String, Map<String, int>> userBreakdownData;
  final bool isPartnerInvited;

  const SixMonthChartWidget({
    super.key,
    required this.monthlyData,
    required this.myName,
    required this.partnerName,
    this.categoryData = const {},
    this.userBreakdownData = const {},
    this.isPartnerInvited = true,
  });

  @override
  State<SixMonthChartWidget> createState() => _SixMonthChartWidgetState();
}

class _SixMonthChartWidgetState extends State<SixMonthChartWidget> {
  bool _showLineChart = true; // true: 折れ線グラフ, false: ドーナツ

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.monthlyData.isEmpty && widget.userBreakdownData.isEmpty) {
      return _buildEmptyState(l);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションタイトル + 単一トグルボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.chartPast6Months,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FamicaColors.textDark,
                ),
              ),
              // 単一トグルボタン（アウトラインスタイル）
              OutlinedButton(
                onPressed: () => setState(() => _showLineChart = !_showLineChart),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FamicaColors.primary,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(
                    color: FamicaColors.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showLineChart ? Icons.pie_chart : Icons.show_chart,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l.chartBreakdown,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // A. 折れ線グラフ or B. ドーナツ内訳（トグルで切り替え）
          if (_showLineChart)
            _buildPerUserRecordCountChart(l)
          else
            _buildUserBreakdownChart(l),
        ],
      ),
    );
  }

  /// トグルボタン
  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FamicaColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A. 棒グラフ（記録回数）- ユーザーごとの2系列
  Widget _buildPerUserRecordCountChart(AppLocalizations l) {
    if (widget.monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    // デバッグログ: 月次カウントデータ
    debugPrint('📊 [6MonthChart] Monthly Data:');
    for (var data in widget.monthlyData) {
      final month = data['monthLabel'] as String;
      final myCount = (data['myCount'] as num?)?.toInt() ?? 0;
      final partnerCount = (data['partnerCount'] as num?)?.toInt() ?? 0;
      debugPrint('  $month: ${widget.myName}=$myCount, ${widget.partnerName}=$partnerCount');
    }

    // 棒グラフ用のデータを作成
    final barGroups = <BarChartGroupData>[];
    final monthLabels = <String>[];
    final allCounts = <double>[];
    
    for (int i = 0; i < widget.monthlyData.length; i++) {
      final data = widget.monthlyData[i];
      final myCount = ((data['myCount'] as num?)?.toInt() ?? 0).toDouble();
      final partnerCount = ((data['partnerCount'] as num?)?.toInt() ?? 0).toDouble();
      
      allCounts.add(myCount);
      allCounts.add(partnerCount);
      monthLabels.add(data['monthLabel'] as String);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            // 自分の棒（ピンク）
            BarChartRodData(
              toY: myCount,
              color: const Color(0xFFFF6FA5),
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            // パートナーの棒（ブルー）
            BarChartRodData(
              toY: partnerCount,
              color: const Color(0xFF4A90E2),
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          barsSpace: 4, // 棒の間隔
        ),
      );
    }

    // Y軸の範囲を計算（整数ステップ）
    final maxCount = allCounts.isEmpty ? 10.0 : allCounts.reduce((a, b) => a > b ? a : b);
    final minY = 0.0;
    final maxY = (maxCount + 2).ceilToDouble(); // 最大値+2（余白）
    final interval = maxY <= 8 ? 1.0 : (maxY <= 16 ? 2.0 : (maxY / 5).ceilToDouble());

    debugPrint('📊 [6MonthChart] Bar Axis: minY=$minY, maxY=$maxY, interval=$interval');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 凡例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(widget.myName, const Color(0xFFFF6FA5)),
            const SizedBox(width: 20),
            _buildLegendItem(widget.partnerName, const Color(0xFF4A90E2)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: BarChart(
              BarChartData(
                minY: minY,
                maxY: maxY,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        // 整数のみ表示
                        if (value != value.toInt().toDouble()) {
                          return const SizedBox.shrink();
                        }
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthLabels[index],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isMyData = rodIndex == 0;
                      final name = isMyData ? widget.myName : widget.partnerName;
                      return BarTooltipItem(
                        l.chartCountTimes(name, rod.toY.toInt()),
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
              swapAnimationDuration: Duration.zero, // アニメーション無効化
            ),
          ),
        ),
      ],
    );
  }

  /// 凡例アイテム
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FamicaColors.textDark,
          ),
        ),
      ],
    );
  }

  /// B. ふたりの家事の内訳
  Widget _buildUserBreakdownChart(AppLocalizations l) {
   if (widget.userBreakdownData.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            l.chartNoData,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.chartStartRecording,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, String>>(
      future: _getCategoryNames(l),
      builder: (context, snapshot) {
        final categoryNames = snapshot.data ?? {};
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserPieCard(
              widget.myName,
              user.uid,
              categoryNames,
              const Color(0xFFFF6FA5),
              l,
            ),
            const SizedBox(height: 16),
            // パートナーが招待されていない場合は招待案内を表示
            if (!widget.isPartnerInvited)
              _buildPartnerInviteAnnouncement(l)
            else
              if (widget.userBreakdownData.keys.any((uid) => uid != user.uid))
                _buildUserPieCard(
                  widget.partnerName,
                  widget.userBreakdownData.keys.firstWhere(
                    (uid) => uid != user.uid,
                  ),
                  categoryNames,
                  const Color(0xFF4A90E2),
                  l,
                ),
          ],
        );
      },
    );
  }

  Widget _buildUserPieCard(
    String userName,
    String userId,
    Map<String, String> categoryNames,
    Color userColor,
    AppLocalizations l,
  ) {
    final userCategories = widget.userBreakdownData[userId] ?? {};
    
    if (userCategories.isEmpty) {
      // 同じレイアウト制約を使用（padding, decoration等）
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: FamicaColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            // 通常のカードと同じ高さを確保（Row構造を維持）
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // チャート領域と同じサイズ
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 20),
                // テキスト領域
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        l.chartNoData,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final totalMinutes = userCategories.values.fold(0, (sum, minutes) => sum + minutes);
    final sortedCategories = userCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // カテゴリごとの色を生成
    final colors = _generateCategoryColors(sortedCategories.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            userName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FamicaColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ドーナツチャート
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: sortedCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final categoryEntry = entry.value;
                      final percent = (categoryEntry.value / totalMinutes * 100);
                      
                      return PieChartSectionData(
                        value: categoryEntry.value.toDouble(),
                        color: colors[index],
                        radius: 35,
                        showTitle: false,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // カテゴリリスト
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final categoryEntry = entry.value;
                    final categoryName = categoryNames[categoryEntry.key] ?? categoryEntry.key;
                    final minutes = categoryEntry.value;
                    final percent = (minutes / totalMinutes * 100).round();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$percent% ($minutes分)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _generateCategoryColors(int count) {
    final colors = [
      const Color(0xFFFF6B9D), // ピンク
      const Color(0xFF4A90E2), // ブルー
      const Color(0xFFFFB74D), // オレンジ
      const Color(0xFF81C784), // グリーン
      const Color(0xFFBA68C8), // パープル
      const Color(0xFFFFD54F), // イエロー
      const Color(0xFF64B5F6), // ライトブルー
      const Color(0xFFE57373), // レッド
      const Color(0xFF4DB6AC), // ティール
      const Color(0xFFAED581), // ライムグリーン
    ];
    
    if (count <= colors.length) {
      return colors.sublist(0, count);
    }
    
    // 色が足りない場合は繰り返し
    final result = <Color>[];
    for (int i = 0; i < count; i++) {
      result.add(colors[i % colors.length]);
    }
    return result;
  }

  Future<Map<String, String>> _getCategoryNames(AppLocalizations l) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final defaultCategories = {
        'cooking': l.categoryCooking,
        'cleaning': l.categoryCleaning,
        'laundry': l.categoryLaundry,
        'dishes': l.categoryDishes,
        'shopping': l.categoryShopping,
        'childcare': l.categoryChildcare,
        'other': l.other,
      };

      final customSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('customCategories')
          .get();

      final customCategories = <String, String>{};
      for (var doc in customSnapshot.docs) {
        final data = doc.data();
        customCategories[doc.id] = data['name'] as String? ?? doc.id;
      }

      return {...defaultCategories, ...customCategories};
    } catch (e) {
      debugPrint('❌ [CategoryNames] エラー: $e');
      return {};
    }
  }

  /// パートナー招待案内ウィジェット
  Widget _buildPartnerInviteAnnouncement(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FamicaColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamicaColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: FamicaColors.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            l.chartInvitePartner,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.chartInvitePartnerDesc,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              l.chartNoDataYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.chartKeepRecording,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
