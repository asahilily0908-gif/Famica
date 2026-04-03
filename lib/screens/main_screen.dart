import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final _fcmService = FCMService();
  String? _lastSavedLocale;

  final List<Widget> _screens = [
    const QuickRecordScreen(),
    const CoupleScreen(),
    const LetterScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFCM();
    _syncLocaleIfNeeded();
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

  /// 端末のlocaleが変更されていればFirestoreを更新
  Future<void> _syncLocaleIfNeeded() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (_lastSavedLocale == currentLocale) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'locale': currentLocale,
      }, SetOptions(merge: true));
      _lastSavedLocale = currentLocale;
    } catch (e) {
      print('⚠️ locale同期エラー: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncLocaleIfNeeded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
