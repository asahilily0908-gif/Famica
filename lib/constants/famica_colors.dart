import 'package:flutter/material.dart';

/// Famica 2025 モダンUIカラーパレット
/// 柔らかい・丸い・優しい・ミニマルで洗練されたデザインシステム
class FamicaColors {
  // === 2025年メインカラー ===
  static const Color primary = Color(0xFFFF75B2); // primaryPink
  static const Color primaryLight = Color(0xFFFFEFF5); // lightPink
  static const Color primaryDark = Color(0xFFFF5A9D); // ダークピンク
  
  // === セカンダリカラー（アクセント） ===
  static const Color secondary = Color(0xFF5A8BFF); // accentBlue
  static const Color secondaryLight = Color(0xFFE3ECFF); // ライトブルー
  static const Color tertiary = Color(0xFFFFC371); // ウォームゴールド
  
  // === バックグラウンド ===
  static const Color background = Color(0xFFFAFBFC); // オフホワイト
  static const Color surface = Color(0xFFFFFFFF); // ピュアホワイト
  static const Color surfaceVariant = Color(0xFFF5F7FA); // グレイッシュホワイト
  
  // === テキストカラー ===
  static const Color textPrimary = Color(0xFF222222); // textDark
  static const Color textSecondary = Color(0xFF777777); // textSub
  static const Color textTertiary = Color(0xFF9CA3AF); // ライトグレー
  static const Color textInverse = Color(0xFFFFFFFF); // ホワイト
  
  // === ラインカラー ===
  static const Color lineColor = Color(0xFFEDEDED); // 区切り線
  
  // === 互換性のための旧名称（既存コードとの互換性保持） ===
  static const Color text = textPrimary; // 旧: text
  static const Color textDark = textPrimary; // 旧: textDark
  static const Color textLight = textSecondary; // 旧: textLight
  static const Color accent = primary; // 旧: accent
  static const Color lavender = Color(0xFF9B59B6); // 旧: lavender
  
  // === カテゴリーカラー（洗練されたパステル） ===
  static const Color categoryKaji = Color(0xFF34D399); // エメラルドグリーン
  static const Color categoryKaigo = Color(0xFF60A5FA); // スカイブルー
  static const Color categoryIkuji = Color(0xFFFBBF24); // サンシャインイエロー
  static const Color categoryOther = Color(0xFFA78BFA); // ラベンダー
  
  // === ステータスカラー ===
  static const Color success = Color(0xFF10B981); // グリーン
  static const Color error = Color(0xFFEF4444); // レッド
  static const Color warning = Color(0xFFF59E0B); // オレンジ
  static const Color info = Color(0xFF3B82F6); // ブルー
  
  // === スペシャルカラー ===
  static const Color thanks = Color(0xFFFCD34D); // ゴールド
  static const Color plus = Color(0xFFFFD700); // プレミアムゴールド
  static const Color ai = Color(0xFF8B5CF6); // AIパープル
  
  // === シャドウ&オーバーレイ ===
  static const Color shadow = Color(0x0F000000); // ソフトシャドウ
  static const Color shadowMedium = Color(0x1A000000); // ミディアムシャドウ
  static const Color shadowHeavy = Color(0x29000000); // ヘビーシャドウ
  static const Color overlay = Color(0x80000000); // オーバーレイ
  
  // === UI専用カラー ===
  static const Color cardBackground = surface; // カード背景
  
  // === グラデーション（モダン＆エレガント） ===
  
  /// メインのアクセントグラデーション
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 互換性のための旧名称
  static const LinearGradient accentGradient = primaryGradient;
  
  /// 背景グラデーション（ソフト）
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFBFC), Color(0xFFF5F7FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  /// AI機能用グラデーション
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Plus機能用グラデーション
  static const LinearGradient plusGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// クールなグラデーション
  static const LinearGradient coolGradient = LinearGradient(
    colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// ウォームなグラデーション
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// サクセスグラデーション
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // === カテゴリー別の色を取得 ===
  static Color getCategoryColor(String category) {
    switch (category) {
      case '家事':
        return categoryKaji;
      case '介護':
        return categoryKaigo;
      case '育児':
        return categoryIkuji;
      case 'その他':
      default:
        return categoryOther;
    }
  }
  
  // === カテゴリー別のグラデーションを取得 ===
  static LinearGradient getCategoryGradient(String category) {
    switch (category) {
      case '家事':
        return const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case '介護':
        return const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case '育児':
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'その他':
      default:
        return const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
  
  // === カテゴリー別のアイコンを取得 ===
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case '家事':
        return Icons.home_outlined;
      case '介護':
        return Icons.favorite_outline;
      case '育児':
        return Icons.child_care_outlined;
      case 'その他':
      default:
        return Icons.more_horiz_outlined;
    }
  }
}

/// Famica 2025 モダンテーマ
class FamicaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: FamicaColors.primary,
        secondary: FamicaColors.secondary,
        tertiary: FamicaColors.tertiary,
        surface: FamicaColors.surface,
        background: FamicaColors.background,
        error: FamicaColors.error,
        onPrimary: FamicaColors.textInverse,
        onSecondary: FamicaColors.textInverse,
        onSurface: FamicaColors.textPrimary,
        onBackground: FamicaColors.textPrimary,
        surfaceVariant: FamicaColors.surfaceVariant,
        outline: FamicaColors.lineColor,
      ),
      scaffoldBackgroundColor: FamicaColors.background,
      
      // AppBar: 透明背景、影なし、iOS風
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: FamicaColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: FamicaColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      
      // Card: 柔らかい角丸、薄い影
      cardTheme: CardThemeData(
        color: FamicaColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // ElevatedButton: フラット、角丸16
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FamicaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
      
      // OutlinedButton: 薄ピンク枠、角丸14
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FamicaColors.primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: FamicaColors.primary, width: 1.5),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // TextButton: シンプル
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FamicaColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // FAB: 角丸20、影あり
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FamicaColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // InputDecoration: 角丸、薄ピンク枠
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FamicaColors.primaryLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FamicaColors.primaryLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FamicaColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FamicaColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: FamicaColors.textSecondary.withOpacity(0.5)),
      ),
      
      // Divider: 薄いグレー
      dividerTheme: const DividerThemeData(
        color: FamicaColors.lineColor,
        thickness: 1,
        space: 1,
      ),
      
      // テキストテーマ: SF Pro風
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: FamicaColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: FamicaColors.textPrimary,
          letterSpacing: -0.4,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: FamicaColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: FamicaColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: FamicaColors.textPrimary,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: FamicaColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: FamicaColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: FamicaColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: FamicaColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: FamicaColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: FamicaColors.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: FamicaColors.textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: FamicaColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: FamicaColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: FamicaColors.textSecondary,
        ),
      ),
    );
  }
}
