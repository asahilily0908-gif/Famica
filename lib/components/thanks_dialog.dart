import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../constants/famica_colors.dart';

/// Famica Phase 1-B: 感謝ダイアログ
/// 記録に対して感謝を送信するUI
class ThanksDialog extends StatefulWidget {
  final String recordId;
  final String toUid;
  final String toName;
  final String task;
  final int timeMinutes;

  const ThanksDialog({
    super.key,
    required this.recordId,
    required this.toUid,
    required this.toName,
    required this.task,
    required this.timeMinutes,
  });

  @override
  State<ThanksDialog> createState() => _ThanksDialogState();
}

class _ThanksDialogState extends State<ThanksDialog>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();

  String? _selectedEmoji;
  bool _isLoading = false;

  // 利用可能な絵文字
  final List<String> _emojis = ['👍', '❤️', '🙏', '🌟', '✨', '🎉'];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendThanks() async {
    if (_selectedEmoji == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('絵文字を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firestoreに感謝を保存
      await _firestoreService.sendThanks(
        recordId: widget.recordId,
        toUid: widget.toUid,
        toName: widget.toName,
        emoji: _selectedEmoji!,
        message: _messageController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // 成功アニメーション
      await _showSuccessAnimation();

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('送信に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSuccessAnimation() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: FamicaColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  '送信しました！',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        insetPadding: EdgeInsets.zero, // デフォルトの余白を完全削除
        backgroundColor: Colors.transparent, // カード部分だけ描画するため
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.95, // ← 横幅95%を絶対に適用
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const Icon(
                Icons.favorite,
                size: 48,
                color: FamicaColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'ありがとうを伝えよう 💕',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: FamicaColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.toName}さんが${widget.task}をしました',
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 16,
                  color: FamicaColors.textLight,
                ),
              ),
              Text(
                '（${widget.timeMinutes}分）',
                style: const TextStyle(
                  fontSize: 14,
                  color: FamicaColors.textLight,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '気持ちを選んでください：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: FamicaColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _emojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? FamicaColors.primary.withOpacity(0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? FamicaColors.primary
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'メッセージ（任意）：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: FamicaColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLength: 100,
                  maxLines: 3,
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                    hintText: 'ありがとう！',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB7D5),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFB7D5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: FamicaColors.primary,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendThanks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FamicaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '送信する',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 感謝ダイアログを表示するヘルパー関数
Future<bool?> showThanksDialog({
  required BuildContext context,
  required String recordId,
  required String toUid,
  required String toName,
  required String task,
  required int timeMinutes,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ThanksDialog(
      recordId: recordId,
      toUid: toUid,
      toName: toName,
      task: task,
      timeMinutes: timeMinutes,
    ),
  );
}
