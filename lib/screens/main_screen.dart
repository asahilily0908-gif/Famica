import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/glass_components.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/fcm_service.dart';
import 'quick_record_screen.dart';
import 'couple_screen.dart';
import 'letter_screen.dart';
import 'settings_screen.dart';

/// Famica メイン画面（フローティングガラスナビゲーション）
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
    final l = AppLocalizations.of(context)!;
    return GlassScaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          GlassNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              GlassNavItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: l.navRecord,
              ),
              GlassNavItem(
                icon: Icons.trending_up_outlined,
                activeIcon: Icons.trending_up,
                label: l.navCouple,
              ),
              GlassNavItem(
                icon: Icons.mail_outline,
                activeIcon: Icons.mail,
                label: l.navLetter,
              ),
              GlassNavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: l.navSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
