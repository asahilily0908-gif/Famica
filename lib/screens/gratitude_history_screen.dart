import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/gratitude_service.dart';
import '../constants/famica_colors.dart';

/// 📮 貰った感謝一覧画面
class GratitudeHistoryScreen extends StatefulWidget {
  const GratitudeHistoryScreen({super.key});

  @override
  State<GratitudeHistoryScreen> createState() => _GratitudeHistoryScreenState();
}

class _GratitudeHistoryScreenState extends State<GratitudeHistoryScreen> {
  final GratitudeService _gratitudeService = GratitudeService();
  
  @override
  void initState() {
    super.initState();
    // 画面を開いた時に全ての未読メッセージを既読にする
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _gratitudeService.markAllAsRead();
    } catch (e) {
      print('既読処理エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '📮 貰った感謝一覧',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FamicaColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _gratitudeService.fetchMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📭', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    '感謝カードはまだありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final doc = messages[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final fromName = data['fromName'] as String? ?? '送信者';
              final toName = data['toName'] as String? ?? 'あなた';
              final message = data['message'] as String? ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final isRead = data['isRead'] as bool? ?? false;
              
              return _buildMessageTile(
                fromName: fromName,
                toName: toName,
                message: message,
                timestamp: timestamp,
                isRead: isRead,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageTile({
    required String fromName,
    required String toName,
    required String message,
    required Timestamp? timestamp,
    required bool isRead,
  }) {
    final dateStr = timestamp != null
        ? DateFormat('yyyy/MM/dd HH:mm').format(timestamp.toDate())
        : '';

    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Text('💌', style: TextStyle(fontSize: 24)),
        title: Text(
          '$fromName → $toName',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: FamicaColors.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: FamicaColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        tileColor: isRead ? Colors.white : Colors.pink.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
