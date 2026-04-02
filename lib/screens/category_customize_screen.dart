import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../constants/famica_colors.dart';
import '../widgets/common_context_menu.dart';
import '../widgets/unified_modal_styles.dart';

/// カテゴリカスタマイズ画面
class CategoryCustomizeScreen extends StatefulWidget {
  const CategoryCustomizeScreen({super.key});

  @override
  State<CategoryCustomizeScreen> createState() => _CategoryCustomizeScreenState();
}

class _CategoryCustomizeScreenState extends State<CategoryCustomizeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _firestoreService.getUserCustomCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('${l.categoryLoadFailed}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: FamicaColors.appBackgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            l.categoryEditTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _categories.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryItem(category, index);
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: FamicaColors.accent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l.categoryEmpty, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(l.categoryEmptyHint, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index) {
    final id = category['id'] as String;
    final name = category['name'] as String? ?? '';
    final emoji = category['emoji'] as String? ?? '📝';
    final minutes = category['defaultMinutes'] as int? ?? 30;

    // Default categories are part of app definition.
    // They cannot be deleted by design.
    final isDefault = id.startsWith('default_');

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FamicaColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
        title: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.quickRecordMinutes(minutes), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            if (isDefault) ...[
              const SizedBox(height: 4),
              Text(
                l.categoryStandardNote,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: FamicaColors.accent,
              onPressed: () => _showEditDialog(category),
            ),
            // デフォルトカテゴリは削除ボタンを表示しない
            if (!isDefault)
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red[400],
                onPressed: () => _confirmDelete(id, name),
              ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });
    _saveOrder();
  }

  Future<void> _saveOrder() async {
    try {
      await _firestoreService.reorderCustomCategories(_categories);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.categoryOrderSaved), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      _showError('${l.orderSaveFailed}: $e');
    }
  }

  void _showAddDialog() {
    if (_categories.length >= 12) {
      _showError(l.categoryMaxReached);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _CategoryDialog(
        onSave: (name, emoji, minutes) async {
          // ダイアログを先に閉じる
          Navigator.of(dialogContext).pop();

          try {
            await _firestoreService.addCustomCategory(
              name: name,
              emoji: emoji,
              defaultMinutes: minutes,
              order: _categories.length + 1,
            );
            if (!mounted) return;

            await _loadCategories();
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.categoryAdded)),
            );
          } catch (e) {
            if (!mounted) return;
            _showError('${l.addFailed}: $e');
          }
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> category) {
    final id = category['id'] as String;
    final isDefault = id.startsWith('default_');

    showDialog(
      context: context,
      builder: (dialogContext) => _CategoryDialog(
        initialName: category['name'] as String? ?? '',
        initialEmoji: category['emoji'] as String? ?? '📝',
        initialMinutes: category['defaultMinutes'] as int? ?? 30,
        isDefault: isDefault,
        onSave: (name, emoji, minutes) async {
          // ダイアログを先に閉じる
          Navigator.of(dialogContext).pop();

          try {
            if (isDefault) {
              // デフォルトカテゴリを編集：overridesDefaultIdフィールド付きで新規追加
              await _firestoreService.addCustomCategory(
                name: name,
                emoji: emoji,
                defaultMinutes: minutes,
                order: category['order'] as int? ?? _categories.length + 1,
                overridesDefaultId: id, // デフォルトカテゴリのIDを渡す
              );
            } else {
              // カスタムカテゴリを編集：updateを使用
              await _firestoreService.updateCustomCategory(
                categoryId: id,
                name: name,
                emoji: emoji,
                defaultMinutes: minutes,
              );
            }

            // 成功後の処理（親のcontextを使用）
            if (!mounted) return;
            await _loadCategories();

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.categoryUpdated)),
            );
          } catch (e) {
            if (!mounted) return;
            _showError('${l.updateFailed}: $e');
          }
        },
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l.categoryDeleteConfirm),
          content: Text(l.categoryDeleteNote),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCategory(id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await _firestoreService.deleteCustomCategory(id);
      await _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.categoryDeleted)));
      }
    } catch (e) {
      _showError('${l.deleteFailed}: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }
}

/// カテゴリ追加・編集ダイアログ
class _CategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialEmoji;
  final int? initialMinutes;
  final bool isDefault;
  final Function(String name, String emoji, int minutes) onSave;

  const _CategoryDialog({
    this.initialName,
    this.initialEmoji,
    this.initialMinutes,
    this.isDefault = false,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _minutesController;
  String _selectedEmoji = '';

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedEmoji = widget.initialEmoji ?? '';
    _minutesController = TextEditingController(text: (widget.initialMinutes ?? 30).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Container(
        width: screenWidth * 0.90,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              children: [
                const Icon(Icons.category, color: UnifiedModalStyles.primaryPink, size: 24),
                const SizedBox(width: 12),
                Text(
                  isEdit ? l.categoryEditTitle : l.categoryAddTitle,
                  style: UnifiedModalStyles.titleStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 絵文字選択
            Text(l.categoryEmoji, style: UnifiedModalStyles.labelStyle),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _showIconPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: UnifiedModalStyles.modalBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: UnifiedModalStyles.pinkBorder.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: UnifiedModalStyles.pinkBorder, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: UnifiedModalStyles.pinkBorder.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji.isEmpty ? '?' : _selectedEmoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 16, color: UnifiedModalStyles.captionStyle.color),
                          const SizedBox(width: 6),
                          Text(l.categorySelectEmoji, style: UnifiedModalStyles.captionStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // カテゴリ名
            Text(l.categoryName, style: UnifiedModalStyles.labelStyle),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: UnifiedModalStyles.textFieldDecoration(
                hintText: l.categoryNameHint,
              ),
              maxLength: 20,
              contextMenuBuilder: buildFamicaContextMenu,
            ),
            const SizedBox(height: 20),

            // 所要時間
            Text(l.categoryDuration, style: UnifiedModalStyles.labelStyle),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showTimeSelectionDialog,
              child: AbsorbPointer(
                child: TextField(
                  controller: _minutesController,
                  readOnly: true,
                  decoration: UnifiedModalStyles.textFieldDecoration(
                    hintText: '30',
                    suffixIcon: const Icon(Icons.arrow_drop_down, color: UnifiedModalStyles.primaryPink),
                  ),
                  contextMenuBuilder: buildFamicaContextMenu,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ボタン
            UnifiedSaveButton(
              text: l.settingsSaveChanges,
              onPressed: _save,
            ),
            const SizedBox(height: 12),
            UnifiedCancelButton(),
          ],
        ),
      ),
    ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final l = AppLocalizations.of(context)!;

        return Container(
          width: screenWidth,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.75,
            maxWidth: screenWidth,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // タイトル
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UnifiedModalStyles.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apps, color: UnifiedModalStyles.primaryPink, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(l.categorySelectEmojiTitle, style: UnifiedModalStyles.titleStyle),
                  ],
                ),
              ),

              // アイコングリッド
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: FamicaIcons.allIcons.length,
                    itemBuilder: (context, index) {
                      final emoji = FamicaIcons.allIcons[index];
                      final isSelected = emoji == _selectedEmoji;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedEmoji = emoji);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? UnifiedModalStyles.primaryPink.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? UnifiedModalStyles.primaryPink
                                  : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: UnifiedModalStyles.primaryPink.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: TextStyle(
                                fontSize: isSelected ? 28 : 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTimeSelectionDialog() {
    final timeOptions = [5, 10, 15, 20, 30, 45, 60, 90, 120];
    final currentMinutes = int.tryParse(_minutesController.text) ?? 30;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final l = AppLocalizations.of(context)!;

        return Container(
          width: screenWidth,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.7,
            maxWidth: screenWidth,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // タイトル
              Row(
                children: [
                  const Icon(Icons.timer, color: UnifiedModalStyles.primaryPink, size: 24),
                  const SizedBox(width: 12),
                  Text(l.categorySelectDuration, style: UnifiedModalStyles.titleStyle),
                ],
              ),
              const SizedBox(height: 20),

              // スクロール可能なリスト
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: timeOptions.map((minutes) {
                      final isSelected = minutes == currentMinutes;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: UnifiedModalStyles.itemCardDecoration,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          title: Text(
                            l.quickRecordMinutes(minutes),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? UnifiedModalStyles.primaryPink : UnifiedModalStyles.textDark,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: UnifiedModalStyles.primaryPink)
                              : null,
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              _minutesController.text = minutes.toString();
                            });
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final minutesText = _minutesController.text.trim();

    if (name.isEmpty) {
      _showError(l.categoryNameEmpty);
      return;
    }
    if (_selectedEmoji.isEmpty) {
      _showError(l.categoryEmojiEmpty);
      return;
    }
    final minutes = int.tryParse(minutesText);
    if (minutes == null || minutes <= 0) {
      _showError(l.categoryInvalidTime);
      return;
    }

    // バリデーション成功後、コールバックを実行
    // ダイアログを閉じるのはコールバック側で行う
    widget.onSave(name, _selectedEmoji, minutes);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}

/// 🎨 Famica アイコンリスト
///
/// 新しいアイコンを追加する方法:
/// 1. 下記のリストに絵文字を追加するだけ！
/// 2. カテゴリコメントで整理しておくと便利
class FamicaIcons {
  static const List<String> allIcons = [
    // 料理・食事
    '🍳', '🍽', '🥘', '🍱', '🥗', '🍜', '🍲', '🥞', '🧆', '🥙',
    '🍕', '🍔', '🌮', '🌯', '🥪', '🍝', '🍛', '🍣', '🍤', '🥟',

    // 洗濯・掃除
    '🧺', '🧼', '🧽', '🧴', '🧹', '🧻', '🪣', '🛁', '🚿', '💧',
    '🧽', '🪟', '🚪', '🛋', '🛏', '🪑', '🚰', '💦', '🫧', '✨',

    // 買い物
    '🛒', '🛍', '🏪', '🎁', '📦', '🎀', '💰', '💳', '💵', '💴',
    '🏬', '🏪', '🏢', '🛍️', '🎊', '🎉', '🎈', '🎁', '🎀', '📦',

    // ゴミ・リサイクル
    '🚮', '🗑', '♻️', '📮', '📪', '📬', '📭', '📫', '🗄', '🗃',

    // 育児・子育て
    '👶', '🍼', '🧸', '🎈', '🎨', '📚', '🎒', '🏫', '👪', '🤱',
    '👨‍👩‍👧', '👨‍👩‍👦', '🧒', '👧', '👦', '🎓', '📖', '✏️', '🖍', '🎭',

    // 交通・移動
    '🚗', '🚕', '🚙', '🚌', '🚎', '🚐', '🚑', '🚒', '🚓', '🚔',
    '🚖', '🚘', '🚛', '🚜', '🚲', '🛴', '🛵', '🏍', '🚂', '🚃',

    // 仕事・事務
    '🧾', '📅', '📝', '📄', '📃', '📑', '📊', '📈', '📉', '💼',
    '📋', '📌', '📍', '✂️', '📐', '📏', '📎', '🖇', '📁', '📂',

    // 愛情・コミュニケーション
    '❤️', '💌', '💐', '🌸', '🌺', '🌻', '🌷', '🌹', '💝', '💖',
    '💗', '💓', '💕', '💞', '💘', '💟', '💬', '💭', '🗨', '💡',

    // 健康・ヘルスケア
    '💊', '💉', '🩹', '🩺', '🌡', '💪', '🧘', '🏃', '🚶', '🧖',
    '😴', '🛌', '😪', '🥱', '😌', '😇', '🧘‍♀️', '🧘‍♂️', '🏋️', '⚕️',

    // ペット
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
    '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🐣',

    // 自然・天気
    '🌞', '🌙', '⭐', '✨', '🌟', '💫', '☀️', '🌤', '⛅', '🌥',
    '☁️', '🌦', '🌧', '⛈', '🌩', '🌨', '❄️', '☃️', '⛄', '🌬',

    // 食材・飲み物
    '🥬', '🥦', '🥒', '🌶', '🫑', '🥕', '🧅', '🧄', '🥔', '🍠',
    '🥐', '🍞', '🥖', '🥨', '🥯', '🧀', '🥚', '🍳', '🥓', '🥩',
    '☕', '🍵', '🧃', '🥤', '🧋', '🍶', '🍾', '🍷', '🍸', '🍹',

    // スポーツ・レジャー
    '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
    '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪀', '🎯', '⛳', '🎣',

    // 音楽・芸術
    '🎵', '🎶', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸',
    '🎻', '🪕', '🎨', '🖌', '🖍', '🖊', '✏️', '📝', '🎭', '🎪',

    // テクノロジー
    '📱', '💻', '⌚', '📷', '📺', '🎮', '🖥', '⌨️', '🖱', '🖨',
    '📞', '📟', '📠', '📡', '🔋', '🔌', '💡', '🔦', '🕯', '🪔',

    // ツール・作業
    '🔧', '🔨', '🪛', '🔩', '⚙️', '🛠', '⛏', '🪓', '⚒', '🔪',
    '🗡', '⚔️', '🪃', '🏹', '🛡', '🪚', '🔗', '⛓', '🪝', '🧰',

    // その他日常
    '🎁', '🎀', '🎊', '🎉', '🎈', '🎏', '🎐', '🧧', '✉️', '📧',
    '📮', '📪', '📫', '📬', '📭', '📦', '📯', '📢', '📣', '📡',
  ];
}
