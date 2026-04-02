import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../constants/famica_colors.dart';
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

  AppLocalizations get l => AppLocalizations.of(context)!;

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
        SnackBar(
          content: Text(l.nicknameEmpty),
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
          SnackBar(
            content: Text(l.nicknameSaved),
            backgroundColor: UnifiedModalStyles.primaryPink,
            duration: const Duration(seconds: 2),
          ),
        );
        // 保存成功後、前の画面に戻る
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.settingsNicknameError}: $e'),
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
    return Container(
      decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.nicknameChangeTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ニックネームラベル
                    Text(l.nicknameLabel, style: UnifiedModalStyles.labelStyle),
                    const SizedBox(height: 12),

                    // TextField
                    TextField(
                      controller: _nicknameController,
                      decoration: UnifiedModalStyles.textFieldDecoration(
                        hintText: l.nicknameInputHint,
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
                    l.nicknameNote,
                    style: UnifiedModalStyles.captionStyle,
                  ),
                  const SizedBox(height: 32),

                  // 保存ボタン
                  UnifiedSaveButton(
                    text: l.settingsSaveChanges,
                    onPressed: _saveNickname,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
