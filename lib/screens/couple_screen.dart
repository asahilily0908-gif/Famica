import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart' as pie;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/gratitude_service.dart';
import '../constants/famica_colors.dart';
import '../widgets/six_month_chart_widget.dart';
import '../widgets/famica_header.dart';
import '../widgets/common_context_menu.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/partner_invite_card.dart';
import 'gratitude_history_screen.dart';

/// Famica ホーム画面（今月のふたり）
class CoupleScreen extends StatefulWidget {
  const CoupleScreen({super.key});

  @override
  State<CoupleScreen> createState() => _CoupleScreenState();
}

class _CoupleScreenState extends State<CoupleScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              _buildHeader(),

              _buildPieChartSection(month),
              
              // 💖 感謝を送る セクション（円グラフ直下に移動）
              _buildGratitudeSection(),
              
              _buildMemberStatsSection(month),
              
              // 6ヶ月の推移
              _buildSixMonthChartSection(),
              
              // 💡 行動のヒント（白カードでラップ）
              Container(
                margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
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
                    Row(
                      children: [
                        const Text(
                          '💡',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '行動のヒント',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const DailyTipCard(),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー（Famicaタイトル）
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FamicaHeader(
            fontSize: 32,
            showSubtitle: false,
          ),
          const SizedBox(height: 4),
          Text(
            'ふたりのがんばりを10秒で記録',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 円グラフ＋総回数セクション
  Widget _buildPieChartSection(String month) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firestoreService.getMonthlyStats(month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? {};
        final myName = stats['myName'] ?? 'あなた';
        final partnerName = stats['partnerName'] ?? 'パートナー';
        final myCount = stats['myCount'] ?? 0;
        final partnerCount = stats['partnerCount'] ?? 0;
        final totalCount = myCount + partnerCount;
        
        // 記録回数ベースで割合を計算
        final myCountPercent = totalCount > 0 ? (myCount / totalCount * 100).round() : 50;
        final partnerCountPercent = totalCount > 0 ? (partnerCount / totalCount * 100).round() : 50;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 円グラフ（pie_chart パッケージ使用 - リングチャート）
              // サイズを85%に縮小（200 → 170px）
              Center(
                child: Container(
                  width: 170,
                  height: 170,
                  child: pie.PieChart(
                    dataMap: {
                      myName: myCountPercent.toDouble(),
                      partnerName: partnerCountPercent.toDouble(),
                    },
                    chartType: pie.ChartType.ring,
                    ringStrokeWidth: 29,
                    animationDuration: const Duration(milliseconds: 800),
                    chartLegendSpacing: 32,
                    chartRadius: 170,
                    colorList: const [
                      Color(0xFFFF69B4), // ピンク
                      Color(0xFF64B5F6), // ブルー
                    ],
                    legendOptions: const pie.LegendOptions(
                      showLegends: false,
                    ),
                    chartValuesOptions: const pie.ChartValuesOptions(
                      showChartValues: false,
                    ),
                    centerWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '今月',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalCount回',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: FamicaColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ラベル
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('🩷 $myName', myCountPercent, const Color(0xFFFF69B4)),
                  const SizedBox(width: 24),
                  const Text('／', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 24),
                  _buildLegendItem('💙 $partnerName', partnerCountPercent, const Color(0xFF64B5F6)),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, int percent, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 感謝セクション
  Widget _buildGratitudeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 感謝メッセージ送信カード
        _buildSendThanksCard(),
        
        // Divider
        const Divider(
          color: Colors.black12,
          thickness: 0.5,
          height: 24,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }

  /// 感謝メッセージ送信カード
  Widget _buildSendThanksCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: GestureDetector(
        onTap: () => _showSendThanksDialog(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FamicaColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '✉️',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '感謝メッセージを送る',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'パートナーに感謝の気持ちを伝えましょう',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 感謝カード送信ボタンカード（未読件数表示付き）
  Widget _buildThanksCardButton() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<int>(
      future: _firestoreService.getUnreadGratitudeCount(user.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        // 未読がある場合は未読通知カードを表示
        if (unreadCount > 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GratitudeHistoryScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '💌',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '感謝カードが届いています',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: FamicaColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'タップして読む',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // 未読がない場合は送信ボタンを表示
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showSendThanksDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FamicaColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '🩷',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '感謝メッセージを送る',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: FamicaColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'パートナーに感謝の気持ちを伝えましょう',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// あなた／パートナーセクション
  Widget _buildMemberStatsSection(String month) {
    // パートナー招待状態を監視
    return StreamBuilder<bool>(
      stream: _watchPartnerInvited(),
      builder: (context, inviteSnapshot) {
        final isInvited = inviteSnapshot.data ?? false;

        return StreamBuilder<Map<String, dynamic>>(
          stream: _firestoreService.getMonthlyStats(month),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final stats = snapshot.data ?? {};
            final myName = stats['myName'] ?? 'あなた';
            final partnerName = stats['partnerName'] ?? 'パートナー';
            final myCount = stats['myCount'] ?? 0;
            final partnerCount = stats['partnerCount'] ?? 0;
            final myTime = stats['myTime'] ?? 0;
            final partnerTime = stats['partnerTime'] ?? 0;

            return FutureBuilder<Map<String, dynamic>>(
              future: Future.wait([
                _getMemberUids(),
                _getMemberTasksSummary(month),
                _getMemberCosts(month),
              ]).then((results) => {
                'uids': results[0],
                'tasks': results[1],
                'costs': results[2],
              }),
              builder: (context, futureSnapshot) {
                final data = futureSnapshot.data ?? {};
                final uidsData = data['uids'] as Map<String, String?>? ?? {};
                final tasksData = data['tasks'] as Map<String, dynamic>? ?? {};
                final costsData = data['costs'] as Map<String, dynamic>? ?? {};
                
                final myUid = uidsData['myUid'];
                final partnerUid = uidsData['partnerUid'];
                
                // 型キャストエラー修正: Map.from()を使用して安全に変換
                final myTasksRaw = tasksData['myTasks'];
                final myTasks = myTasksRaw is Map
                    ? Map<String, Map<String, dynamic>>.from(
                        myTasksRaw.map((key, value) => MapEntry(
                          key.toString(),
                          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{}
                        ))
                      )
                    : <String, Map<String, dynamic>>{};
                
                final partnerTasksRaw = tasksData['partnerTasks'];
                final partnerTasks = partnerTasksRaw is Map
                    ? Map<String, Map<String, dynamic>>.from(
                        partnerTasksRaw.map((key, value) => MapEntry(
                          key.toString(),
                          value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{}
                        ))
                      )
                    : <String, Map<String, dynamic>>{};
                
                final myCost = costsData['myCost'] as int? ?? 0;
                final partnerCost = costsData['partnerCost'] as int? ?? 0;
                final myCostDetails = costsData['myCostDetails'] as List<Map<String, dynamic>>? ?? [];
                final partnerCostDetails = costsData['partnerCostDetails'] as List<Map<String, dynamic>>? ?? [];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // 自分のカードは常に表示
                      _buildMemberCard(
                        '🩷 $myName',
                        myCount,
                        myTime,
                        const Color(0xFFFF69B4),
                        myCount / (myCount + partnerCount + 1),
                        myTasks,
                        myUid,
                        myCost,
                        myCostDetails,
                      ),
                      const SizedBox(height: 12),
                      // パートナーが招待されている場合はパートナーカード、未招待の場合は招待カード
                      if (isInvited)
                        _buildMemberCard(
                          '💙 $partnerName',
                          partnerCount,
                          partnerTime,
                          const Color(0xFF64B5F6),
                          partnerCount / (myCount + partnerCount + 1),
                          partnerTasks,
                          partnerUid,
                          partnerCost,
                          partnerCostDetails,
                        )
                      else
                        const PartnerInviteCard(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMemberCard(
    String name,
    int count,
    int minutes,
    Color color,
    double progress,
    Map<String, Map<String, dynamic>> tasks,
    String? userId,
    int cost,
    List<Map<String, dynamic>> costDetails,
  ) {
    final hours = (minutes / 60).floor();
    final mins = minutes % 60;

    // タスクを時間が多い順にソート
    final sortedTasks = tasks.entries.toList()
      ..sort((a, b) => (b.value['time'] as int).compareTo(a.value['time'] as int));
    
    // 最大5件まで表示
    final displayTasks = sortedTasks.take(5).toList();

    return Container(
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
          // 🩷を確実に表示するため、絵文字と名前を分離して表示
          Row(
            children: [
              // 絵文字部分（フォントサイズを大きめに）
              Text(
                name.startsWith('🩷') || name.startsWith('💙') 
                    ? name.substring(0, 2) 
                    : '',
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              // 名前部分
              Text(
                name.startsWith('🩷') || name.startsWith('💙')
                    ? name.substring(3) // "🩷 " or "💙 " の後
                    : name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: FamicaColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 記録回数',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count回',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: FamicaColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏰ 合計時間',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hours時間$mins分',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: FamicaColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💗 もらった感謝',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    if (userId != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                          final thanks = (data['totalThanksReceived'] ?? 0) as int;
                          final title = (data['title'] ?? '') as String;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$thanks回',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: FamicaColors.textDark,
                                ),
                              ),
                              if (title.isNotEmpty)
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    else
                      const Text(
                        '0回',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: FamicaColors.textDark,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (displayTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // カテゴリタイトル帯
            Row(
              children: [
                const Text(
                  '📂',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '今月の家事内訳（カテゴリ別の合計）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...displayTasks.map((entry) {
              final task = entry.key;
              final time = entry.value['time'] as int;
              final taskCount = entry.value['count'] as int;
              final taskHours = (time / 60).floor();
              final taskMins = time % 60;
              final timeLabel = taskHours > 0
                  ? '$taskHours時間$taskMins分'
                  : '$taskMins分';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Text(
                  '✅ $task　$timeLabel（$taskCount回）',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    height: 1.4,
                  ),
                ),
              );
            }),
          ],
          // コストセクション（家事の内訳の下に追加）
          if (cost > 0 || costDetails.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // コストタイトル帯
            Row(
              children: [
                const Text(
                  '💰',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '今月のコスト（支出）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 合計金額（大きく強調表示）
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    '合計',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '¥${NumberFormat('#,###').format(cost)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            // 用途別の支出明細（上位5件）
            if (costDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...costDetails.map((detail) {
                final amount = detail['amount'] as int? ?? 0;
                final usage = detail['usage'] as String? ?? '用途未記入';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          usage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${NumberFormat('#,###').format(amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  /// メンバーごとのタスク集計を取得
  Future<Map<String, dynamic>> _getMemberTasksSummary(String month) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'myTasks': {}, 'partnerTasks': {}};
      }

      final householdId = await _firestoreService.getCurrentUserHouseholdId();
      if (householdId == null) {
        return {'myTasks': {}, 'partnerTasks': {}};
      }

      // 今月の全記録を取得
      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('records')
          .where('month', isEqualTo: month)
          .get();

      final myTasks = <String, Map<String, dynamic>>{};
      final partnerTasks = <String, Map<String, dynamic>>{};

      for (var doc in recordsSnapshot.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String?;
        final memberName = data['memberName'] as String?;
        
        // taskとcategoryの両方をチェック
        final task = data['task'] as String? ?? data['category'] as String? ?? '未分類';
        final timeMinutes = data['timeMinutes'] as int? ?? 0;

        // メンバー判定
        final isMyRecord = memberId == user.uid || 
                          memberName == user.displayName ||
                          (user.email != null && memberName?.contains(user.email!.split('@')[0]) == true);
        
        final targetMap = isMyRecord ? myTasks : partnerTasks;

        if (!targetMap.containsKey(task)) {
          targetMap[task] = {'count': 0, 'time': 0};
        }

        targetMap[task] = {
          'count': (targetMap[task]!['count'] as int) + 1,
          'time': (targetMap[task]!['time'] as int) + timeMinutes,
        };
      }

      return {'myTasks': myTasks, 'partnerTasks': partnerTasks};
    } catch (e) {
      return {'myTasks': {}, 'partnerTasks': {}};
    }
  }

  Future<Map<String, String?>> _getMemberUids() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'myUid': null, 'partnerUid': null};

    final householdId = await _firestoreService.getCurrentUserHouseholdId();
    if (householdId == null) return {'myUid': user.uid, 'partnerUid': null};

    try {
      final members = await _firestoreService.getHouseholdMembers();
      final partnerMember = members.firstWhere(
        (m) => m['uid'] != user.uid,
        orElse: () => {'uid': null},
      );

      return {
        'myUid': user.uid,
        'partnerUid': partnerMember['uid'] as String?,
      };
    } catch (e) {
      return {'myUid': user.uid, 'partnerUid': null};
    }
  }

  /// パートナー招待状態を監視するStream（members.lengthで判定）
  Stream<bool> _watchPartnerInvited() async* {
    try {
      final householdId = await _firestoreService.getCurrentUserHouseholdId();
      if (householdId == null) {
        yield false;
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return false;
            final data = doc.data();
            final members = (data?['members'] as List?) ?? [];
            return members.length >= 2;
          });
    } catch (e) {
      debugPrint('❌ [PartnerInvite] エラー: $e');
      yield false;
    }
  }

  /// メンバーごとのコスト集計と明細を取得（用途ごとに合算）
  Future<Map<String, dynamic>> _getMemberCosts(String month) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'myCost': 0,
          'partnerCost': 0,
          'myCostDetails': <Map<String, dynamic>>[],
          'partnerCostDetails': <Map<String, dynamic>>[],
        };
      }

      final householdId = await _firestoreService.getCurrentUserHouseholdId();
      if (householdId == null) {
        return {
          'myCost': 0,
          'partnerCost': 0,
          'myCostDetails': <Map<String, dynamic>>[],
          'partnerCostDetails': <Map<String, dynamic>>[],
        };
      }

      // 今月のコストを取得
      final costsSnapshot = await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('costs')
          .where('month', isEqualTo: month)
          .get();

      int myCost = 0;
      int partnerCost = 0;
      
      // 用途ごとに金額を集計するためのMap
      final Map<String, int> myUsageMap = {};
      final Map<String, int> partnerUsageMap = {};

      for (var doc in costsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? '';
        final amount = data['amount'] as int? ?? 0;
        final usage = data['usage'] as String? ?? data['memo'] as String? ?? '用途未記入';

        if (userId == user.uid) {
          myCost += amount;
          myUsageMap[usage] = (myUsageMap[usage] ?? 0) + amount;
        } else {
          partnerCost += amount;
          partnerUsageMap[usage] = (partnerUsageMap[usage] ?? 0) + amount;
        }
      }

      // 合計金額が大きい順にソートして上位5件を取得
      final myCostDetails = myUsageMap.entries
          .map((e) => {'usage': e.key, 'amount': e.value})
          .toList()
        ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
      
      final partnerCostDetails = partnerUsageMap.entries
          .map((e) => {'usage': e.key, 'amount': e.value})
          .toList()
        ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));

      return {
        'myCost': myCost,
        'partnerCost': partnerCost,
        'myCostDetails': myCostDetails.take(5).toList(),
        'partnerCostDetails': partnerCostDetails.take(5).toList(),
      };
    } catch (e) {
      return {
        'myCost': 0,
        'partnerCost': 0,
        'myCostDetails': <Map<String, dynamic>>[],
        'partnerCostDetails': <Map<String, dynamic>>[],
      };
    }
  }

  /// ユーザー別のカテゴリ内訳を取得
  Future<Map<String, Map<String, int>>> _getUserBreakdown() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      final householdId = await _firestoreService.getCurrentUserHouseholdId();
      if (householdId == null) return {};

      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // 今月の全記録を取得
      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('records')
          .where('month', isEqualTo: month)
          .get();

      // ユーザーごとにカテゴリ別の時間を集計
      final Map<String, Map<String, int>> userData = {};

      for (var doc in recordsSnapshot.docs) {
        final data = doc.data();
        final categoryId = data['categoryId'] as String? ?? data['category'] as String? ?? '未分類';
        final userId = data['memberId'] as String? ?? data['userId'] as String? ?? '';
        final minutes = data['timeMinutes'] as int? ?? 0;

        if (!userData.containsKey(userId)) {
          userData[userId] = {};
        }

        userData[userId]![categoryId] = (userData[userId]![categoryId] ?? 0) + minutes;
      }

      return userData;
    } catch (e) {
      debugPrint('❌ [UserBreakdown] エラー: $e');
      return {};
    }
  }

  /// 6ヶ月グラフセクション（全ユーザー対象）
  Widget _buildSixMonthChartSection() {
    // パートナー招待状態を監視
    return StreamBuilder<bool>(
      stream: _watchPartnerInvited(),
      builder: (context, inviteSnapshot) {
        final isInvited = inviteSnapshot.data ?? false;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _firestoreService.getSixMonthsData(),
          builder: (context, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final monthsData = dataSnapshot.data ?? [];
            
            return StreamBuilder<Map<String, dynamic>>(
              stream: _firestoreService.getMonthlyStats(
                '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}'
              ),
              builder: (context, statsSnapshot) {
                final stats = statsSnapshot.data ?? {};
                final myName = stats['myName'] ?? 'あなた';
                final partnerName = stats['partnerName'] ?? 'パートナー';

                return FutureBuilder<Map<String, Map<String, int>>>(
                  future: _getUserBreakdown(),
                  builder: (context, breakdownSnapshot) {
                    if (breakdownSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final userBreakdownData = breakdownSnapshot.data ?? {};

                    return SixMonthChartWidget(
                      monthlyData: monthsData,
                      myName: myName,
                      partnerName: partnerName,
                      userBreakdownData: userBreakdownData,
                      isPartnerInvited: isInvited,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// 💡提案セクション（無料プラン・ルールベース）
  Widget _buildSuggestionsSection(String month) {
    return FutureBuilder<List<String>>(
      future: _generateRuleBasedSuggestions(month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final suggestions = snapshot.data ?? [];
        if (suggestions.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '今月の提案はまだありません💡',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16),
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
              const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    '提案',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>> _generateRuleBasedSuggestions(String month) async {
    final stats = await _firestoreService.getMonthlyStats(month).first;
    final suggestions = <String>[];

    final myPercent = stats['myPercent'] ?? 50;
    final partnerPercent = stats['partnerPercent'] ?? 50;

    // ルール1: 負担が偏っている場合
    if (myPercent >= 70) {
      suggestions.add('あなたに少し負担が偏っているようです。\nたまにはパートナーに任せてリラックスしてもいいかも☺️');
    } else if (partnerPercent >= 70) {
      suggestions.add('パートナーに少し負担が偏っているようです。\n感謝の気持ちを伝えてみましょう💕');
    }

    // ルール2: バランスが良い場合
    if (myPercent >= 40 && myPercent <= 60) {
      suggestions.add('料理のバランスが良いですね！\nこの調子で続けていきましょう✨');
    }

    return suggestions.take(2).toList();
  }

  /// 感謝カード送信ダイアログを表示
  Future<void> _showSendThanksDialog(BuildContext context) async {
    try {
      final members = await _firestoreService.getHouseholdMembers();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final partner = members.firstWhere(
        (m) => m['uid'] != user.uid,
        orElse: () => {},
      );

      if (partner.isEmpty || partner['uid'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('パートナーが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => _ThanksCardDialog(
            partnerName: partner['name'] ?? 'パートナー',
            partnerUid: partner['uid'],
            firestoreService: _firestoreService,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Thanks] エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ThanksCardDialog extends StatefulWidget {
  final String partnerName;
  final String partnerUid;
  final FirestoreService firestoreService;

  const _ThanksCardDialog({
    required this.partnerName,
    required this.partnerUid,
    required this.firestoreService,
  });

  @override
  State<_ThanksCardDialog> createState() => _ThanksCardDialogState();
}

class _ThanksCardDialogState extends State<_ThanksCardDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedModalContainer(
      isDialog: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              children: [
                const Text(
                  '💗',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  '感謝カードを送る',
                  style: UnifiedModalStyles.titleStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 送り先
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: UnifiedModalStyles.primaryPink.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: UnifiedModalStyles.pinkBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '送り先：',
                    style: UnifiedModalStyles.labelStyle,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.partnerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: UnifiedModalStyles.primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // メッセージ入力
            const Text(
              'メッセージ',
              style: UnifiedModalStyles.labelStyle,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: TextField(
                controller: _messageController,
                maxLines: null,
                expands: true,
                maxLength: 100,
                textAlignVertical: TextAlignVertical.top,
                decoration: UnifiedModalStyles.textFieldDecoration(
                  hintText: '例：いつも洗い物してくれてありがとう😊',
                ),
                contextMenuBuilder: buildFamicaContextMenu,
              ),
            ),
            const SizedBox(height: 32),
            
            // 送信ボタン
            UnifiedSaveButton(
              text: '送信',
              onPressed: _sendThanksCard,
              isLoading: _isSending,
            ),
            const SizedBox(height: 12),
            UnifiedCancelButton(),
          ],
        ),
      ),
    );
  }

  Future<void> _sendThanksCard() async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メッセージを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      // 感謝カードを送信
      await widget.firestoreService.sendThanksCard(
        toUserId: widget.partnerUid,
        message: message,
      );
      
      if (!mounted) return;
      
      // ダイアログを閉じる
      Navigator.pop(context);
      
      // 完了メッセージを表示
      debugPrint('✅ [Gratitude] 感謝を送信しました');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💌 感謝カードを送信しました'),
            backgroundColor: UnifiedModalStyles.primaryPink,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Gratitude] 送信エラー: $e');
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
