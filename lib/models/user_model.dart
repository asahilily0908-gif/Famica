import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザー情報モデル
class UserModel {
  final String uid;
  final String displayName;
  final String nickname; // ★ nicknameフィールドを追加
  final String email;
  final String? householdId;
  final String role;
  final String lifeStage;
  final String plan;
  final DateTime? createdAt;
  final String? title; // 称号バッジ
  final int totalThanksReceived; // 受け取った感謝の総数

  UserModel({
    required this.uid,
    required this.displayName,
    String? nickname, // オプショナルで受け取る
    required this.email,
    this.householdId,
    this.role = '未設定',
    this.lifeStage = 'couple',
    this.plan = 'free',
    this.createdAt,
    this.title,
    this.totalThanksReceived = 0,
  }) : nickname = nickname ?? displayName; // nicknameがnullならdisplayNameを使用

  /// Firestoreドキュメントから UserModel を作成
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final displayName = data['displayName'] as String? ?? '未設定';
    final nickname = data['nickname'] as String?; // Firestoreからnicknameを取得
    
    return UserModel(
      uid: doc.id,
      displayName: displayName,
      nickname: nickname ?? displayName, // nicknameがnullならdisplayNameを使用
      email: data['email'] as String? ?? '',
      householdId: data['householdId'] as String?,
      role: data['role'] as String? ?? '未設定',
      lifeStage: data['lifeStage'] as String? ?? 'couple',
      plan: data['plan'] as String? ?? 'free',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      title: data['title'] as String?,
      totalThanksReceived: data['totalThanksReceived'] as int? ?? 0,
    );
  }

  /// Map形式に変換
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'nickname': nickname, // ★ nicknameを追加
      'email': email,
      'householdId': householdId,
      'role': role,
      'lifeStage': lifeStage,
      'plan': plan,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'title': title,
      'totalThanksReceived': totalThanksReceived,
    };
  }

  /// コピーを作成（一部フィールドを変更）
  UserModel copyWith({
    String? displayName,
    String? nickname,
    String? email,
    String? householdId,
    String? role,
    String? lifeStage,
    String? plan,
    DateTime? createdAt,
    String? title,
    int? totalThanksReceived,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname, // ★ nicknameを追加
      email: email ?? this.email,
      householdId: householdId ?? this.householdId,
      role: role ?? this.role,
      lifeStage: lifeStage ?? this.lifeStage,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      totalThanksReceived: totalThanksReceived ?? this.totalThanksReceived,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, nickname: $nickname, householdId: $householdId, role: $role)';
  }
}
