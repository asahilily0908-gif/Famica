import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Famica Phase 1-A: 家族招待サービス
/// 招待コード生成・検証・メンバー追加を担当
class InviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 6桁のランダム招待コードを生成
  String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 紛らわしい文字を除外
    final random = Random();
    const length = 6;
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// 招待コードがユニークか確認
  Future<bool> isInviteCodeUnique(String code) async {
    final query = await _firestore
        .collection('households')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    
    return query.docs.isEmpty;
  }

  /// ユニークな招待コードを生成（Firestore重複チェック）
  Future<String> generateUniqueInviteCode() async {
    String code;
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 20;

    do {
      code = generateInviteCode();
      final snapshot = await _firestore
          .collection('households')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      exists = snapshot.docs.isNotEmpty;
      attempts++;
      
      if (attempts >= maxAttempts) {
        throw Exception('招待コードの生成に失敗しました（最大試行回数超過）');
      }
    } while (exists);

    print('✅ ユニーク招待コード生成成功: $code (試行回数: $attempts)');
    return code;
  }

  /// 現在のユーザーのhouseholdIdと招待コードを取得
  Future<Map<String, String>?> getCurrentUserInviteInfo() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // ユーザードキュメントからhouseholdIdを取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final householdId = userDoc.data()?['householdId'] as String?;
      if (householdId == null) return null;

      // householdドキュメントから招待コードを取得
      final householdDoc = await _firestore.collection('households').doc(householdId).get();
      if (!householdDoc.exists) return null;

      final inviteCode = householdDoc.data()?['inviteCode'] as String?;
      if (inviteCode == null) return null;

      return {
        'householdId': householdId,
        'inviteCode': inviteCode,
      };
    } catch (e) {
      print('❌ 招待情報取得エラー: $e');
      return null;
    }
  }

  /// inviteCodesコレクションに招待コードを作成
  Future<void> createInviteCodeDocument(String code, String householdId) async {
    try {
      await _firestore.collection('inviteCodes').doc(code.toUpperCase()).set({
        'householdId': householdId,
        'createdAt': FieldValue.serverTimestamp(),
        'used': false,
        'usedAt': null,
        'usedBy': null,
      });
      print('✅ inviteCodeドキュメント作成成功: $code');
    } catch (e) {
      print('❌ inviteCodeドキュメント作成エラー: $e');
      rethrow;
    }
  }

  /// 招待コードを検証（存在確認・使用済みチェック）
  Future<Map<String, dynamic>?> validateInviteCode(String inviteCode) async {
    try {
      print('🔍 招待コード検証開始: $inviteCode');
      
      final codeDoc = await _firestore
          .collection('inviteCodes')
          .doc(inviteCode.toUpperCase())
          .get();

      if (!codeDoc.exists) {
        print('⚠️ 招待コードが見つかりません: $inviteCode');
        return null;
      }

      final data = codeDoc.data()!;
      final used = data['used'] as bool? ?? false;
      
      if (used) {
        print('⚠️ 招待コードは既に使用されています: $inviteCode');
        return {'error': 'used', 'message': 'この招待コードは既に使用されています'};
      }

      print('✅ 招待コード検証成功: $inviteCode');
      return data;
    } catch (e, stackTrace) {
      print('🔥 Firestore Error: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// 招待コードからhouseholdIdを取得（後方互換性のため残す）
  Future<String?> getHouseholdIdByInviteCode(String inviteCode) async {
    try {
      print('🔍 招待コード検索開始: $inviteCode');
      
      // まずinviteCodesコレクションを検索
      final codeDoc = await _firestore
          .collection('inviteCodes')
          .doc(inviteCode.toUpperCase())
          .get();

      if (codeDoc.exists) {
        final data = codeDoc.data()!;
        final householdId = data['householdId'] as String?;
        print('✅ inviteCodesからhouseholdId取得成功: $householdId');
        return householdId;
      }

      // 見つからない場合は従来の方法（householdsコレクション）を試す（後方互換性）
      final query = await _firestore
          .collection('households')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      print('📊 検索結果: ${query.docs.length}件');

      if (query.docs.isEmpty) {
        print('⚠️ 招待コードが見つかりません: $inviteCode');
        return null;
      }

      final householdId = query.docs.first.id;
      print('✅ householdsからhouseholdId取得成功: $householdId');
      return householdId;
    } catch (e, stackTrace) {
      print('🔥 Firestore Error: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// 招待コードを使用してhouseholdに参加（安全なトランザクション化）
  Future<Map<String, dynamic>> joinHouseholdByInviteCode(String inviteCode, {
    required String memberName,
    required String role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'success': false, 'error': 'not_authenticated', 'message': 'ログインが必要です'};
    }

    try {
      print('=== 招待コード参加処理開始 ===');
      print('招待コード: $inviteCode');
      print('ユーザーUID: ${user.uid}');
      
      // 事前検証：招待コードの存在確認と使用済みチェック
      final validation = await validateInviteCode(inviteCode);
      
      if (validation == null) {
        print('❌ 招待コードが無効です');
        return {'success': false, 'error': 'invalid_code', 'message': '無効な招待コードです'};
      }
      
      if (validation.containsKey('error')) {
        print('❌ ${validation['message']}');
        return {
          'success': false,
          'error': validation['error'],
          'message': validation['message'],
        };
      }
      
      final householdId = validation['householdId'] as String;
      print('householdId: $householdId');

      // 自分のhouseholdに自分で参加しようとしていないかチェック
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentHouseholdId = userDoc.data()?['householdId'] as String?;
      if (currentHouseholdId == householdId) {
        print('⚠️ 自分のhouseholdの招待コードです');
        return {'success': false, 'error': 'self_join', 'message': '自分の世帯の招待コードです'};
      }

      // トランザクションで招待コード使用済み化 + household参加を同時実行
      await _firestore.runTransaction((transaction) async {
        // inviteCodeドキュメントを再取得（トランザクション内で再チェック）
        final inviteCodeRef = _firestore.collection('inviteCodes').doc(inviteCode.toUpperCase());
        final inviteCodeDoc = await transaction.get(inviteCodeRef);
        
        if (!inviteCodeDoc.exists) {
          throw Exception('招待コードが存在しません');
        }
        
        final inviteCodeData = inviteCodeDoc.data()!;
        final used = inviteCodeData['used'] as bool? ?? false;
        
        if (used) {
          throw Exception('この招待コードは既に使用されています');
        }

        // householdドキュメントを取得
        final householdRef = _firestore.collection('households').doc(householdId);
        final householdDoc = await transaction.get(householdRef);
        
        if (!householdDoc.exists) {
          throw Exception('世帯が存在しません');
        }

        final householdData = householdDoc.data()!;
        final members = List<Map<String, dynamic>>.from(householdData['members'] ?? []);

        // 既に参加済みかチェック（コードを消費せずに終了）
        if (members.any((m) => m['uid'] == user.uid)) {
          print('✅ 既に参加済みです（コードは消費しない）');
          return;
        }

        print('現在のメンバー数: ${members.length}');

        // 新しいメンバーを追加
        members.add({
          'uid': user.uid,
          'name': memberName,
          'role': role,
          'avatar': user.photoURL ?? '',
          'joinedAt': FieldValue.serverTimestamp(),
        });

        print('更新後のメンバー数: ${members.length}');

        // householdを更新（membersに追加）
        transaction.update(householdRef, {
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ユーザードキュメントを更新
        final userRef = _firestore.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'householdId': householdId,
          'displayName': memberName,
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 招待コードを使用済みにマーク
        transaction.update(inviteCodeRef, {
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
          'usedBy': user.uid,
        });
        
        print('✅ トランザクション内の更新処理完了');
      });

      print('✅ household参加成功: $householdId');
      return {'success': true, 'householdId': householdId};
    } catch (e) {
      print('❌ household参加エラー: $e');
      
      // エラーメッセージを詳細に返す
      if (e.toString().contains('既に使用されています')) {
        return {
          'success': false,
          'error': 'already_used',
          'message': 'この招待コードは既に使用されています。\n新しい招待コードを発行してください。',
        };
      }
      
      return {
        'success': false,
        'error': 'unknown',
        'message': '参加に失敗しました: $e',
      };
    }
  }

  /// household作成（初回ユーザー用）
  Future<String?> createHouseholdWithInviteCode({
    required String householdName,
    required String memberName,
    required String role,
    required String lifeStage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // ユニークな招待コードを生成
      final inviteCode = await generateUniqueInviteCode();

      // householdドキュメントを作成
      final householdRef = _firestore.collection('households').doc();
      await householdRef.set({
        'name': householdName,
        'inviteCode': inviteCode,
        'inviteActive': true, // 招待コード有効状態
        'lifeStage': lifeStage,
        'members': [
          {
            'uid': user.uid,
            'name': memberName,
            'role': role,
            'avatar': user.photoURL ?? '',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        ],
        'plan': 'free',
        'planOwner': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // inviteCodesコレクションにドキュメントを作成
      await createInviteCodeDocument(inviteCode, householdRef.id);

      // ユーザードキュメントを更新
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': memberName,
        'email': user.email,
        'householdId': householdRef.id,
        'avatar': user.photoURL ?? '',
        'role': role,
        'lifeStage': lifeStage,
        'plan': 'free',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ household作成成功: ${householdRef.id}, 招待コード: $inviteCode');
      return householdRef.id;
    } catch (e) {
      print('❌ household作成エラー: $e');
      return null;
    }
  }

  /// 招待リンクを生成（LINE共有用）
  String generateInviteLink(String inviteCode) {
    // 本番環境ではディープリンクを使用
    // 開発環境では招待コードのみ
    return 'Famicaに招待されました！\n招待コード: $inviteCode\n\nアプリをダウンロードして、このコードを入力してください。';
  }

  /// householdIdを直接指定して参加（招待URL用）
  Future<bool> joinHouseholdById({
    required String householdId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      print('=== 招待URL参加処理開始 ===');
      print('householdId: $householdId');
      print('userId: $userId');

      // トランザクションでusersとhouseholdsを同時に更新
      await _firestore.runTransaction((transaction) async {
        // householdドキュメントを取得
        final householdRef = _firestore.collection('households').doc(householdId);
        final householdDoc = await transaction.get(householdRef);
        
        if (!householdDoc.exists) {
          throw Exception('指定された世帯が存在しません');
        }

        final householdData = householdDoc.data()!;
        final members = List<Map<String, dynamic>>.from(householdData['members'] ?? []);

        // 既に参加済みかチェック
        if (members.any((m) => m['uid'] == userId)) {
          print('✅ 既に参加済みです');
          return;
        }

        print('現在のメンバー数: ${members.length}');

        // ユーザードキュメントを取得してnickname情報を取得
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        String displayName = userName;
        String nickname = userName;
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          displayName = userData['displayName'] ?? userName;
          nickname = userData['nickname'] ?? displayName;
        }

        // 新しいメンバーを追加
        members.add({
          'uid': userId,
          'name': displayName,
          'nickname': nickname,
          'role': 'member', // デフォルトロール
          'avatar': '',
          'joinedAt': FieldValue.serverTimestamp(),
        });

        print('更新後のメンバー数: ${members.length}');

        // householdを更新
        transaction.update(householdRef, {
          'members': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ユーザードキュメントを更新
        transaction.set(userRef, {
          'uid': userId,
          'email': userEmail,
          'displayName': displayName,
          'nickname': nickname,
          'householdId': householdId,
          'role': 'member',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('✅ トランザクション内の更新処理完了');
      });

      print('✅ household参加成功: $householdId');
      return true;
    } catch (e) {
      print('❌ household参加エラー: $e');
      rethrow;
    }
  }

  /// householdのメンバー一覧を取得（displayNameをusersコレクションから取得）
  Future<List<Map<String, dynamic>>> getHouseholdMembers() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final householdId = userDoc.data()?['householdId'] as String?;
      if (householdId == null) return [];

      final householdDoc = await _firestore.collection('households').doc(householdId).get();
      if (!householdDoc.exists) return [];

      final members = List<Map<String, dynamic>>.from(householdDoc.data()?['members'] ?? []);
      
      // 各メンバーのdisplayNameをusersコレクションから取得
      for (var member in members) {
        final memberUid = member['uid'] as String?;
        if (memberUid != null) {
          try {
            final memberUserDoc = await _firestore.collection('users').doc(memberUid).get();
            if (memberUserDoc.exists) {
              member['displayName'] = memberUserDoc.data()?['displayName'] as String? ?? member['name'] ?? '未設定';
            } else {
              member['displayName'] = member['name'] ?? '未設定';
            }
          } catch (e) {
            member['displayName'] = member['name'] ?? '未設定';
          }
        }
      }
      
      return members;
    } catch (e) {
      print('❌ メンバー一覧取得エラー: $e');
      return [];
    }
  }
}
