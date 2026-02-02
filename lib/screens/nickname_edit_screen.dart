import 'package:flutter/material.dart';
import '../widgets/common_context_menu.dart';
import '../widgets/unified_modal_styles.dart';
import '../services/firestore_service.dart';

/// ニックネーム変更画面
class NicknameEditScreen extends StatefulWidget {
  const NicknameEditScreen({super.key});

  @override
  State<NicknameEditScreen> createState() => _NicknameEditScreenState();
}

class _NicknameEditScreenState extends State<NicknameEditScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadNickname() async {
    setState(() => _isLoading = true);
    
    final nickname = await _firestoreService.getMyNickname();
    if (nickname != null && mounted) {
      setState(() {
        _nicknameController.text = nickname;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ニックネームを入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestoreService.updateMyNickname(nickname);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 変更を保存しました'),
            backgroundColor: UnifiedModalStyles.primaryPink,
            duration: Duration(seconds: 2),
          ),
        );
        // 保存成功後、前の画面に戻る
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ エラーが発生しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ニックネーム変更',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ニックネームラベル
                  const Text('ニックネーム', style: UnifiedModalStyles.labelStyle),
                  const SizedBox(height: 12),
                  
                  // TextField
                  TextField(
                    controller: _nicknameController,
                    decoration: UnifiedModalStyles.textFieldDecoration(
                      hintText: 'ニックネームを入力',
                      prefixIcon: const Icon(
                        Icons.person,
                        color: UnifiedModalStyles.primaryPink,
                      ),
                    ),
                    maxLength: 20,
                    autofocus: true,
                    contextMenuBuilder: buildFamicaContextMenu,
                  ),
                  const SizedBox(height: 12),
                  
                  // 説明テキスト
                  Text(
                    'ℹ️ ニックネームは全画面で即時反映されます',
                    style: UnifiedModalStyles.captionStyle,
                  ),
                  const SizedBox(height: 32),
                  
                  // 保存ボタン
                  UnifiedSaveButton(
                    text: '変更を保存',
                    onPressed: _saveNickname,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
    );
  }
}
