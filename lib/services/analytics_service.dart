import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Famica Phase 5: 分析・集計サービス
/// memberIdごとの記録集計、時間・回数の計算を担当
///
/// ⚠️ 現在未使用 - 将来の統計機能強化で使用予定
/// - メンバー別詳細統計
/// - 高度な分析機能（トレンド分析、予測など）
/// - ダッシュボード表示用の集計データ
/// - 現在はFirestoreServiceで直接クエリしているが、
///   将来的にこのサービスに統合予定
class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーのhouseholdIdを取得
  Future<String?> getCurrentUserHouseholdId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['householdId'] as String?;
      }
      return user.uid;
    } catch (e) {
      print('❌ householdId取得エラー: $e');
      return user.uid;
    }
  }

  /// 指定月のメンバー別集計データを取得
  /// Stream<Map<String, MemberStats>> を返す
  Stream<Map<String, MemberStats>> getMemberStatsForMonth(String month) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield {};
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .where('month', isEqualTo: month)
        .snapshots()
        .asyncMap((snapshot) async {
      // メンバー情報を取得
      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();
      
      final members = List<Map<String, dynamic>>.from(
          householdDoc.data()?['members'] ?? []);

      // メンバーごとに集計
      final Map<String, MemberStats> stats = {};

      for (final member in members) {
        final memberId = member['uid'] as String;
        final memberName = member['name'] as String;
        
        stats[memberId] = MemberStats(
          memberId: memberId,
          memberName: memberName,
          totalMinutes: 0,
          totalCount: 0,
          categoryBreakdown: {},
        );
      }

      // 記録を集計
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String;
        final timeMinutes = data['timeMinutes'] as int;
        final category = data['category'] as String? ?? 'その他';

        if (stats.containsKey(memberId)) {
          stats[memberId]!.totalMinutes += timeMinutes;
          stats[memberId]!.totalCount += 1;
          
          // カテゴリ別集計
          stats[memberId]!.categoryBreakdown[category] = 
              (stats[memberId]!.categoryBreakdown[category] ?? 0) + timeMinutes;
        }
      }

      return stats;
    });
  }

  /// 全期間のメンバー別集計データを取得
  Stream<Map<String, MemberStats>> getAllTimeMemberStats() async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield {};
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .snapshots()
        .asyncMap((snapshot) async {
      // メンバー情報を取得
      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();
      
      final members = List<Map<String, dynamic>>.from(
          householdDoc.data()?['members'] ?? []);

      // メンバーごとに集計
      final Map<String, MemberStats> stats = {};

      for (final member in members) {
        final memberId = member['uid'] as String;
        final memberName = member['name'] as String;
        
        stats[memberId] = MemberStats(
          memberId: memberId,
          memberName: memberName,
          totalMinutes: 0,
          totalCount: 0,
          categoryBreakdown: {},
        );
      }

      // 記録を集計
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String;
        final timeMinutes = data['timeMinutes'] as int;
        final category = data['category'] as String? ?? 'その他';

        if (stats.containsKey(memberId)) {
          stats[memberId]!.totalMinutes += timeMinutes;
          stats[memberId]!.totalCount += 1;
          
          // カテゴリ別集計
          stats[memberId]!.categoryBreakdown[category] = 
              (stats[memberId]!.categoryBreakdown[category] ?? 0) + timeMinutes;
        }
      }

      return stats;
    });
  }

  /// カテゴリ別集計（全メンバー合計）
  Stream<Map<String, int>> getCategoryStatsForMonth(String month) async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield {};
      return;
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> categoryStats = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'その他';
        final timeMinutes = data['timeMinutes'] as int;

        categoryStats[category] = 
            (categoryStats[category] ?? 0) + timeMinutes;
      }

      return categoryStats;
    });
  }

  /// 月別推移データの取得（直近6ヶ月）
  Stream<List<MonthlyTotal>> getMonthlyTrend() async* {
    final householdId = await getCurrentUserHouseholdId();
    if (householdId == null) {
      yield [];
      return;
    }

    // 直近6ヶ月のリストを生成
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }

    yield* _firestore
        .collection('households')
        .doc(householdId)
        .collection('records')
        .where('month', whereIn: months)
        .snapshots()
        .map((snapshot) {
      final Map<String, int> monthlyTotals = {};

      for (final month in months) {
        monthlyTotals[month] = 0;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final month = data['month'] as String;
        final timeMinutes = data['timeMinutes'] as int;

        if (monthlyTotals.containsKey(month)) {
          monthlyTotals[month] = monthlyTotals[month]! + timeMinutes;
        }
      }

      return months.map((month) {
        return MonthlyTotal(
          month: month,
          totalMinutes: monthlyTotals[month] ?? 0,
        );
      }).toList();
    });
  }

  /// 比率計算（パーセント）
  double calculatePercentage(int value, int total) {
    if (total == 0) return 0.0;
    return (value / total) * 100;
  }

  /// 時間を「○時間○分」形式に変換
  String formatMinutesToHours(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours == 0) {
      return '$mins分';
    } else if (mins == 0) {
      return '$hours時間';
    } else {
      return '$hours時間$mins分';
    }
  }
}

/// メンバー別統計データ
class MemberStats {
  final String memberId;
  final String memberName;
  int totalMinutes;
  int totalCount;
  Map<String, int> categoryBreakdown;

  MemberStats({
    required this.memberId,
    required this.memberName,
    required this.totalMinutes,
    required this.totalCount,
    required this.categoryBreakdown,
  });

  /// 時間を「○時間○分」形式で取得
  String get formattedTime {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    
    if (hours == 0) {
      return '$mins分';
    } else if (mins == 0) {
      return '$hours時間';
    } else {
      return '$hours時間$mins分';
    }
  }

  /// 平均時間（分）
  double get averageMinutes {
    if (totalCount == 0) return 0.0;
    return totalMinutes / totalCount;
  }
}

/// 月別合計データ
class MonthlyTotal {
  final String month;
  final int totalMinutes;

  MonthlyTotal({
    required this.month,
    required this.totalMinutes,
  });

  /// 時間を「○時間」形式で取得
  String get formattedTime {
    final hours = totalMinutes ~/ 60;
    return '$hours時間';
  }

  /// 月を「○月」形式で取得
  String get monthLabel {
    final parts = month.split('-');
    if (parts.length == 2) {
      return '${int.parse(parts[1])}月';
    }
    return month;
  }
}
