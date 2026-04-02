import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../constants/famica_colors.dart';
import '../widgets/famica_header.dart';
import 'record_list_screen.dart';
import 'category_customize_screen.dart';
import 'cost_record_screen.dart';

/// Famica v3.0 クイック記録画面（UIリファレンス準拠）
class QuickRecordScreen extends StatefulWidget {
  const QuickRecordScreen({super.key});

  @override
  State<QuickRecordScreen> createState() => _QuickRecordScreenState();
}

class _QuickRecordScreenState extends State<QuickRecordScreen> {
  final _firestoreService = FirestoreService();
  bool _isLoading = true;

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 初期化処理
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
    return Container(
      decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: FamicaColors.accent),
        ),
      ),
    );
    }

    return Container(
      decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              _buildHeader(),

              // 今日のがんばり
              _buildTodayStats(),

              // クイック記録
              _buildQuickRecordSection(),

              // コスト記録ボタン
              _buildCostRecordButton(),

              // 最近の記録
              _buildRecentRecords(),

              const SizedBox(height: 80), // ボトムナビ用スペース
            ],
          ),
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
            l.appTagline,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _firestoreService.getTodayStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? {};
        final myCount = stats['myCount'] ?? 0;
        final partnerCount = stats['partnerCount'] ?? 0;
        final myName = stats['myName'] ?? l.you;
        final partnerName = stats['partnerName'] ?? l.partner;

        final now = DateTime.now();
        final dateStr = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.quickRecordTodayEffort,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB6C8), Color(0xFFFF8FAB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF75B2).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            l.quickRecordCountTimes(myCount),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            myName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF90CAF9), Color(0xFF5A8BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A8BFF).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            l.quickRecordCountTimes(partnerCount),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partnerName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickRecordSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.quickRecord,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  print('📝 [QuickRecord] カテゴリ編集画面へ遷移');
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryCustomizeScreen(),
                    ),
                  );
                  // StreamBuilderが自動的に更新されるため、setStateは不要
                  print('🔙 [QuickRecord] カテゴリ編集画面から戻った（Streamが自動更新）');
                },
                child: Text(
                  l.quickRecordPanelEdit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: FamicaColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickButtons(),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getUserCustomCategoriesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(l.quickRecordError(snapshot.error.toString())),
          );
        }

        // カスタムカテゴリまたはデフォルトカテゴリを取得
        final categories = snapshot.data ?? [];

        // 🔍 DEBUG LOG: Stream購読情報
        print('📡 [STREAM] クイック記録画面 StreamBuilder rebuild');
        print('📡 [STREAM] カテゴリ総数: ${categories.length}件');
        print('📡 [STREAM] カテゴリID一覧:');
        for (var cat in categories) {
          final id = cat['id'] as String? ?? '';
          final name = cat['name'] as String? ?? '';
          final isVisible = cat['isVisible'] as bool? ?? true;
          print('  - id: $id, name: $name, isVisible: $isVisible');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildQuickButton(
              emoji: category['emoji'] as String? ?? '📝',
              task: category['name'] as String? ?? l.task,
              minutes: category['defaultMinutes'] as int? ?? 30,
              color: Colors.white,
            );
          },
        );
      },
    );
  }


  Widget _buildQuickButton({
    required String emoji,
    required String task,
    required int minutes,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _showTimeSelectionDialog(task, minutes),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              task,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l.quickRecordMinutes(minutes),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentRecords() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.quickRecordRecentRecords,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecordListScreen(),
                    ),
                  );
                },
                child: Text(
                  l.quickRecordSeeAll,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: FamicaColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getRecentRecords(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(l.quickRecordError(snapshot.error.toString())),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      l.quickRecordNoRecords,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }

              final records = snapshot.data!.docs;

              return Column(
                children: records.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildRecentRecordItem(
                      data['task'] ?? l.task,
                      data['memberName'] ?? l.quickRecordNoName,
                      data['timeMinutes'] ?? 0,
                      data['thankedBy']?.length ?? 0,
                      data['createdAt'] as Timestamp?,
                      recordId: doc.id,
                      thankedBy: data['thankedBy'] as List?,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getTaskEmoji(String task) {
    final taskLower = task.toLowerCase();
    if (taskLower.contains('料理') || taskLower.contains('cooking')) return '🍳';
    if (taskLower.contains('洗濯') || taskLower.contains('laundry')) return '🧺';
    if (taskLower.contains('掃除') || taskLower.contains('clean')) return '🧹';
    if (taskLower.contains('買い物') || taskLower.contains('shop')) return '🛒';
    if (taskLower.contains('ゴミ') || taskLower.contains('trash')) return '🗑️';
    if (taskLower.contains('水回り') || taskLower.contains('water')) return '💧';
    return '💡';
  }

  Widget _buildRecentRecordItem(
    String task,
    String memberName,
    int timeMinutes,
    int thanksCount,
    Timestamp? createdAt,
    {String? recordId, List? thankedBy}
  ) {
    // 経過時間を計算
    String timeAgo = l.now;
    if (createdAt != null) {
      final now = DateTime.now();
      final recordTime = createdAt.toDate();
      final diff = now.difference(recordTime);

      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}日前';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}時間前';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}分前';
      }
    }

    final emoji = _getTaskEmoji(task);

    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? '';
    final hasThanked = thankedBy?.contains(currentUserId) ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FamicaColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$memberName • $timeAgo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            l.quickRecordMinutes(timeMinutes),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (recordId != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.favorite,
                color: hasThanked ? Colors.pinkAccent : Colors.grey[400],
                size: 20,
              ),
              onPressed: hasThanked ? null : () async {
                try {
                  // recordのmemberIdを取得して通知を送信
                  final recordDoc = await FirebaseFirestore.instance
                      .collection('households')
                      .doc(await _firestoreService.getCurrentUserHouseholdId())
                      .collection('records')
                      .doc(recordId)
                      .get();

                  final toUserId = recordDoc.data()?['memberId'] as String? ?? '';

                  await _firestoreService.addThanks(recordId, toUserId: toUserId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.quickRecordThanks),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.quickRecordError(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showTimeSelectionDialog(String task, int defaultMinutes) {
    final timeOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120];
    final emoji = _getTaskEmoji(task);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernTimeSelectionSheet(
        task: task,
        emoji: emoji,
        timeOptions: timeOptions,
        defaultMinutes: defaultMinutes,
        onTimeSelected: (minutes) async {
          Navigator.pop(context);
          await _createRecord(task, minutes);
        },
      ),
    );
  }

  Future<void> _createRecord(String task, int timeMinutes) async {
    try {
      // カスタムカテゴリ名をcategoryとtaskの両方に保存
      await _firestoreService.createRecord(
        category: task,  // カスタムカテゴリ名
        task: task,      // カスタムカテゴリ名
        timeMinutes: timeMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.quickRecordAdded),
            backgroundColor: FamicaColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.quickRecordError(e.toString())),
            backgroundColor: FamicaColors.error,
          ),
        );
      }
    }
  }

  Widget _buildCostRecordButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const CostRecordScreen(),
          );

          // モーダルから戻ってきたら画面を更新
          if (result == true && mounted) {
            setState(() {});
          }
        },
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
              const Text('💰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                l.quickRecordCostRecord,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// モダンな時間選択シート（2025年風デザイン）
class _ModernTimeSelectionSheet extends StatefulWidget {
  final String task;
  final String emoji;
  final List<int> timeOptions;
  final int defaultMinutes;
  final Function(int) onTimeSelected;

  const _ModernTimeSelectionSheet({
    required this.task,
    required this.emoji,
    required this.timeOptions,
    required this.defaultMinutes,
    required this.onTimeSelected,
  });

  @override
  State<_ModernTimeSelectionSheet> createState() => _ModernTimeSelectionSheetState();
}

class _ModernTimeSelectionSheetState extends State<_ModernTimeSelectionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedMinutes;

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.defaultMinutes;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 400),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ドラッグハンドル
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    // タスクアイコン
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFFD9E8),
                            const Color(0xFFFFEAF2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: FamicaColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // タイトル
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.quickRecordSelectTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 閉じるボタン
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 時間リスト
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: widget.timeOptions.length,
                  itemBuilder: (context, index) {
                    final minutes = widget.timeOptions[index];
                    final isSelected = minutes == _selectedMinutes;

                    return _TimeOptionItem(
                      minutes: minutes,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedMinutes = minutes;
                        });
                        Future.delayed(const Duration(milliseconds: 90), () {
                          widget.onTimeSelected(minutes);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// 時間オプションアイテム
class _TimeOptionItem extends StatefulWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeOptionItem({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TimeOptionItem> createState() => _TimeOptionItemState();
}

class _TimeOptionItemState extends State<_TimeOptionItem> {
  bool _isPressed = false;

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _isPressed ? 0.97 : 1.0,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFFFD9E8),
                        Color(0xFFFFEAF2),
                      ],
                    )
                  : null,
              color: widget.isSelected ? null : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x11000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.isSelected) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4F9F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    l.quickRecordMinutes(widget.minutes),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected
                          ? const Color(0xFFFF4F9F)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Icon(
                    Icons.chevron_right,
                    color: const Color(0xFFFF4F9F).withOpacity(0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
