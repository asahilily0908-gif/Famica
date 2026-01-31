import 'package:flutter/material.dart';
import '../constants/famica_colors.dart';

/// Famica共通ヘッダーウィジェット
/// シンプルなタイトル表示（Freeプランのみ対応）
class FamicaHeader extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  
  const FamicaHeader({
    super.key,
    this.fontSize = 32,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Famica',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: FamicaColors.accent,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            '10秒で記録',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
