/// Famica UIデザイン統一基準
/// ステップ2で定義された統一ルール

import 'package:flutter/material.dart';

/// 【背景色】
class FamicaBackground {
  static const Color screen = Colors.white;
  static const Color dialog = Colors.white;
  static const Color card = Colors.white;
}

/// 【余白統一】
class FamicaSpacing {
  // 画面左右
  static const double screenHorizontal = 16.0;
  
  // カード周り
  static const double cardMargin = 12.0;
  
  // セクション間
  static const double sectionGap = 20.0;
  
  // カード内パディング
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  
  // ListTile標準
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    vertical: 8.0,
    horizontal: 16.0,
  );
}

/// 【フォントサイズ統一】
class FamicaFontSize {
  // 説明文・サブ情報
  static const double caption = 12.0;
  
  // 通常テキスト
  static const double body = 14.0;
  
  // 重要テキスト・中見出し
  static const double subtitle = 16.0;
  
  // 大見出し
  static const double title = 20.0;
}

/// 【Card統一スタイル】
class FamicaCardStyle {
  static const double borderRadius = 12.0;
  static const double elevation = 1.0;
  
  static BoxDecoration decoration = BoxDecoration(
    color: FamicaBackground.card,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// 【AppBar統一スタイル】
class FamicaAppBar {
  static AppBar build({
    required String title,
    List<Widget>? actions,
    Widget? leading,
  }) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: FamicaFontSize.title,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: actions,
      leading: leading,
    );
  }
}
