import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Famica App Theme - OS標準フォント準拠
/// iOS: San Francisco / Android: Roboto が自然に適用される
class AppTheme {
  // ========================================
  // カラーパレット
  // ========================================
  
  static const Color primaryPink = Color(0xFFFF75B2);
  static const Color lightPink = Color(0xFFFFEFF5);
  static const Color accentBlue = Color(0xFF5A8BFF);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF222222);
  static const Color textSub = Color(0xFF777777);
  static const Color lineColor = Color(0xFFEFEFEF);
  
  // 追加色
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  
  // ========================================
  // シャドウ定義
  // ========================================
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];
  
  // ========================================
  // ThemeData - OS標準フォント使用
  // ========================================
  
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      
      // カラースキーム
      colorScheme: ColorScheme.light(
        primary: primaryPink,
        secondary: accentBlue,
        surface: white,
        error: error,
        onPrimary: white,
        onSecondary: white,
        onSurface: textDark,
        outline: lineColor,
      ),
      
      // Scaffold背景色
      scaffoldBackgroundColor: white,
      
      // Canvas色
      canvasColor: white,
      
      // BottomSheet背景色
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        modalBackgroundColor: white,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        iconTheme: IconThemeData(
          color: textDark,
          size: 24,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // ボタンテーマ
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPink,
          backgroundColor: white,
          side: const BorderSide(color: primaryPink, width: 1),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSub,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textSub.withOpacity(0.5)),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: lineColor,
        thickness: 1,
        space: 1,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryPink,
        unselectedItemColor: textSub,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: textSub,
        textColor: textDark,
        tileColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // テキストテーマ - OS標準フォント（fontFamily指定なし）
      textTheme: const TextTheme(
        // 画面タイトル / 大見出し
        displayLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // セクションタイトル
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.5,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // カードタイトル
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // 本文（メイン）
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // 本文（標準）
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // 補足文
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0,
          color: textSub,
        ),
        
        // ボタンテキスト
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
          letterSpacing: 0.2,
          color: textDark,
        ),
        
        // ラベル（中）
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // ラベル（小）
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.3,
          letterSpacing: 0,
          color: textSub,
        ),
        
        // 数値強調
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          letterSpacing: 0,
          color: textDark,
        ),
        
        // 小見出し
        headlineMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
          letterSpacing: 0,
          color: textDark,
        ),
      ),
    );
  }
}

/// App Text Styles - 互換性用（既存コードとの互換性維持）
/// OS標準フォント使用（iOS: San Francisco / Android: Roboto）
class AppTextStyles {
  // 画面タイトル / 大見出し
  static const TextStyle displayLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // セクションタイトル
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // カードタイトル
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // 本文（メイン）
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // 本文（標準）
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // 補足文
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textSub,
  );
  
  // ボタンテキスト
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppTheme.textDark,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.textSub,
  );
  
  // 数値強調
  static const TextStyle displayMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // Headline系
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textDark,
  );
  
  // 補足・注釈（互換性）
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textSub,
  );
  
  static const TextStyle captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppTheme.textSub,
  );
}

/// レイアウト定数
class AppLayout {
  // 横方向のパディング
  static const double horizontalPadding = 16.0;
  
  // コンポーネント間の間隔
  static const double componentSpacing = 12.0;
  static const double componentSpacingMedium = 16.0;
  
  // セクション間の間隔
  static const double sectionSpacing = 24.0;
  
  // カードの角丸
  static const double cardBorderRadius = 22.0;
  
  // ボタンの角丸
  static const double buttonBorderRadiusPrimary = 16.0;
  static const double buttonBorderRadiusSecondary = 14.0;
  
  // インプットの角丸
  static const double inputBorderRadius = 12.0;
  
  // ボトムシートの角丸
  static const double bottomSheetBorderRadius = 28.0;
  
  // 最小タップターゲット
  static const double minTapTarget = 44.0;
}
