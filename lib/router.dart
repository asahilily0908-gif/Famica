import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:famica/auth_screen.dart';
import 'package:famica/screens/main_screen.dart';
import 'package:famica/screens/invite_screen.dart';

/// FirebaseAuth状態変化をgo_routerに通知するためのヘルパークラス
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// アプリ全体のルーティング設定
/// ディープリンク（招待URL）とアプリ内ナビゲーションを管理
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (BuildContext context, GoRouterState state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthScreen = state.matchedLocation == '/auth';
      final isInviteScreen = state.matchedLocation.startsWith('/invite');

      // 未ログインでかつ認証画面・招待画面以外にアクセスしようとした場合
      if (user == null && !isAuthScreen && !isInviteScreen) {
        return '/auth';
      }

      // ログイン済みで認証画面にアクセスしようとした場合
      if (user != null && isAuthScreen) {
        return '/';
      }

      return null; // リダイレクト不要
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) {
          final householdId = state.uri.queryParameters['hid'];
          
          if (householdId == null || householdId.isEmpty) {
            // householdIdが無効な場合はホームへリダイレクト
            return const Scaffold(
              body: Center(
                child: Text('無効な招待URLです'),
              ),
            );
          }
          
          return InviteScreen(householdId: householdId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('エラー')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'ページが見つかりません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('ホームへ戻る'),
            ),
          ],
        ),
      ),
    ),
  );
}
