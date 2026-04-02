import 'package:flutter/material.dart';
import '../constants/famica_colors.dart';

/// Famica共通ヘッダーウィジェット
/// グラデーションテキスト + サブタイトル対応
class FamicaHeader extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  final String? subtitle;

  const FamicaHeader({
    super.key,
    this.fontSize = 32,
    this.showSubtitle = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Famica',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: FamicaColors.accent,
              letterSpacing: -0.5,
            ),
          ),
          if (showSubtitle || subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle ?? '10秒で記録',
              style: TextStyle(
                fontSize: 14,
                color: FamicaColors.textSecondary.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
