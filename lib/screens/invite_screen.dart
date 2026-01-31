import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famica/services/household_service.dart';
import 'package:famica/services/invite_service.dart';

/// 招待URL経由で遷移された際の招待受諾画面
class InviteScreen extends StatefulWidget {
  final String householdId;

  const InviteScreen({
    super.key,
    required this.householdId,
  });

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final HouseholdService _householdService = HouseholdService();
  final InviteService _inviteService = InviteService();
  bool _isLoading = true;
  bool _isJoining = false;
  Map<String, dynamic>? _householdInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHouseholdInfo();
  }

  /// 世帯情報を読み込み
  Future<void> _loadHouseholdInfo() async {
    try {
      final info = await _householdService.getHouseholdInfo(widget.householdId);
      
      if (info == null) {
        setState(() {
          _errorMessage = '招待リンクが無効です';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _householdInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '世帯情報の取得に失敗しました';
        _isLoading = false;
      });
    }
  }

  /// 世帯への参加処理
  Future<void> _joinHousehold() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // 未ログインの場合は認証画面へ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('先にログインしてください')),
        );
        Navigator.of(context).pushReplacementNamed('/auth');
      }
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // InviteServiceを使用して世帯に参加
      await _inviteService.joinHouseholdById(
        householdId: widget.householdId,
        userId: user.uid,
        userName: user.displayName ?? 'ゲスト',
        userEmail: user.email ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_householdInfo!['name']}に参加しました！'),
            backgroundColor: Colors.green,
          ),
        );
        
        // メイン画面へ遷移
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('参加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ファミリーに参加'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      );
    }

    // 世帯情報を表示
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.family_restroom,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            '${_householdInfo!['name']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'への参加招待を受け取りました',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'メンバー',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildMemberList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isJoining ? null : _joinHousehold,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: _isJoining
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '参加する',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// メンバーリストを構築
  List<Widget> _buildMemberList() {
    final members = _householdInfo!['members'] as List<dynamic>? ?? [];
    
    if (members.isEmpty) {
      return [
        const Text(
          'メンバーがいません',
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }

    return members.map((member) {
      final nickname = member['nickname'] ?? member['name'] ?? '不明';
      final role = member['role'] ?? '';
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                nickname.isNotEmpty ? nickname[0] : '?',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
