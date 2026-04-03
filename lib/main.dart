import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/firestore_service.dart';
import 'services/fcm_service.dart';
import 'services/att_service.dart';
import 'models/user_model.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

// ========================================
// FCM バックグラウンドハンドラー（トップレベル関数）
// ========================================

/// バックグラウンド/終了時のメッセージハンドラー
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🌙 バックグラウンド通知受信: ${message.messageId}');
  print('   タイトル: ${message.notification?.title}');
  print('   本文: ${message.notification?.body}');
  print('   データ: ${message.data}');
}

// ========================================
// Riverpod Providers
// ========================================

/// 現在のFirebase認証ユーザーを監視するStreamProvider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 現在のユーザー情報（Firestore）を監視するStreamProvider
/// users/{uid}ドキュメントの変更をリアルタイムで反映
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      
      // users/{uid}ドキュメントを監視
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return UserModel.fromFirestore(snapshot);
          });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase初期化成功');
    
    // FCMバックグラウンドメッセージハンドラーを登録
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ FCMバックグラウンドハンドラー登録完了');
    
    // AdMobの初期化
    final initResult = await MobileAds.instance.initialize();
    print('✅ AdMob初期化成功');
    print('   初期化ステータス: ${initResult.adapterStatuses}');
    
    // 初期化完了を明示的に確認
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // 必要に応じて実機IDを追加
      ),
    );
    print('   リクエスト設定: 完了');
    
    // ATT（App Tracking Transparency）リクエスト
    // iOS 14.5以降、広告表示前に必須
    final attService = ATTService();
    final attStatus = await attService.requestPermission();
    print('✅ ATT初期化完了: $attStatus');
    
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    print('❌ Firebase初期化エラー: $e');
    print('スタックトレース: $stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Firebase初期化エラー', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Famica',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// ログイン状態を監視して、ログインしてなければログイン画面を出す
/// Firestore users/{uid}の監視により、householdIdが設定されるまで待機
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  final _firestoreService = FirestoreService();
  bool _isInitialized = false;

  Future<void> _saveLocale(User user) async {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'locale': locale,
      }, SetOptions(merge: true));
    } catch (e) {
      print('⚠️ locale保存エラー: $e');
    }
  }

  Future<void> _ensureSetup(User user) async {
    if (_isInitialized) return;
    
    try {
      print('🚀 初期セットアップ実行');
      await _firestoreService.ensureUserSetup(
        lifeStage: 'couple', // デフォルト: 同棲カップル
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ セットアップエラー: $e');
      // エラーでも画面は表示する
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // authStateProviderを監視
    final authState = ref.watch(authStateProvider);
    
    final l = AppLocalizations.of(context)!;

    return authState.when(
      data: (user) {
        if (user == null) {
          // 未ログイン
          _isInitialized = false;
          return const AuthScreen();
        }
        
        // ログイン済み - currentUserProviderを監視
        final currentUserAsync = ref.watch(currentUserProvider);
        
        return currentUserAsync.when(
          data: (userData) {
            if (userData == null) {
              // usersドキュメントが存在しない場合は初期セットアップを実行
              if (!_isInitialized) {
                _ensureSetup(user);
                _saveLocale(user);
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryPink),
                        const SizedBox(height: 16),
                        Text(l.mainInitSetup),
                        const SizedBox(height: 8),
                        Text(
                          l.mainCreatingUser,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // セットアップ完了後もユーザーデータが取得できない場合は待機
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryPink),
                      const SizedBox(height: 16),
                      Text(l.mainLoadingUser),
                    ],
                  ),
                ),
              );
            }
            
            // householdIdが設定されているか確認
            if (userData.householdId == null || userData.householdId!.isEmpty) {
              // householdIdが未設定の場合は待機
              print('⚠️ householdIdが未設定: ${userData.uid}');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primaryPink),
                      const SizedBox(height: 16),
                      Text(l.mainPreparingHousehold),
                      const SizedBox(height: 8),
                      Text(
                        l.mainWaitingHousehold,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // ユーザー情報とhouseholdIdが揃っているので、メイン画面へ
            print('✅ ユーザー情報確認完了: ${userData.displayName} (household: ${userData.householdId})');
            _isInitialized = true;
            return const MainScreen();
          },
          // loading状態ではBuildContextからAppLocalizationsを取得できるが、
          // constウィジェットとして構築するためローカライズ不可。
          // ここは初回読み込み時の一瞬だけ表示されるため影響は軽微。
          loading: () => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryPink),
                  const SizedBox(height: 16),
                  Text(l.loading),
                ],
              ),
            ),
          ),
          error: (error, stack) {
            print('❌ ユーザー情報取得エラー: $error');
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(l.mainErrorOccurred),
                      const SizedBox(height: 8),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Text(l.logout),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('${l.mainAuthError}: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
