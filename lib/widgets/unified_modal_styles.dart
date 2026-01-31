import 'package:flutter/material.dart';

/// 記録一覧と統一されたモーダルデザインスタイル

class UnifiedModalStyles {
  // ===================================
  // カラー定義
  // ===================================
  
  /// モーダル背景色（白に統一）
  static const Color modalBackground = Color(0xFFFFFFFF);
  
  /// ピンク枠線
  static const Color pinkBorder = Color(0xFFFFB7D5);
  
  /// メインピンク
  static const Color primaryPink = Color(0xFFFF75B2);
  
  /// テキスト暗
  static const Color textDark = Color(0xFF333333);
  
  /// テキスト中
  static const Color textMedium = Color(0xFF555555);
  
  /// テキスト薄
  static const Color textLight = Color(0xFF888888);
  
  // ===================================
  // カード/コンテナスタイル
  // ===================================
  
  /// 標準カードの装飾
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  /// 項目カードの装飾（記録一覧と同じ）
  static BoxDecoration get itemCardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFFFFE0E8),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // ===================================
  // TextFieldスタイル
  // ===================================
  
  /// 統一されたTextFieldの装飾
  static InputDecoration textFieldDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: pinkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: pinkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  
  // ===================================
  // ボタンスタイル
  // ===================================
  
  /// 選択ボタンの装飾（ON状態）
  static BoxDecoration selectedButtonDecoration = BoxDecoration(
    color: primaryPink,
    borderRadius: BorderRadius.circular(16),
  );
  
  /// 選択ボタンの装飾（OFF状態）
  static BoxDecoration unselectedButtonDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: pinkBorder, width: 1.5),
  );
  
  /// 選択ボタンのテキストスタイル（ON）
  static const TextStyle selectedButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  /// 選択ボタンのテキストスタイル（OFF）
  static const TextStyle unselectedButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryPink,
  );
  
  // ===================================
  // テキストスタイル
  // ===================================
  
  /// モーダルタイトル
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textDark,
  );
  
  /// ラベル
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textMedium,
  );
  
  /// 本文
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMedium,
  );
  
  /// キャプション
  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textLight,
  );
}

/// 統一モーダルコンテナ
class UnifiedModalContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const UnifiedModalContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Container(
            width: screenWidth * 0.95,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.9,
            ),
            decoration: BoxDecoration(
              color: UnifiedModalStyles.modalBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 統一された保存ボタン
class UnifiedSaveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const UnifiedSaveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: UnifiedModalStyles.primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// 統一されたキャンセルボタン
class UnifiedCancelButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const UnifiedCancelButton({
    super.key,
    this.text = 'キャンセル',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed ?? () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 統一された選択ボタン（あなた/パートナー用）
class UnifiedSelectionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const UnifiedSelectionButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: isSelected
              ? UnifiedModalStyles.selectedButtonDecoration
              : UnifiedModalStyles.unselectedButtonDecoration,
          child: Center(
            child: Text(
              text,
              style: isSelected
                  ? UnifiedModalStyles.selectedButtonTextStyle
                  : UnifiedModalStyles.unselectedButtonTextStyle,
            ),
          ),
        ),
      ),
    );
  }
}
