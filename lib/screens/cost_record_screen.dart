import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/common_context_menu.dart';
import '../widgets/unified_modal_styles.dart';

/// コスト記録画面（フルスクリーン）
class CostRecordScreen extends StatefulWidget {
  const CostRecordScreen({super.key});

  @override
  State<CostRecordScreen> createState() => _CostRecordScreenState();
}

class _CostRecordScreenState extends State<CostRecordScreen> {
  final _firestoreService = FirestoreService();
  final _amountController = TextEditingController();
  final _usageController = TextEditingController();
  
  String _selectedPayer = 'self'; // 'self' or 'partner'
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'コストを記録',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          // 保存ボタン（ヘッダー）
          TextButton(
            onPressed: _isLoading ? null : _saveCost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: UnifiedModalStyles.primaryPink,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 金額入力
              const Text('金額', style: UnifiedModalStyles.labelStyle),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: UnifiedModalStyles.textFieldDecoration(
                  hintText: '1000',
                  prefixIcon: const Icon(
                    Icons.currency_yen,
                    color: UnifiedModalStyles.primaryPink,
                  ),
                ),
                contextMenuBuilder: buildFamicaContextMenu,
              ),
              const SizedBox(height: 24),

              // 用途入力（新機能）
              const Text('用途', style: UnifiedModalStyles.labelStyle),
              const SizedBox(height: 12),
              TextField(
                controller: _usageController,
                maxLength: 50,
                decoration: UnifiedModalStyles.textFieldDecoration(
                  hintText: '例：食材、日用品、交通費など',
                  prefixIcon: const Icon(
                    Icons.edit,
                    color: UnifiedModalStyles.primaryPink,
                  ),
                ),
                contextMenuBuilder: buildFamicaContextMenu,
              ),
              const SizedBox(height: 24),

              // 支払った人
              const Text('支払った人', style: UnifiedModalStyles.labelStyle),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, String>>(
                future: _getPayerNames(),
                builder: (context, snapshot) {
                  final myName = snapshot.data?['myName'] ?? 'あなた';
                  final partnerName = snapshot.data?['partnerName'] ?? 'パートナー';

                  return Row(
                    children: [
                      Expanded(
                        child: UnifiedSelectionButton(
                          text: myName,
                          isSelected: _selectedPayer == 'self',
                          onTap: () => setState(() => _selectedPayer = 'self'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: UnifiedSelectionButton(
                          text: partnerName,
                          isSelected: _selectedPayer == 'partner',
                          onTap: () => setState(() => _selectedPayer = 'partner'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _getPayerNames() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'myName': 'あなた', 'partnerName': 'パートナー'};
      }

      final householdId = await _firestoreService.getCurrentUserHouseholdId();
      if (householdId == null) {
        return {'myName': 'あなた', 'partnerName': 'パートナー'};
      }

      final members = await _firestoreService.getHouseholdMembers();
      
      String myName = 'あなた';
      String partnerName = 'パートナー';

      for (var member in members) {
        if (member['uid'] == user.uid) {
          myName = member['displayName'] as String? ?? 'あなた';
        } else {
          partnerName = member['displayName'] as String? ?? 'パートナー';
        }
      }

      return {'myName': myName, 'partnerName': partnerName};
    } catch (e) {
      return {'myName': 'あなた', 'partnerName': 'パートナー'};
    }
  }

  Future<void> _saveCost() async {
    final amountText = _amountController.text.trim();
    final usage = _usageController.text.trim();
    
    if (amountText.isEmpty) {
      _showError('金額を入力してください');
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('正しい金額を入力してください');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createCostRecord(
        amount: amount,
        category: 'その他', // デフォルトカテゴリ
        payer: _selectedPayer,
        memo: usage, // 用途をmemoとして保存
        usage: usage, // 用途フィールドを追加
      );

      if (!mounted) return;

      Navigator.pop(context, true); // trueを返して保存成功を通知

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💰 コストを記録しました'),
          backgroundColor: UnifiedModalStyles.primaryPink,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('保存に失敗しました: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
