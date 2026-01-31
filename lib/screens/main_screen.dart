import 'package:flutter/material.dart';
import '../constants/famica_colors.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/fcm_service.dart';
import 'quick_record_screen.dart';
import 'couple_screen.dart';
import 'letter_screen.dart';
import 'settings_screen.dart';

/// Famica メイン画面（ボトムナビゲーション付き・広告付き無料版）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _fcmService = FCMService();

  final List<Widget> _screens = [
    const QuickRecordScreen(),
    const CoupleScreen(),
    const LetterScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  /// FCMサービスを初期化
  Future<void> _initializeFCM() async {
    try {
      await _fcmService.initialize();
      // アプリ起動時のアクティビティを記録
      _fcmService.trackActivityNow();
      print('✅ MainScreen: FCM初期化完了');
    } catch (e) {
      print('❌ MainScreen: FCM初期化エラー: $e');
    }
  }

  @override
  void dispose() {
    _fcmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: FamicaColors.accent,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline, size: 28),
                  activeIcon: Icon(Icons.add_circle, size: 28),
                  label: '記録',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.trending_up_outlined, size: 28),
                  activeIcon: Icon(Icons.trending_up, size: 28),
                  label: 'ふたり',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mail_outline, size: 28),
                  activeIcon: Icon(Icons.mail, size: 28),
                  label: '手紙',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 28),
                  activeIcon: Icon(Icons.settings, size: 28),
                  label: '設定',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
