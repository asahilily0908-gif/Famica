import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'invite_service.dart';

/// Famica v3.0 Firestoreサービス
/// households/{householdId} ベースのデータ構造に対応
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InviteService _inviteService = InviteService();

  // 現在のユーザーのhouseholdIdを取得
  Future<String?> getCurrentUserHouseholdId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['householdId'] as String?;
      }
      // usersドキュメントが存在しない場合は、uidをhouseholdIdとして使用
      return user.uid;
    } catch (e) {
      print('❌ householdId取得エラー: $e');
      return user.uid;
    }
  }

  // ユーザー情報の作成または更新
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String displayName,
    String? householdId,
    String role = '未設定',
    String lifeStage = 'couple',
    String plan = 'free',
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'displayName': displayName,
        'nickname': displayName, // ★ nicknameフィールドを追加
        'email': email,
        'householdId': householdId ?? uid,
        'role': role,
        'lifeStage': lifeStage,
        'plan': plan,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ users/${uid} 保存完了: nickname=$displayName, householdId=${householdId ?? uid}');
    } catch (e) {
      print('❌ ユーザー情報作成エラー: $e');
      rethrow;
    }
  }

  // 世帯情報の作成または更新
  Future<void> createOrUpdateHousehold({
    required String householdId,
    required String name,
    required String uid,
    required String memberName,
    String role = '未設定',
    String lifeStage = 'couple',
  }) async {
    try {
      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();

      if (!householdDoc.exists) {
        // 新規作成（安全なコード生成 + Firestore重複チェック）
        final inviteCode = await _inviteService.generateUniqueInviteCode();

        await _firestore.collection('households').doc(householdId).set({
          'name': name,
          'inviteCode': inviteCode,
          'lifeStage': lifeStage,
          'members': [
            {
              'uid': uid,
              'name': memberName,
              'nickname': memberName,
              'role': role,
              'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$memberName',
            }
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });

        // inviteCodesコレクションにも登録
        await _inviteService.createInviteCodeDocument(inviteCode, householdId);

        print('✅ household作成: $householdId (inviteCode: $inviteCode)');
      } else {
        // 既存の世帯にメンバーを追加（重複チェック）
        final members = List<Map<String, dynamic>>.from(
            householdDoc.data()?['members'] ?? []);
        final existingMemberIndex = members.indexWhere((m) => m['uid'] == uid);

        if (existingMemberIndex == -1) {
          // 新しいメンバーを追加
          members.add({
            'uid': uid,
            'name': memberName,
            'nickname': memberName, // nicknameフィールドを追加
            'role': role,
            'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$memberName',
          });

          await _firestore.collection('households').doc(householdId).update({
            'members': members,
          });
          print('✅ household更新: メンバー追加 ($memberName)');
        } else {
          // 既存メンバーの情報を更新（nicknameが設定されていない場合）
          final existingMember = members[existingMemberIndex];
          if (existingMember['nickname'] == null || (existingMember['nickname'] as String).isEmpty) {
            members[existingMemberIndex] = {
              ...existingMember,
              'nickname': memberName,
            };
            await _firestore.collection('households').doc(householdId).update({
              'members': members,
            });
            print('✅ household更新: ニックネーム設定 ($memberName)');
          } else {
            print('ℹ️ household: メンバー既存 (スキップ)');
          }
        }
      }
    } catch (e) {
      print('❌ 世帯情報作成エラー: $e');
      rethrow;
    }
  }

  // 記録の作成
  Future<String> createRecord({
    required String category,
    required String task,
    required int timeMinutes,
    int cost = 0,
    String note = '',
    String? customMonth,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) throw Exception('householdIdが取得できません');

    // ユーザー名をnicknameから取得（優先順位: nickname > name > displayName > email@前 > '未設定'）
    final members = await getHouseholdMembers();
    final myMember = members.firstWhere(
      (m) => m['uid'] == user.uid,
      orElse: () => <String, dynamic>{},
    );
    final memberName = myMember['nickname'] as String? ?? 
                      myMember['name'] as String? ?? 
                      user.displayName ?? 
                      user.email?.split('@')[0] ?? 
                      '未設定';

    final now = DateTime.now();
    final month = customMonth ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    try {
      final docRef = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('records')
          .add({
        'memberId': user.uid,
        'memberName': memberName,
        'category': category,
        'task': task,
        'timeMinutes': timeMinutes,
        'cost': cost,
        'note': note,
        'month': month,
        'thankedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 記録作成後、インサイトを自動生成
      // エラーが発生してもrecord作成は成功とする
      generateMonthlyInsights().catchError((e) {
        print('⚠️ インサイト生成エラー（記録は作成済み）: $e');
      });

      return docRef.id;
    } catch (e) {
      print('❌ 記録作成エラー: $e');
      rethrow;
    }
  }

  // 月次記録の取得
  Stream<QuerySnapshot> getMonthlyRecords(String month) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .where('month', isEqualTo: month)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 感謝の送信
  Future<void> sendThanks({
    required String recordId,
    required String toUid,
    required String toName,
    required String emoji,
    String message = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) throw Exception('householdIdが取得できません');

    // 送信者名をnicknameから取得（優先順位: nickname > name > displayName > email@前 > '未設定'）
    final members = await getHouseholdMembers();
    final myMember = members.firstWhere(
      (m) => m['uid'] == user.uid,
      orElse: () => <String, dynamic>{},
    );
    final fromName = myMember['nickname'] as String? ?? 
                    myMember['name'] as String? ?? 
                    user.displayName ?? 
                    user.email?.split('@')[0] ?? 
                    '未設定';

    try {
      // thanksコレクションに追加
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('thanks')
          .add({
        'fromUid': user.uid,
        'fromName': fromName,
        'toUid': toUid,
        'toName': toName,
        'recordId': recordId,
        'emoji': emoji,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // recordのthankedBy配列を更新
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('records')
          .doc(recordId)
          .update({
        'thankedBy': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      print('❌ 感謝送信エラー: $e');
      rethrow;
    }
  }

  // シンプルな感謝の追加（💗ボタン用）
  Future<void> addThanks(String recordId, {required String toUserId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) throw Exception('householdIdが取得できません');

    try {
      final ref = _firestore
          .collection('households')
          .doc(householdId)
          .collection('records')
          .doc(recordId);

      // 自分が既にありがとう済みなら何もしない（重複防止）
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final thankedBy = List<String>.from(data['thankedBy'] ?? []);
      if (thankedBy.contains(user.uid)) {
        print('ℹ️ 既に感謝済み: $recordId');
        return;
      }

      // recordのthankedBy配列を更新
      await ref.update({
        'thankedBy': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ 感謝を追加: $recordId');

      // 感謝をもらった人の称号を更新（自分でなければ）
      if (toUserId.isNotEmpty && toUserId != user.uid) {
        try {
          await incrementThanksAndUpdateTitle(toUserId);
          print('✅ 称号更新完了');
        } catch (e) {
          print('⚠️ 称号更新失敗（記録は保存済み）: $e');
        }
      }
    } catch (e) {
      print('❌ 感謝追加エラー: $e');
      rethrow;
    }
  }

  // ========================================
  // 称号バッジシステム
  // ========================================

  /// 感謝数を増やして称号を更新
  Future<void> incrementThanksAndUpdateTitle(String userId) async {
    try {
      final uref = _firestore.collection('users').doc(userId);
      
      // FieldValue.increment を使用して感謝数を増やす
      await uref.set({
        'totalThanksReceived': FieldValue.increment(1),
      }, SetOptions(merge: true));
      
      // 最新の感謝数を取得
      final doc = await uref.get();
      final count = (doc.data()?['totalThanksReceived'] ?? 0) as int;
      
      // 称号を計算して更新
      final title = getTitleForCount(count);
      await uref.update({
        'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ 感謝数更新: $userId (count: $count, title: $title)');
    } catch (e) {
      print('❌ 感謝数更新エラー: $e');
      rethrow;
    }
  }

  /// 感謝数から称号を取得
  String getTitleForCount(int count) {
    if (count >= 200) return '🕊️ ふたりの賢者';
    if (count >= 100) return '💞 思いやりマスター';
    if (count >= 50) return '🧺 家事の達人';
    if (count >= 30) return '🌿 感謝の芽';
    if (count >= 10) return '🌱 家事のたね';
    return '';
  }

  /// ユーザーの感謝数と称号を取得
  Future<Map<String, dynamic>> getUserThanksInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return {
          'totalThanksReceived': 0,
          'title': '',
        };
      }
      
      final data = userDoc.data()!;
      return {
        'totalThanksReceived': data['totalThanksReceived'] as int? ?? 0,
        'title': data['title'] as String? ?? '',
      };
    } catch (e) {
      print('❌ 感謝情報取得エラー: $e');
      return {
        'totalThanksReceived': 0,
        'title': '',
      };
    }
  }

  // クイックテンプレートの取得
  Stream<QuerySnapshot> getQuickTemplates() async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('quickTemplates')
        .orderBy('order')
        .snapshots();
  }

  // 月次統計データの取得
  Stream<Map<String, dynamic>> getMonthlyStats(String month) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield {};
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      yield {};
      return;
    }

    // householdドキュメントとrecordsの両方を監視
    await for (final _ in _firestore
        .collection('households')
        .doc(householdId)
        .snapshots()) {
      
      // recordsを取得
      final snapshot = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('records')
          .where('month', isEqualTo: month)
          .get();
      
      // メンバー情報を取得（ニックネーム優先）
      final members = await getHouseholdMembers();
      
      // 自分のメンバー情報
      final myMember = members.firstWhere(
        (m) => m['uid'] == user.uid,
        orElse: () => <String, dynamic>{},
      );
      
      // 自分の表示名：nickname > name > displayName > 'あなた'
      String myName = myMember['nickname'] as String? ?? 
                      myMember['name'] as String? ?? 
                      user.displayName ?? 
                      'あなた';
      
      // パートナー情報を取得
      String partnerName = 'パートナー';
      String? partnerUid;
      
      final partnerMember = members.firstWhere(
        (m) => m['uid'] != user.uid,
        orElse: () => {'uid': '', 'name': '', 'nickname': ''},
      );
      
      if (partnerMember['uid'] != '') {
        partnerUid = partnerMember['uid'] as String;
        // パートナーの表示名：nickname > name > 'パートナー'
        partnerName = partnerMember['nickname'] as String? ?? 
                     partnerMember['name'] as String? ?? 
                     'パートナー';
      }

      // 今月の記録を集計
      int myCount = 0;
      int myTime = 0;
      int partnerCount = 0;
      int partnerTime = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String?;
        final timeMinutes = data['timeMinutes'] as int? ?? 0;
        
        if (memberId == user.uid) {
          myCount++;
          myTime += timeMinutes;
        } else {
          partnerCount++;
          partnerTime += timeMinutes;
        }
      }

      // パーセンテージ計算
      final totalTime = myTime + partnerTime;
      final myPercent = totalTime > 0 ? (myTime / totalTime * 100).round() : 50;
      final partnerPercent = totalTime > 0 ? 100 - myPercent : 50;

      yield {
        'myCount': myCount,
        'myTime': myTime,
        'myPercent': myPercent,
        'partnerCount': partnerCount,
        'partnerTime': partnerTime,
        'partnerPercent': partnerPercent,
        'myName': myName,
        'partnerName': partnerName,
      };
    }
  }

  // 今日の統計データの取得
  Stream<Map<String, dynamic>> getTodayStats() async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield {};
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      yield {};
      return;
    }

    // 今日の開始時刻（00:00:00）
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .snapshots()
        .asyncMap((snapshot) async {
      // メンバー情報を取得（ニックネーム優先）
      final members = await getHouseholdMembers();
      
      // 自分のメンバー情報
      final myMember = members.firstWhere(
        (m) => m['uid'] == user.uid,
        orElse: () => <String, dynamic>{},
      );
      
      // 自分の表示名：nickname > name > displayName > 'あなた'
      String myName = myMember['nickname'] as String? ?? 
                      myMember['name'] as String? ?? 
                      user.displayName ?? 
                      'あなた';
      
      // パートナー情報を取得
      String partnerName = 'パートナー';
      String? partnerUid;
      
      final partnerMember = members.firstWhere(
        (m) => m['uid'] != user.uid,
        orElse: () => {'uid': '', 'name': '', 'nickname': ''},
      );
      
      if (partnerMember['uid'] != '') {
        partnerUid = partnerMember['uid'] as String;
        // パートナーの表示名：nickname > name > 'パートナー'
        partnerName = partnerMember['nickname'] as String? ?? 
                     partnerMember['name'] as String? ?? 
                     'パートナー';
      }

      // 今日の記録を集計
      int myCount = 0;
      int partnerCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String?;
        
        if (memberId == user.uid) {
          myCount++;
        } else {
          partnerCount++;
        }
      }

      return {
        'myCount': myCount,
        'partnerCount': partnerCount,
        'myName': myName,
        'partnerName': partnerName,
      };
    });
  }

  // 最近の記録の取得（最新5件）
  Stream<QuerySnapshot> getRecentRecords({int limit = 5}) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // すべての記録の取得
  Stream<QuerySnapshot> getAllRecords() async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 感謝メッセージの取得（Stream）
  Stream<QuerySnapshot> getThanks({int? limit}) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    var query = _firestore
        .collection('households')
        .doc(householdId)
        .collection('thanks')
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    yield* query.snapshots();
  }

  // 達成バッジの取得（Stream）
  Stream<QuerySnapshot> getAchievements({int? limit}) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    var query = _firestore
        .collection('households')
        .doc(householdId)
        .collection('achievements')
        .orderBy('achievedAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    yield* query.snapshots();
  }

  // 招待コードからhouseholdを検索
  Future<String?> getHouseholdByInviteCode(String inviteCode) async {
    try {
      final query = await _firestore
          .collection('households')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query.docs.first.id;
    } catch (e) {
      print('❌ 招待コード検索エラー: $e');
      return null;
    }
  }

  // 招待コードの取得
  Future<String?> getInviteCode() async {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) return null;

    try {
      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();

      if (!householdDoc.exists) return null;

      return householdDoc.data()?['inviteCode'] as String?;
    } catch (e) {
      print('❌ 招待コード取得エラー: $e');
      return null;
    }
  }

  // householdのメンバー一覧を取得（usersコレクションからnickname補完）
  Future<List<Map<String, dynamic>>> getHouseholdMembers() async {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) return [];

    try {
      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();

      if (!householdDoc.exists) return [];

      final members = List<Map<String, dynamic>>.from(
          householdDoc.data()?['members'] ?? []);
      
      // 各メンバーのnicknameをusersコレクションから取得して補完
      for (var member in members) {
        final memberUid = member['uid'] as String?;
        if (memberUid != null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(memberUid)
                .get();
            
            if (userDoc.exists) {
              final userData = userDoc.data();
              // usersコレクションのnicknameを優先、なければdisplayName、なければmembers配列のname
              member['nickname'] = userData?['nickname'] as String? ?? 
                                  userData?['displayName'] as String? ?? 
                                  member['name'] as String? ?? 
                                  '未設定';
            } else if (member['nickname'] == null || (member['nickname'] as String).isEmpty) {
              // usersドキュメントがなく、nicknameもない場合はnameを使用
              member['nickname'] = member['name'] as String? ?? '未設定';
            }
          } catch (e) {
            print('⚠️ メンバー${memberUid}のnickname取得失敗: $e');
            // エラー時はmembers配列のnameを使用
            if (member['nickname'] == null || (member['nickname'] as String).isEmpty) {
              member['nickname'] = member['name'] as String? ?? '未設定';
            }
          }
        }
      }

      return members;
    } catch (e) {
      print('❌ メンバー一覧取得エラー: $e');
      return [];
    }
  }

  // ========================================
  // Phase 3: 初期セットアップ自動化
  // ========================================

  /// 初回ログイン時のユーザー・世帯セットアップ
  /// household/usersドキュメントの自動作成、members配列の自動更新
  Future<void> ensureUserSetup({
    String? displayName,
    String lifeStage = 'couple',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ ユーザー未認証');
      return;
    }

    try {
      print('🔧 初期セットアップ開始...');
      print('   UID: ${user.uid}');
      print('   Email: ${user.email}');

      // 1. usersドキュメントを確認・作成
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String householdId;

      if (!userDoc.exists) {
        // 新規ユーザー
        householdId = user.uid; // 初回は自分のUIDをhouseholdIdに
        final userName = displayName ?? user.email?.split('@')[0] ?? '名無し';

        await createOrUpdateUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: userName,
          householdId: householdId,
          lifeStage: lifeStage,
        );

        print('✅ usersドキュメント作成: users/${user.uid}');
      } else {
        householdId = userDoc.data()?['householdId'] as String? ?? user.uid;
        print('✅ usersドキュメント既存確認');
      }

      // 2. householdドキュメントを確認・作成
      try {
        final householdDoc = await _firestore
            .collection('households')
            .doc(householdId)
            .get();

        if (!householdDoc.exists) {
          // 新規household作成
          final userName = displayName ?? user.email?.split('@')[0] ?? '名無し';
          
          await createOrUpdateHousehold(
            householdId: householdId,
            name: '$userName家',
            uid: user.uid,
            memberName: userName,
            lifeStage: lifeStage,
          );

          print('✅ householdドキュメント作成: households/$householdId');

          // 3. デフォルトquickTemplatesを登録
          await createDefaultQuickTemplates(householdId, lifeStage);
          print('✅ デフォルトテンプレート登録完了');
        } else {
          print('✅ householdドキュメント既存確認');
          
          // members配列に自分が含まれているか確認
          final members = List<Map<String, dynamic>>.from(
              householdDoc.data()?['members'] ?? []);
          final exists = members.any((m) => m['uid'] == user.uid);

          if (!exists) {
            // 自分をmembers配列に追加
            final userName = displayName ?? user.email?.split('@')[0] ?? '名無し';
            members.add({
              'uid': user.uid,
              'name': userName,
              'role': '未設定',
              'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$userName',
            });

            await _firestore
                .collection('households')
                .doc(householdId)
                .update({'members': members});
            
            print('✅ members配列に追加: $userName');
          }
        }
      } catch (e) {
        // householdドキュメントへのアクセスエラー（permission-denied等）
        // → 新規作成を試みる
        print('⚠️ household取得エラー: $e');
        print('🔧 household新規作成を試行...');
        
        final userName = displayName ?? user.email?.split('@')[0] ?? '名無し';
        
        await createOrUpdateHousehold(
          householdId: householdId,
          name: '$userName家',
          uid: user.uid,
          memberName: userName,
          lifeStage: lifeStage,
        );

        print('✅ householdドキュメント作成: households/$householdId');

        // デフォルトquickTemplatesを登録
        await createDefaultQuickTemplates(householdId, lifeStage);
        print('✅ デフォルトテンプレート登録完了');
      }

      print('🎉 初期セットアップ完了！');
    } catch (e, stackTrace) {
      print('❌ 初期セットアップエラー: $e');
      print('スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// デフォルトquickTemplatesの作成
  /// lifeStage別のテンプレートを自動登録
  Future<void> createDefaultQuickTemplates(
    String householdId,
    String lifeStage,
  ) async {
    try {
      // 既存のテンプレートをチェック
      final existingTemplates = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('quickTemplates')
          .limit(1)
          .get();

      if (existingTemplates.docs.isNotEmpty) {
        print('ℹ️ テンプレート既存のためスキップ');
        return;
      }

      final templates = _getDefaultTemplatesForLifeStage(lifeStage);

      for (int i = 0; i < templates.length; i++) {
        final template = templates[i];
        await _firestore
            .collection('households')
            .doc(householdId)
            .collection('quickTemplates')
            .add({
          'task': template['task'],
          'icon': template['icon'],
          'defaultMinutes': template['minutes'],
          'category': template['category'],
          'order': i + 1,
          'lifeStage': lifeStage,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ ${templates.length}件のテンプレートを登録');
    } catch (e) {
      print('❌ テンプレート登録エラー: $e');
      rethrow;
    }
  }

  /// lifeStage別のデフォルトテンプレート
  List<Map<String, dynamic>> _getDefaultTemplatesForLifeStage(String lifeStage) {
    switch (lifeStage) {
      case 'baby':
        return [
          {'icon': '🍼', 'task': '授乳', 'minutes': 20, 'category': '育児'},
          {'icon': '🚼', 'task': 'おむつ替え', 'minutes': 5, 'category': '育児'},
          {'icon': '😴', 'task': '寝かしつけ', 'minutes': 30, 'category': '育児'},
          {'icon': '🛁', 'task': 'お風呂', 'minutes': 30, 'category': '育児'},
          {'icon': '🍳', 'task': '離乳食', 'minutes': 45, 'category': '育児'},
          {'icon': '🚗', 'task': '送迎', 'minutes': 30, 'category': '育児'},
        ];
      case 'newlywed':
        return [
          {'icon': '🍳', 'task': '料理', 'minutes': 30, 'category': '家事'},
          {'icon': '🧺', 'task': '洗濯', 'minutes': 15, 'category': '家事'},
          {'icon': '🧹', 'task': '掃除', 'minutes': 20, 'category': '家事'},
          {'icon': '🛒', 'task': '買い物', 'minutes': 45, 'category': '家事'},
          {'icon': '🚗', 'task': '車関係', 'minutes': 20, 'category': 'その他'},
          {'icon': '📄', 'task': '書類手続き', 'minutes': 30, 'category': 'その他'},
        ];
      case 'couple':
      default:
        return [
          {'icon': '🍳', 'task': '料理', 'minutes': 30, 'category': '家事'},
          {'icon': '🧺', 'task': '洗濯', 'minutes': 15, 'category': '家事'},
          {'icon': '🧹', 'task': '掃除', 'minutes': 20, 'category': '家事'},
          {'icon': '🛒', 'task': '買い物', 'minutes': 45, 'category': '家事'},
          {'icon': '🗑️', 'task': 'ゴミ出し', 'minutes': 5, 'category': '家事'},
          {'icon': '💧', 'task': '水回り', 'minutes': 15, 'category': '家事'},
        ];
    }
  }

  // ========================================
  // インサイト管理
  // ========================================

  /// 今月の記録から自動的にインサイトを生成
  /// 記録追加時に呼び出される（重複防止機能付き）
  Future<void> generateMonthlyInsights() async {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      print('❌ [insights] householdIdが取得できません');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ [insights] ユーザー未認証');
      return;
    }

    try {
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final insightsRef = _firestore
          .collection('households')
          .doc(householdId)
          .collection('insights');

      // 既存の今月のインサイトを取得（重複チェック用）
      final existingInsights = await insightsRef
          .where('month', isEqualTo: currentMonth)
          .where('isDemo', isEqualTo: false)
          .get();

      final existingTexts = existingInsights.docs
          .map((doc) => (doc.data()['text'] as String? ?? '').trim())
          .toSet();

      print('ℹ️ [insights] 既存インサイト: ${existingTexts.length}件');

      // 今月の記録を取得
      final recordsSnapshot = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('records')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .get();

      if (recordsSnapshot.docs.isEmpty) {
        print('ℹ️ [insights] 今月の記録がありません');
        return;
      }

      // カテゴリごとの件数を集計
      final categoryCount = <String, int>{};
      int myCount = 0;
      int partnerCount = 0;

      for (var doc in recordsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'その他';
        final memberId = data['memberId'] as String? ?? '';

        // カテゴリ集計
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;

        // メンバー別集計
        if (memberId == user.uid) {
          myCount++;
        } else {
          partnerCount++;
        }
      }

      if (categoryCount.isEmpty) {
        print('ℹ️ [insights] カテゴリデータなし');
        return;
      }

      // 最も多いカテゴリを特定
      final topCategory = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      
      // 貢献率を計算
      final total = myCount + partnerCount;
      final myRatio = total > 0 ? myCount / total : 0.5;
      final partnerRatio = total > 0 ? partnerCount / total : 0.5;

      // AI風コメントを生成
      final insightText = _generateMonthlyInsight(
        topCategory: topCategory,
        userRatio: myRatio,
        partnerRatio: partnerRatio,
      );

      // 重複チェックして保存
      if (!existingTexts.contains(insightText.trim())) {
        await insightsRef.add({
          'text': insightText,
          'type': 'task_summary',
          'subtype': 'suggestion',
          'category': topCategory,
          'month': currentMonth,
          'isDemo': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ [insights] 新規インサイトを生成: $insightText');
      } else {
        print('ℹ️ [insights] 同じ内容のため重複スキップ');
      }
    } catch (e) {
      print('❌ [insights] 生成エラー: $e');
    }
  }

  /// AI風の月次インサイトを生成（ルールベース）
  String _generateMonthlyInsight({
    required String topCategory,
    required double userRatio,
    required double partnerRatio,
  }) {
    // バランスメッセージ
    String bias;
    if (userRatio > 0.7) {
      bias = "少し偏っているようです。たまにはパートナーにお願いしてもいいかも💆‍♀️";
    } else if (partnerRatio > 0.7) {
      bias = "パートナーが支えてくれていますね💞 感謝を伝えてみましょう💌";
    } else {
      bias = "ふたりのバランスが良いですね🌸 無理せず続けていきましょう☺️";
    }

    // カテゴリ別提案
    switch (topCategory) {
      case '料理':
      case '家事':
        return "料理のバランスが良いですね🍳\n$bias";
      case '掃除':
        return "お家を整える時間が多かったですね🧹\n$bias";
      case '洗濯':
        return "日々の積み重ねが素敵です👕\n$bias";
      case '買い物':
        return "生活を支える準備をしっかりされています🛒\n$bias";
      case '育児':
        return "家族への思いやりが伝わる1ヶ月でした👶\n$bias";
      default:
        return "お互いを支え合う時間が取れていますね✨\n$bias";
    }
  }

  // ========================================
  // テストデータ管理
  // ========================================

  /// 今月の気づきのテストデータを1件追加
  /// デバッグ用: insightsコレクションが空の場合に使用
  Future<void> seedOneInsight() async {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      print('❌ householdIdが取得できません');
      return;
    }

    try {
      final now = DateTime.now();
      final nowMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('insights')
          .add({
        'text': '料理の回数が先月より3回増えました！',
        'type': 'task_summary',
        'subtype': 'suggestion',
        'category': '料理',
        'month': nowMonth,
        'isDemo': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ [insights] テストデータを追加しました');
      print('   householdId: $householdId');
      print('   month: $nowMonth');
    } catch (e) {
      print('❌ [insights] テストデータ追加エラー: $e');
      rethrow;
    }
  }

  // ========================================
  // ニックネーム管理
  // ========================================

  /// 自分のニックネームを更新
  Future<void> updateMyNickname(String newNickname) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) throw Exception('householdIdが取得できません');

    try {
      // 1. usersコレクションを更新（重要：これが即時反映のキー）
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'nickname': newNickname,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ users/${user.uid} ニックネーム更新: $newNickname');

      // 2. householdドキュメントを取得
      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();

      if (!householdDoc.exists) {
        throw Exception('世帯情報が見つかりません');
      }

      // 3. members配列を更新
      final members = List<Map<String, dynamic>>.from(
          householdDoc.data()?['members'] ?? []);

      // 自分のメンバー情報を更新
      bool updated = false;
      for (var member in members) {
        if (member['uid'] == user.uid) {
          member['nickname'] = newNickname;
          updated = true;
          break;
        }
      }

      if (!updated) {
        throw Exception('メンバー情報が見つかりません');
      }

      // 4. Firestoreに保存
      await _firestore
          .collection('households')
          .doc(householdId)
          .update({
        'members': members,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ household/${householdId} members配列更新完了: $newNickname');
    } catch (e) {
      print('❌ ニックネーム更新エラー: $e');
      rethrow;
    }
  }

  /// 現在のニックネームを取得
  Future<String?> getMyNickname() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final members = await getHouseholdMembers();
      final myMember = members.firstWhere(
        (m) => m['uid'] == user.uid,
        orElse: () => <String, dynamic>{},
      );

      return myMember['nickname'] as String?;
    } catch (e) {
      print('❌ ニックネーム取得エラー: $e');
      return null;
    }
  }

  // ========================================
  // カスタムカテゴリ管理
  // ========================================

  /// ユーザーのカスタムカテゴリを取得
  Future<List<Map<String, dynamic>>> getUserCustomCategories() async {
    final user = _auth.currentUser;
    if (user == null) {
      // 認証されていない場合はデフォルトカテゴリを返す
      return _getDefaultCategoriesAsMap();
    }

    try {
      // デフォルトカテゴリを取得
      final defaultCategories = _getDefaultCategoriesAsMap();
      
      // カスタムカテゴリを取得
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('customCategories')
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        // カスタムカテゴリがない場合はデフォルトのみを返す
        return defaultCategories;
      }

      // カスタムカテゴリをMapに変換
      final customCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String? ?? '',
          'emoji': data['emoji'] as String? ?? '📝',
          'defaultMinutes': data['defaultMinutes'] as int? ?? 30,
          'isVisible': data['isVisible'] as bool? ?? true,
          'order': data['order'] as int? ?? 0,
          'overridesDefaultId': data['overridesDefaultId'] as String?,
        };
      }).toList();

      // 上書きされたデフォルトカテゴリのIDを収集
      final overriddenDefaultIds = customCategories
          .where((c) => c['overridesDefaultId'] != null)
          .map((c) => c['overridesDefaultId'] as String)
          .toSet();

      // 上書きされていないデフォルトカテゴリのみをフィルタリング
      final filteredDefaultCategories = defaultCategories
          .where((cat) => !overriddenDefaultIds.contains(cat['id']))
          .toList();

      // フィルタ済みデフォルト + カスタムを結合して返す
      return [...filteredDefaultCategories, ...customCategories];
    } catch (e) {
      print('❌ カスタムカテゴリ取得エラー: $e');
      return _getDefaultCategoriesAsMap();
    }
  }

  /// ユーザーのカスタムカテゴリをStreamで取得（リアルタイム同期用）
  Stream<List<Map<String, dynamic>>> getUserCustomCategoriesStream() async* {
    final user = _auth.currentUser;
    if (user == null) {
      // 認証されていない場合はデフォルトカテゴリを返す
      yield _getDefaultCategoriesAsMap();
      return;
    }

    try {
      // デフォルトカテゴリを取得
      final defaultCategories = _getDefaultCategoriesAsMap();
      
      // 🔍 DEBUG LOG: Stream購読パス
      final streamPath = 'users/${user.uid}/customCategories';
      print('📡 [STREAM_SETUP] 購読パス: $streamPath');
      print('📡 [STREAM_SETUP] クエリ条件: where(isVisible == true).orderBy(order)');
      
      // カスタムカテゴリをStreamで監視
      yield* _firestore
          .collection('users')
          .doc(user.uid)
          .collection('customCategories')
          .where('isVisible', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
        
        // 🔍 DEBUG LOG: Snapshotの内容
        print('📡 [STREAM_DATA] Snapshot受信: ${snapshot.docs.length}件');
        print('📡 [STREAM_DATA] ドキュメントID一覧:');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('  - ${doc.id}: name=${data['name']}, isVisible=${data['isVisible']}');
        }
        
        if (snapshot.docs.isEmpty) {
          // カスタムカテゴリがない場合はデフォルトのみを返す
          return defaultCategories;
        }

        // カスタムカテゴリをMapに変換
        final customCategories = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] as String? ?? '',
            'emoji': data['emoji'] as String? ?? '📝',
            'defaultMinutes': data['defaultMinutes'] as int? ?? 30,
            'isVisible': data['isVisible'] as bool? ?? true,
            'order': data['order'] as int? ?? 0,
            'overridesDefaultId': data['overridesDefaultId'] as String?,
          };
        }).toList();

        // 上書きされたデフォルトカテゴリのIDを収集
        final overriddenDefaultIds = customCategories
            .where((c) => c['overridesDefaultId'] != null)
            .map((c) => c['overridesDefaultId'] as String)
            .toSet();

        // 上書きされていないデフォルトカテゴリのみをフィルタリング
        final filteredDefaultCategories = defaultCategories
            .where((cat) => !overriddenDefaultIds.contains(cat['id']))
            .toList();

        // フィルタ済みデフォルト + カスタムを結合して返す
        return [...filteredDefaultCategories, ...customCategories];
      });
    } catch (e) {
      print('❌ カスタムカテゴリStream取得エラー: $e');
      yield _getDefaultCategoriesAsMap();
    }
  }

  /// デフォルトカテゴリをMap形式で返す
  List<Map<String, dynamic>> _getDefaultCategoriesAsMap() {
    return [
      {'id': 'default_cooking', 'name': '料理', 'emoji': '🍳', 'defaultMinutes': 30, 'order': 1},
      {'id': 'default_laundry', 'name': '洗濯', 'emoji': '🧺', 'defaultMinutes': 15, 'order': 2},
      {'id': 'default_cleaning', 'name': '掃除', 'emoji': '🧹', 'defaultMinutes': 20, 'order': 3},
      {'id': 'default_shopping', 'name': '買い物', 'emoji': '🛒', 'defaultMinutes': 45, 'order': 4},
      {'id': 'default_trash', 'name': 'ゴミ出し', 'emoji': '🗑️', 'defaultMinutes': 5, 'order': 5},
      {'id': 'default_water', 'name': '水回り', 'emoji': '💧', 'defaultMinutes': 15, 'order': 6},
    ];
  }

  /// カスタムカテゴリを追加
  Future<String> addCustomCategory({
    required String name,
    required String emoji,
    required int defaultMinutes,
    required int order,
    String? overridesDefaultId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    try {
      final data = {
        'name': name,
        'emoji': emoji,
        'defaultMinutes': defaultMinutes,
        'isVisible': true,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // デフォルトカテゴリを上書きする場合
      if (overridesDefaultId != null) {
        data['overridesDefaultId'] = overridesDefaultId;
      }

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('customCategories')
          .add(data);

      print('✅ カスタムカテゴリ追加: $name${overridesDefaultId != null ? ' (overrides: $overridesDefaultId)' : ''}');
      return docRef.id;
    } catch (e) {
      print('❌ カスタムカテゴリ追加エラー: $e');
      rethrow;
    }
  }

  /// カスタムカテゴリを更新
  Future<void> updateCustomCategory({
    required String categoryId,
    String? name,
    String? emoji,
    int? defaultMinutes,
    bool? isVisible,
    int? order,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (emoji != null) updateData['emoji'] = emoji;
      if (defaultMinutes != null) updateData['defaultMinutes'] = defaultMinutes;
      if (isVisible != null) updateData['isVisible'] = isVisible;
      if (order != null) updateData['order'] = order;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('customCategories')
          .doc(categoryId)
          .update(updateData);

      print('✅ カスタムカテゴリ更新: $categoryId');
    } catch (e) {
      print('❌ カスタムカテゴリ更新エラー: $e');
      rethrow;
    }
  }

  /// カスタムカテゴリを削除
  Future<void> deleteCustomCategory(String categoryId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) throw Exception('世帯IDが取得できません');

    try {
      // デフォルトカテゴリ（default_で始まる）かどうかを判定
      final isDefaultCategory = categoryId.startsWith('default_');

      // 🔍 DEBUG LOG: 削除対象の情報
      final deletePath = 'users/${user.uid}/customCategories/$categoryId';
      print('🗑️ [DELETE] 削除対象docId: $categoryId');
      print('🗑️ [DELETE] 削除対象パス: $deletePath');
      print('🗑️ [DELETE] isDefaultCategory: $isDefaultCategory');

      String? categoryName;

      if (isDefaultCategory) {
        // デフォルトカテゴリの場合：isVisible=falseのカスタムカテゴリを作成して非表示化
        print('🗑️ [DELETE] 操作: デフォルトカテゴリを非表示化（isVisible=false）');
        
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('customCategories')
            .add({
          'isVisible': false,
          'overridesDefaultId': categoryId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ デフォルトカテゴリを非表示化: $categoryId');
      } else {
        // カスタムカテゴリの場合：通常のハード削除
        final categoryDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('customCategories')
            .doc(categoryId)
            .get();

        if (categoryDoc.exists) {
          categoryName = categoryDoc.data()?['name'] as String?;
        }

        print('🗑️ [DELETE] カテゴリ名: $categoryName');
        print('🗑️ [DELETE] 操作: doc.delete() (ハード削除)');

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('customCategories')
            .doc(categoryId)
            .delete();

        print('✅ カスタムカテゴリ削除完了: $categoryId (name: $categoryName)');

        // そのカテゴリに紐づくすべてのrecordsを削除
        if (categoryName != null && categoryName.isNotEmpty) {
          final recordsSnapshot = await _firestore
              .collection('households')
              .doc(householdId)
              .collection('records')
              .where('category', isEqualTo: categoryName)
              .get();

          final batch = _firestore.batch();
          for (var doc in recordsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();

          print('✅ カテゴリ「$categoryName」に紐づく${recordsSnapshot.docs.length}件のレコードを削除しました');
        }
      }
    } catch (e) {
      print('❌ カスタムカテゴリ削除エラー: $e');
      rethrow;
    }
  }

  /// カテゴリの表示順を更新
  Future<void> reorderCustomCategories(List<Map<String, dynamic>> categories) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        final categoryId = category['id'] as String?;
        if (categoryId == null || categoryId.startsWith('default_')) continue;

        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('customCategories')
            .doc(categoryId);
        
        batch.update(docRef, {'order': i + 1});
      }

      await batch.commit();
      print('✅ カテゴリ並び替え完了');
    } catch (e) {
      print('❌ カテゴリ並び替えエラー: $e');
      rethrow;
    }
  }

  // ========================================
  // Plus限定機能：6ヶ月データ取得
  // ========================================

  /// 過去6ヶ月の統計データを取得（Plus限定機能）
  /// データが存在する月のみを返す
  Future<List<Map<String, dynamic>>> getSixMonthsData() async {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) return [];

    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final monthsData = <Map<String, dynamic>>[];

      // 過去6ヶ月分のデータを取得（データがある月のみ）
      for (int i = 5; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final month = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
        final monthLabel = '${targetDate.month}月';

        // その月の記録を取得
        final recordsSnapshot = await _firestore
            .collection('households')
            .doc(householdId)
            .collection('records')
            .where('month', isEqualTo: month)
            .get();

        // データが存在しない月はスキップ
        if (recordsSnapshot.docs.isEmpty) {
          continue;
        }

        int myCount = 0;
        int myTime = 0;
        int partnerCount = 0;
        int partnerTime = 0;

        for (var doc in recordsSnapshot.docs) {
          final data = doc.data();
          final memberId = data['memberId'] as String?;
          final timeMinutes = data['timeMinutes'] as int? ?? 0;

          if (memberId == user.uid) {
            myCount++;
            myTime += timeMinutes;
          } else {
            partnerCount++;
            partnerTime += timeMinutes;
          }
        }

        // バランススコアを計算（50%が理想、自分の割合を基準）
        final totalTime = myTime + partnerTime;
        final myRatio = totalTime > 0 ? (myTime / totalTime) : 0.5;
        final balanceScore = (myRatio * 100).round();

        monthsData.add({
          'month': month,
          'monthLabel': monthLabel,
          'myCount': myCount,
          'partnerCount': partnerCount,
          'myTime': myTime,
          'partnerTime': partnerTime,
          'balanceScore': balanceScore,
        });
      }

      return monthsData;
    } catch (e) {
      print('❌ 6ヶ月データ取得エラー: $e');
      return [];
    }
  }

  // ========================================
  // 感謝カード送信機能
  // ========================================

  /// 感謝カードを送信（gratitudeMessagesコレクション）
  Future<String> sendThanksCard({
    required String toUserId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    try {
      // householdIdを取得（セキュリティ強化）
      final householdId = await getCurrentUserHouseholdId();
      if (householdId == null) throw Exception('householdIdが取得できません');

      // 送信者名をニックネーム優先で取得
      final members = await getHouseholdMembers();
      final myMember = members.firstWhere(
        (m) => m['uid'] == user.uid,
        orElse: () => <String, dynamic>{},
      );
      final fromName = myMember['nickname'] as String? ?? 
                       myMember['name'] as String? ?? 
                       user.displayName ?? 
                       '未設定';

      // 受信者名をニックネーム優先で取得
      final partnerMember = members.firstWhere(
        (m) => m['uid'] == toUserId,
        orElse: () => <String, dynamic>{},
      );
      final toName = partnerMember['nickname'] as String? ?? 
                    partnerMember['name'] as String? ?? 
                    'パートナー';

      final docRef = await _firestore
          .collection('gratitudeMessages')
          .add({
        'householdId': householdId,  // ← 追加（セキュリティ強化）
        'fromUserId': user.uid,
        'fromUserName': fromName,
        'toUserId': toUserId,
        'toName': toName,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ 感謝カード送信: $fromName → $toName (household: $householdId)');
      return docRef.id;
    } catch (e) {
      print('❌ 感謝カード送信エラー: $e');
      rethrow;
    }
  }

  /// 未読の感謝カード件数を取得
  Future<int> getUnreadGratitudeCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gratitudeMessages')
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('❌ 未読件数取得エラー: $e');
      return 0;
    }
  }

  /// 全ての感謝カードを取得（自分宛て）
  Stream<QuerySnapshot> getMyGratitudeMessages(String userId) {
    return _firestore
        .collection('gratitudeMessages')
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 感謝カードを既読にする
  Future<void> markGratitudeAsRead(String messageId) async {
    try {
      await _firestore
          .collection('gratitudeMessages')
          .doc(messageId)
          .update({'isRead': true});

      print('✅ 感謝カードを既読にしました: $messageId');
    } catch (e) {
      print('❌ 感謝カード既読エラー: $e');
      rethrow;
    }
  }

  /// 自分宛ての未読メッセージを全て既読にする
  Future<void> markAllGratitudeAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gratitudeMessages')
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      print('✅ 全ての未読メッセージを既読にしました');
    } catch (e) {
      print('❌ 一括既読エラー: $e');
      rethrow;
    }
  }

  // ========================================
  // コスト記録機能
  // ========================================

  /// コストを記録
  Future<String> createCostRecord({
    required int amount,
    required String category,
    required String payer, // 'self' or 'partner'
    String memo = '',
    String usage = '', // 用途（何に使ったか）
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーが認証されていません');

    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) throw Exception('householdIdが取得できません');

    try {
      // メンバー情報を先に取得
      final members = await getHouseholdMembers();
      
      // payerがselfの場合は自分のuid、partnerの場合はパートナーのuidを取得
      String payerUid = user.uid;
      String payerName;
      
      if (payer == 'partner') {
        final partnerMember = members.firstWhere(
          (m) => m['uid'] != user.uid,
          orElse: () => {'uid': '', 'name': ''},
        );
        
        if (partnerMember['uid'] != '') {
          payerUid = partnerMember['uid'] as String;
          payerName = partnerMember['nickname'] as String? ?? 
                     partnerMember['name'] as String? ?? 
                     'パートナー';
        } else {
          payerName = 'パートナー';
        }
      } else {
        // 自分の名前をnicknameから取得
        final myMember = members.firstWhere(
          (m) => m['uid'] == user.uid,
          orElse: () => <String, dynamic>{},
        );
        payerName = myMember['nickname'] as String? ?? 
                   myMember['name'] as String? ?? 
                   user.displayName ?? 
                   user.email?.split('@')[0] ?? 
                   '未設定';
      }

      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final docRef = await _firestore
          .collection('households')
          .doc(householdId)
          .collection('costs')
          .add({
        'userId': payerUid,
        'payerName': payerName,
        'payer': payer,
        'category': category,
        'amount': amount,
        'memo': memo,
        'usage': usage, // 用途フィールドを追加
        'month': month,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ コスト記録作成: ¥$amount');
      return docRef.id;
    } catch (e) {
      print('❌ コスト記録作成エラー: $e');
      rethrow;
    }
  }

  /// 今月のコスト統計を取得
  Stream<Map<String, dynamic>> getMonthlyCoststats(String month) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield {};
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      yield {};
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('costs')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) {
      int myTotal = 0;
      int partnerTotal = 0;
      int totalCost = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final amount = data['amount'] as int? ?? 0;

        totalCost += amount;

        if (userId == user.uid) {
          myTotal += amount;
        } else {
          partnerTotal += amount;
        }
      }

      return {
        'myTotal': myTotal,
        'partnerTotal': partnerTotal,
        'totalCost': totalCost,
      };
    });
  }

  /// 最近のコスト記録を取得
  Stream<QuerySnapshot> getRecentCosts({int limit = 10}) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield* Stream.empty();
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('costs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
