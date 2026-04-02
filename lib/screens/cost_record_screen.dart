import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../constants/famica_colors.dart';
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

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _amountController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            l.costRecordTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.transparent,
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
                : Text(
                    l.save,
                    style: const TextStyle(
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
              Text(l.costRecordAmount, style: UnifiedModalStyles.labelStyle),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: UnifiedModalStyles.textFieldDecoration(
                  hintText: l.costRecordAmountHint,
                  prefixIcon: const Icon(
                    Icons.currency_yen,
                    color: UnifiedModalStyles.primaryPink,
                  ),
                ),
                contextMenuBuilder: buildFamicaContextMenu,
              ),
              const SizedBox(height: 24),

              // 用途入力（新機能）
              Text(l.costRecordPurpose, style: UnifiedModalStyles.labelStyle),
              const SizedBox(height: 12),
              TextField(
                controller: _usageController,
                maxLength: 50,
                decoration: UnifiedModalStyles.textFieldDecoration(
                  hintText: l.costRecordPurposeHint,
                  prefixIcon: const Icon(
                    Icons.edit,
                    color: UnifiedModalStyles.primaryPink,
                  ),
                ),
                contextMenuBuilder: buildFamicaContextMenu,
              ),
              const SizedBox(height: 24),

              // 支払った人
              Text(l.costRecordPayer, style: UnifiedModalStyles.labelStyle),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, String>>(
                future: _getPayerNames(),
                builder: (context, snapshot) {
                  final myName = snapshot.data?['myName'] ?? l.you;
                  final partnerName = snapshot.data?['partnerName'] ?? l.partner;

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
      ),
    );
  }

  Future<Map<String, String>> _getPayerNames() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'myName': l.you, 'partnerName': l.partner};
      }

      final householdId = await _firestoreService.getCurrentUserHouseholdId();
      if (householdId == null) {
        return {'myName': l.you, 'partnerName': l.partner};
      }

      final members = await _firestoreService.getHouseholdMembers();

      String myName = l.you;
      String partnerName = l.partner;

      for (var member in members) {
        if (member['uid'] == user.uid) {
          myName = member['displayName'] as String? ?? l.you;
        } else {
          partnerName = member['displayName'] as String? ?? l.partner;
        }
      }

      return {'myName': myName, 'partnerName': partnerName};
    } catch (e) {
      return {'myName': l.you, 'partnerName': l.partner};
    }
  }

  Future<void> _saveCost() async {
    final amountText = _amountController.text.trim();
    final usage = _usageController.text.trim();

    if (amountText.isEmpty) {
      _showError(l.costRecordEmptyAmount);
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError(l.costRecordInvalidAmount);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createCostRecord(
        amount: amount,
        category: l.other, // デフォルトカテゴリ
        payer: _selectedPayer,
        memo: usage, // 用途をmemoとして保存
        usage: usage, // 用途フィールドを追加
      );

      if (!mounted) return;

      Navigator.pop(context, true); // trueを返して保存成功を通知

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.costRecordSuccess),
          backgroundColor: UnifiedModalStyles.primaryPink,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('${l.costRecordFailed}: $e');
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
