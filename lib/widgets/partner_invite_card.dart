/// パートナー招待案内カード
/// パートナー未招待時に表示する案内UI

import 'package:flutter/material.dart';
import '../constants/famica_colors.dart';
import '../screens/family_invite_screen.dart';

class PartnerInviteCard extends StatelessWidget {
  const PartnerInviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // アイコン
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: FamicaColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text(
                '👥',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // タイトル
          Text(
            'パートナーを招待して、\nふたりの記録を見える化しよう',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // 説明
          Text(
            '招待リンクを送るだけで、共有が始まります',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // 招待ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyInviteScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FamicaColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '招待リンクを共有',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
