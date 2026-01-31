/// 日替わりヒントカード
/// 1日1つのヒントを淡い紫色のカードで表示

import 'package:flutter/material.dart';
import '../utils/daily_tip_picker.dart';

class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tip = getTodayTip();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // やさしい淡い紫色の背景
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリ名
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE9D5FF).withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tip.category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B46C1),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ヒント本文
            Text(
              tip.body,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                height: 1.7,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
