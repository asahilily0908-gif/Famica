import 'package:cloud_firestore/cloud_firestore.dart';

/// 世帯（household）管理サービス
/// 招待URL生成などの世帯関連機能を提供
class HouseholdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 招待URL生成
  /// householdIdから招待URLを生成し、Firestoreに保存
  Future<String> generateInviteLink(String householdId) async {
    try {
      // 招待URL形式: https://famica.app/invite?hid={householdId}
      final inviteLink = 'https://famica.app/invite?hid=$householdId';
      
      // householdドキュメントにinviteLinkフィールドを追加/更新
      await _firestore.collection('households').doc(householdId).update({
        'inviteLink': inviteLink,
        'inviteLinkUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      return inviteLink;
    } catch (e) {
      print('招待URL生成エラー: $e');
      rethrow;
    }
  }
  
  /// 招待URLから世帯IDを取得
  /// URLパラメータからhouseholdIdを抽出
  String? extractHouseholdIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['hid'];
    } catch (e) {
      print('URL解析エラー: $e');
      return null;
    }
  }
  
  /// 世帯情報を取得
  Future<Map<String, dynamic>?> getHouseholdInfo(String householdId) async {
    try {
      print('🔥 Firestore path: households/$householdId');
      print('🔥 Auth UID: ${_firestore.app.options.projectId}');
      
      final doc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();
      
      print('📊 Document exists: ${doc.exists}');
      
      if (!doc.exists) {
        print('⚠️ Household not found: $householdId');
        return null;
      }
      
      print('✅ Household data retrieved successfully');
      return doc.data();
    } catch (e, stackTrace) {
      print('🔥 Firestore Error in getHouseholdInfo: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// 既存の世帯に招待URLフィールドを追加（マイグレーション用）
  Future<void> migrateExistingHouseholds() async {
    try {
      final snapshot = await _firestore.collection('households').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // inviteLinkフィールドが存在しない場合のみ生成
        if (!data.containsKey('inviteLink')) {
          await generateInviteLink(doc.id);
        }
      }
      
      print('世帯データマイグレーション完了');
    } catch (e) {
      print('マイグレーションエラー: $e');
      rethrow;
    }
  }
}
