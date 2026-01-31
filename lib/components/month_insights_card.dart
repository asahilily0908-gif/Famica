import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// 今月の気づきカード
/// 温かい共感的メッセージカードとしてデザイン
class MonthInsightsCard extends StatelessWidget {
  const MonthInsightsCard({
    super.key,
    required this.householdId,
  });

  final String householdId;

  @override
  Widget build(BuildContext context) {
    // 今月の月フォーマット（yyyy-MM）
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now).trim();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('insights')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snap.hasError) {
          return const SizedBox.shrink();
        }

        // クライアント側でフィルタリング
        final allDocs = snap.data?.docs ?? [];
        
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isDemo = data['isDemo'] as bool? ?? false;
          final month = (data['month'] as String? ?? '').trim();
          return !isDemo && month == currentMonth;
        }).toList();

        if (docs.isEmpty) {
          // データがない場合は表示しない
          return const SizedBox.shrink();
        }

        // subtypeでグループ化
        final suggestions = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['subtype'] as String? ?? 'suggestion') == 'suggestion';
        }).toList();

        final highlights = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['subtype'] as String? ?? '') == 'highlight';
        }).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8FA), // 淡いピンク
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    '提案',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A1F63),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 仕切り線
              Container(
                height: 1,
                color: const Color(0xFFF2E6EF),
              ),
              const SizedBox(height: 16),

              // 提案セクション
              if (suggestions.isNotEmpty) ...[
                const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      '提案',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A1F63),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...suggestions.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final text = data['text'] as String? ?? '';
                  if (text.isEmpty) return const SizedBox.shrink();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF4A1F63),
                      ),
                    ),
                  );
                }),
              ],

              // ハイライトセクション
              if (highlights.isNotEmpty) ...[
                if (suggestions.isNotEmpty) const SizedBox(height: 8),
                const Row(
                  children: [
                    Text('🕊️', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'ハイライト',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A1F63),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...highlights.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final text = data['text'] as String? ?? '';
                  if (text.isEmpty) return const SizedBox.shrink();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF4A1F63),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
