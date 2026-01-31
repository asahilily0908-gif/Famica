import 'package:flutter/material.dart';
import '../widgets/common_context_menu.dart';
import 'package:flutter/services.dart';
import '../widgets/common_context_menu.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/common_context_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_context_menu.dart';
import '../services/invite_service.dart';
import '../widgets/common_context_menu.dart';
import '../constants/famica_colors.dart';
import '../widgets/common_context_menu.dart';

/// Famica Phase 1-A: 家族招待画面
/// 招待コード表示・共有・参加機能
class FamilyInviteScreen extends StatefulWidget {
  const FamilyInviteScreen({super.key});

  @override
  State<FamilyInviteScreen> createState() => _FamilyInviteScreenState();
}

class _FamilyInviteScreenState extends State<FamilyInviteScreen> {
  final InviteService _inviteService = InviteService();
  final TextEditingController _inviteCodeController = TextEditingController();
  
  String? _myInviteCode;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _showJoinCard = false;

  @override
  void initState() {
    super.initState();
    _loadInviteInfo();
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadInviteInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final inviteInfo = await _inviteService.getCurrentUserInviteInfo();
      final members = await _inviteService.getHouseholdMembers();
      
      // 招待コードが存在しない場合は自動生成
      String? inviteCode = inviteInfo?['inviteCode'];
      final householdId = inviteInfo?['householdId'];
      
      if (householdId != null && (inviteCode == null || inviteCode.isEmpty)) {
        print('⚠️ 招待コードが存在しないため自動生成します');
        inviteCode = await _inviteService.generateUniqueInviteCode();
        
        // Firestoreに招待コードを保存
        await FirebaseFirestore.instance
            .collection('households')
            .doc(householdId)
            .update({'inviteCode': inviteCode});
        
        // inviteCodesコレクションにもドキュメントを作成
        await _inviteService.createInviteCodeDocument(inviteCode, householdId);
        
        print('✅ 招待コード生成完了: $inviteCode');
      }
      
      setState(() {
        _myInviteCode = inviteCode;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 招待情報読み込みエラー: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyInviteCode() async {
    if (_myInviteCode == null) return;
    
    await Clipboard.setData(ClipboardData(text: _myInviteCode!));
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('招待コードをコピーしました'),
        duration: Duration(seconds: 2),
        backgroundColor: FamicaColors.primary,
      ),
    );
  }

  Future<void> _shareInviteLink() async {
    if (_myInviteCode == null) return;
    
    final inviteText = _inviteService.generateInviteLink(_myInviteCode!);
    
    try {
      await Share.share(
        inviteText,
        subject: 'Famicaに招待します',
      );
    } catch (e) {
      print('❌ 共有エラー: $e');
    }
  }

  Future<void> _joinHousehold() async {
    final inviteCode = _inviteCodeController.text.trim().toUpperCase();
    
    if (inviteCode.length != 6) {
      _showErrorDialog('招待コードは6桁です');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _inviteService.joinHouseholdByInviteCode(
        inviteCode,
        memberName: 'パートナー',
        role: 'パートナー',
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 参加しました！'),
            backgroundColor: FamicaColors.primary,
          ),
        );
        
        _loadInviteInfo();
        setState(() => _showJoinCard = false);
      } else {
        // エラーメッセージを取得
        final errorMessage = result['message'] as String? ?? '招待コードが無効です';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('参加に失敗しました: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: const Text(
          'パートナーを招待',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(FamicaColors.primary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_myInviteCode != null) ...[
                      _buildInviteCodeCard(),
                      const SizedBox(height: 16),
                      _buildMembersCard(),
                      const SizedBox(height: 16),
                    ],
                    if (_showJoinCard) ...[
                      _buildJoinHouseholdCard(),
                      const SizedBox(height: 16),
                    ],
                    if (!_showJoinCard && _myInviteCode == null)
                      _buildNoHouseholdCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInviteCodeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.favorite,
            size: 36,
            color: FamicaColors.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'パートナーをFamicaに招待しましょう！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: FamicaColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'あなたの招待コード',
            style: TextStyle(
              fontSize: 14,
              color: FamicaColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _myInviteCode ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: FamicaColors.primary,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyInviteCode,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('コピー'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FamicaColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(
                      color: FamicaColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareInviteLink,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('共有'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FamicaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'メンバー',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FamicaColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (_members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'まだメンバーがいません',
                style: TextStyle(color: FamicaColors.textLight),
              ),
            )
          else
            ..._members.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(height: 1, thickness: 0.5),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF5F5F5),
                          child: Text(
                            (member['displayName'] ?? member['name'] ?? '?').substring(0, 1),
                            style: const TextStyle(
                              color: FamicaColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['displayName'] ?? member['name'] ?? '未設定',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: FamicaColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member['role'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: FamicaColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildJoinHouseholdCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const Icon(
            Icons.group_add,
            size: 48,
            color: FamicaColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            '招待コードを入力',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FamicaColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'パートナーから受け取った\n6桁のコードを入力してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: FamicaColors.textLight,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _inviteCodeController,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: 'ABC123',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: FamicaColors.primary,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: FamicaColors.primary,
                  width: 2,
                ),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _showJoinCard = false);
                    _inviteCodeController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: FamicaColors.textLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('キャンセル'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _joinHousehold,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FamicaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('参加する'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoHouseholdCard() {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Column(
        children: [
          Icon(
            Icons.group_add,
            size: 64,
            color: FamicaColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'まだパートナーがいません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: FamicaColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'パートナーから招待コードを\n受け取って参加しましょう',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: FamicaColors.textLight.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _showJoinCard = true);
            },
            icon: const Icon(Icons.vpn_key, size: 20),
            label: const Text('招待コードを入力'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FamicaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
