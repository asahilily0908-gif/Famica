import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../constants/famica_colors.dart';

/// Famica v3.0 記録一覧画面
class RecordListScreen extends StatefulWidget {
  final bool showAllRecords;
  
  const RecordListScreen({
    super.key,
    this.showAllRecords = false,
  });

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  final _firestoreService = FirestoreService();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<String> _availableMonths = [];
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _showAll = widget.showAllRecords;
    _generateMonthList();
  }

  void _generateMonthList() {
    final now = DateTime.now();
    final months = <String>['すべて']; // 「すべて」オプションを追加
    
    // 過去12ヶ月分の月を生成
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('yyyy-MM').format(month));
    }
    
    setState(() {
      _availableMonths = months;
      if (_showAll) {
        _selectedMonth = 'すべて';
      }
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '記録一覧',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: Column(
        children: [
          // 月選択ドロップダウン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: FamicaColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          isExpanded: true,
                          items: _availableMonths.map((month) {
                            return DropdownMenuItem(
                              value: month,
                              child: Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMonth = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // サマリーとリスト
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedMonth == 'すべて'
                  ? _firestoreService.getAllRecords()
                  : _firestoreService.getMonthlyRecords(_selectedMonth),
              builder: (context, recordsSnapshot) {
                if (recordsSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: FamicaColors.error),
                        const SizedBox(height: 16),
                        Text('エラー: ${recordsSnapshot.error}'),
                      ],
                    ),
                  );
                }

                if (recordsSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: FamicaColors.accent,
                    ),
                  );
                }

                final records = recordsSnapshot.data?.docs ?? [];

                // 時間の合計を計算
                int totalMinutes = 0;
                for (var doc in records) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalMinutes += (data['timeMinutes'] as int?) ?? 0;
                }

                // costsコレクションから総コストを取得
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getRecentCosts(limit: 1000),
                  builder: (context, costsSnapshot) {
                    int totalCost = 0;

                    if (costsSnapshot.hasData) {
                      final costs = costsSnapshot.data?.docs ?? [];
                      
                      // 選択された月でフィルタリング
                      for (var doc in costs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final month = data['month'] as String? ?? '';
                        final amount = data['amount'] as int? ?? 0;

                        // 「すべて」または選択された月に一致する場合
                        if (_selectedMonth == 'すべて' || month == _selectedMonth) {
                          totalCost += amount;
                        }
                      }
                    }

                    return _buildContent(records, totalMinutes, totalCost);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(List<QueryDocumentSnapshot> records, int totalMinutes, int totalCost) {
    return Column(
      children: [
        // サマリーカード
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: Card(
              color: FamicaColors.accent.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: 32, 
                          color: FamicaColors.accent,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(totalMinutes / 60).toStringAsFixed(1)}時間',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: FamicaColors.text,
                          ),
                        ),
                        Text(
                          '($totalMinutes分)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: FamicaColors.accent.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_money, 
                          size: 32, 
                          color: FamicaColors.thanks,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¥${NumberFormat('#,###').format(totalCost)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: FamicaColors.text,
                          ),
                        ),
                        Text(
                          '総コスト',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        const SizedBox(height: 16),

        // 記録リスト
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '記録がありません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final doc = records[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final category = data['category'] as String? ?? '';
                    final task = data['task'] as String? ?? '';
                    final timeMinutes = data['timeMinutes'] as int? ?? 0;
                    final cost = data['cost'] as int? ?? 0;
                    final note = data['note'] as String? ?? '';
                    final memberName = data['memberName'] as String? ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final thankedBy = List<String>.from(data['thankedBy'] ?? []);
                    
                    String dateStr = '';
                    if (createdAt != null) {
                      dateStr = DateFormat('yyyy/MM/dd HH:mm').format(
                        createdAt.toDate(),
                      );
                    }

                    // アイコンなしのシンプルなカードスタイル
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (thankedBy.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.favorite,
                                    size: 18,
                                    color: Color(0xFFFF5A84),
                                  ),
                                  Text(
                                    ' ${thankedBy.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF5A84),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '$timeMinutes分',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF555555),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (cost > 0) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    '・',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '¥${NumberFormat('#,###').format(cost)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$memberName・$dateStr',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
