import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../constants/famica_colors.dart';

/// アルバム画面（記録・感謝・記念日のタイムライン）
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _householdId;
  AlbumItemType? _selectedFilter;

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadHouseholdId();
  }

  Future<void> _loadHouseholdId() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _householdId = userDoc.data()?['householdId'] as String?;
      });
    } catch (e) {
      debugPrint('❌ householdId取得エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_householdId == null) {
      return Container(
        decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              l.albumTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            l.albumOurAlbum,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<AlbumItemType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Text(l.all),
              ),
              PopupMenuItem(
                value: AlbumItemType.record,
                child: Row(
                  children: [
                    const Text('📝 ', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(l.albumRecordsOnly),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AlbumItemType.thanks,
                child: Row(
                  children: [
                    const Text('❤️ ', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(l.albumGratitudeOnly),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<List<AlbumItem>>(
              stream: _getAlbumItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: FamicaColors.error),
                        const SizedBox(height: 16),
                        Text(l.errorWithMessage(snapshot.error.toString())),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: FamicaColors.accent,
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];

                // フィルター適用
                final items = _selectedFilter == null
                    ? allItems
                    : allItems.where((item) => item.type == _selectedFilter).toList();

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _AlbumCard(item: item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            l.albumNoItems,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.albumNoItemsDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// アルバムアイテムを取得（記録・感謝・記念日）
  Stream<List<AlbumItem>> _getAlbumItems() async* {
    if (_householdId == null) {
      yield [];
      return;
    }

    // recordsStreamをベースに、thanksとmilestonesを非同期取得
    final recordsStream = _firestore
        .collection('households')
        .doc(_householdId)
        .collection('records')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    await for (final recordsSnapshot in recordsStream) {
      final items = <AlbumItem>[];

      // 記録を追加
      for (final doc in recordsSnapshot.docs) {
        final data = doc.data();
        final task = data['task'] ?? l.albumRecord;
        final timeMinutes = data['timeMinutes'] ?? 0;
        final memberName = data['memberName'] ?? '';

        items.add(AlbumItem(
          id: doc.id,
          type: AlbumItemType.record,
          timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          title: task,
          description: '$memberName • $timeMinutes分',
          icon: '📝',
          data: data,
        ));
      }

      // 感謝を取得（非同期なので別途処理）
      try {
        final thanksSnapshot = await _firestore
            .collection('households')
            .doc(_householdId)
            .collection('thanks')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        for (final doc in thanksSnapshot.docs) {
          final data = doc.data();
          items.add(AlbumItem(
            id: doc.id,
            type: AlbumItemType.thanks,
            timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            title: l.albumGratitude,
            description: data['message'] ?? '',
            icon: data['emoji'] ?? '❤️',
            data: data,
          ));
        }
      } catch (e) {
        debugPrint('❌ 感謝取得エラー: $e');
      }


      // 日付順にソート
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      yield items;
    }
  }
}

/// アルバムアイテムタイプ
enum AlbumItemType {
  record,
  thanks,
}

/// アルバムアイテムモデル
class AlbumItem {
  final String id;
  final AlbumItemType type;
  final DateTime timestamp;
  final String title;
  final String description;
  final String icon;
  final Map<String, dynamic> data;

  AlbumItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.icon,
    required this.data,
  });
}

/// アルバムカード
class _AlbumCard extends StatelessWidget {
  final AlbumItem item;

  const _AlbumCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;

    switch (item.type) {
      case AlbumItemType.record:
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      case AlbumItemType.thanks:
        backgroundColor = FamicaColors.accent.withOpacity(0.1);
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アイコン
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // コンテンツ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: FamicaColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 説明
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // タイムスタンプ
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return '今日 ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨日 ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
