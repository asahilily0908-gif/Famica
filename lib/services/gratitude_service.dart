import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 感謝メッセージサービス
class GratitudeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUid => _auth.currentUser?.uid;

  /// 感謝メッセージ送信
  Future<void> sendMessage({
    required String toUserId,
    required String fromUserName,
    required String message,
  }) async {
    if (_currentUid == null) {
      throw Exception('ユーザーが認証されていません');
    }

    await _firestore.collection('gratitudeMessages').add({
      'fromUserId': _currentUid,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 未読メッセージ監視（リアルタイム）
  Stream<int> watchUnreadCount() {
    if (_currentUid == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('gratitudeMessages')
        .where('toUserId', isEqualTo: _currentUid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// メッセージ一覧取得
  Stream<QuerySnapshot> fetchMessages() {
    if (_currentUid == null) {
      return Stream.value(
        FirebaseFirestore.instance.collection('gratitudeMessages').snapshots().first as QuerySnapshot,
      );
    }

    return _firestore
        .collection('gratitudeMessages')
        .where('toUserId', isEqualTo: _currentUid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 一括既読化
  Future<void> markAllAsRead() async {
    if (_currentUid == null) return;

    try {
      final unread = await _firestore
          .collection('gratitudeMessages')
          .where('toUserId', isEqualTo: _currentUid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ 既読化エラー: $e');
      rethrow;
    }
  }

  /// 単一メッセージを既読化
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore
          .collection('gratitudeMessages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ 既読化エラー: $e');
      rethrow;
    }
  }
}
