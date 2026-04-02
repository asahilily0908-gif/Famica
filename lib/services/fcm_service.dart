import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// FCM通知サービス
/// - トークン登録・管理
/// - 通知ハンドリング（フォアグラウンド/バックグラウンド）
/// - アクティビティ追跡
/// - 設定管理
class FCMService with WidgetsBindingObserver {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 🔧 静的フラグにしてシングルトン全体で共有
  static bool _initialized = false;
  static int _initCallCount = 0; // デバッグ用：初期化呼び出し回数
  String? _currentToken;
  bool _tokenSavedToFirestore = false;
  Timer? _activityDebounceTimer;

  // ========================================
  // 初期化
  // ========================================

  /// FCMサービスを初期化（冪等）
  Future<void> initialize() async {
    _initCallCount++;

    if (_initialized) {
      print('ℹ️ FCMService.initialize() 呼び出し #$_initCallCount: 既に初期化済み（スキップ）');
      if (kDebugMode) {
        print('   → リスナー重複登録を防止しました');
        print('   → スタックトレース省略（既に設定済み）');
      }
      return;
    }

    try {
      print('🔔 FCMService.initialize() 呼び出し #$_initCallCount: 初期化開始...');
      if (kDebugMode) {
        print('   → シングルトンインスタンス: ${identityHashCode(this)}');
      }

      // ローカル通知プラグインを初期化
      await _initializeLocalNotifications();

      // 通知権限をリクエスト
      await _requestPermissions();

      // トークンを取得・登録（リトライ付き）
      await _setupTokenWithRetry();

      // トークン更新リスナーを設定
      _setupTokenRefreshListener();

      // フォアグラウンドメッセージハンドラーを設定
      _setupForegroundHandler();

      // フォアグラウンド復帰時の再試行用にライフサイクルを監視
      WidgetsBinding.instance.addObserver(this);

      // バックグラウンド/終了時のメッセージハンドラー（main.dartで設定）

      _initialized = true;
      print('✅ FCMService: 初期化完了');
    } catch (e) {
      print('❌ FCMService初期化エラー: $e');
      rethrow;
    }
  }

  /// アプリのライフサイクル変更を監視
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_tokenSavedToFirestore) {
      print('🔄 フォアグラウンド復帰: FCMトークン未保存のため再試行');
      _setupTokenWithRetry();
    }
  }

  /// ローカル通知プラグインを初期化
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('✅ ローカル通知プラグイン初期化完了');
  }

  /// 通知権限をリクエスト
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 通知権限: ${settings.authorizationStatus}');
  }

  // ========================================
  // トークン管理
  // ========================================

  /// トークンを取得してFirestoreに登録（リトライ付き）
  Future<void> _setupTokenWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _setupToken();
        if (_tokenSavedToFirestore) {
          print('✅ FCMトークン保存確認済み（試行 $attempt/$maxRetries）');
          return;
        }
      } catch (e) {
        print('⚠️ トークンセットアップ試行 $attempt/$maxRetries 失敗: $e');
      }

      if (attempt < maxRetries) {
        final delay = Duration(seconds: 2 * attempt);
        print('⏳ ${delay.inSeconds}秒後にリトライ...');
        await Future.delayed(delay);
      }
    }

    if (!_tokenSavedToFirestore) {
      print('❌ FCMトークンの保存に失敗しました（$maxRetries回試行）');
    }
  }

  /// トークンを取得してFirestoreに登録
  Future<void> _setupToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ ユーザー未認証のためトークン登録スキップ');
      return;
    }

    // ========================================
    // iOS: 先にAPNSトークンを取得（重要）
    // ========================================
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        print('🍎 APNSトークン取得成功: ${apnsToken.substring(0, apnsToken.length.clamp(0, 20))}...');
      } else {
        print('⚠️ APNSトークンを取得できませんでした');
        print('   → 実機で実行していることを確認してください');
        print('   → Xcodeで Push Notifications capability が有効か確認してください');

        // APNSトークンがない場合、再試行（最大5回、2秒間隔）
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            print('🍎 APNSトークン取得成功（再試行 ${i + 1}回目）');
            break;
          }
          print('   APNSトークン再試行 ${i + 1}/5: まだ取得できません');
        }
      }

      // APNSトークンが取得できなかった場合、FCMトークンも無効になるため中断
      if (apnsToken == null) {
        print('❌ APNSトークン取得失敗: FCMトークンの取得をスキップします');
        return;
      }
    }

    // ========================================
    // FCMトークンを取得
    // ========================================
    final token = await _messaging.getToken();
    if (token == null) {
      print('⚠️ FCMトークンを取得できませんでした');
      return;
    }

    _currentToken = token;
    print('📱 FCMトークン取得成功:');
    print('   トークン長: ${token.length}文字');
    print('   先頭20文字: ${token.substring(0, token.length.clamp(0, 20))}...');
    if (kDebugMode) {
      print('🔑 完全なFCMトークン（コピーしてFirebase Consoleで使用）:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(token);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // Firestoreに保存
    await _saveTokenToFirestore(token);

    // デフォルト設定を初期化（既存の場合はスキップ）
    await _initializeDefaultSettings();
  }

  /// トークンをFirestoreに保存
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': {
          token: true,
        },
      }, SetOptions(merge: true));

      _tokenSavedToFirestore = true;
      print('✅ FCMトークン保存完了 (users/${user.uid})');

      // 保存を検証
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      final savedTokens = data?['fcmTokens'] as Map<String, dynamic>?;
      if (savedTokens != null && savedTokens.containsKey(token)) {
        print('✅ FCMトークン保存検証OK: Firestoreに正しく保存されています');
      } else {
        print('⚠️ FCMトークン保存検証NG: Firestoreに保存されていません');
        _tokenSavedToFirestore = false;
      }
    } catch (e) {
      print('❌ トークン保存エラー: $e');
      _tokenSavedToFirestore = false;
    }
  }

  /// トークン更新リスナーを設定
  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCMトークン更新: ${newToken.substring(0, newToken.length.clamp(0, 20))}...');
      _currentToken = newToken;
      _tokenSavedToFirestore = false;
      _saveTokenToFirestore(newToken);
    });
  }

  /// 古いトークンを削除
  Future<void> _removeTokenFromFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens.$token': FieldValue.delete(),
      });
      print('🗑️ 古いトークン削除: ${token.substring(0, token.length.clamp(0, 20))}...');
    } catch (e) {
      print('❌ トークン削除エラー: $e');
    }
  }

  // ========================================
  // 通知ハンドリング
  // ========================================

  /// フォアグラウンドメッセージハンドラーを設定
  void _setupForegroundHandler() {
    final listenerId = DateTime.now().millisecondsSinceEpoch;
    print('🎧 フォアグラウンドリスナー登録: ID=$listenerId');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 フォアグラウンド通知受信 (リスナーID: $listenerId)');
      print('   messageId: ${message.messageId}');
      _handleForegroundMessage(message);
    });
  }

  /// フォアグラウンドで通知を表示
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) {
      print('⚠️ 通知データがありません');
      return;
    }

    print('📬 タイトル: ${notification.title}');
    print('📬 本文: ${notification.body}');
    print('📬 データ: $data');

    // ローカル通知として表示
    const androidDetails = AndroidNotificationDetails(
      'famica_main_channel',
      'Famica通知',
      channelDescription: 'Famicaからのお知らせ',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: _encodePayload(data),
    );
  }

  /// 通知タップ時の処理
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final data = _decodePayload(payload);
    _handleNotificationNavigation(data);
  }

  /// 通知からのナビゲーション処理
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final householdId = data['householdId'] as String?;
    final docId = data['docId'] as String?;

    print('🔔 通知ナビゲーション: type=$type, docId=$docId');

    // TODO: GoRouterを使用したディープリンクナビゲーション
    // 実装例：
    // switch (type) {
    //   case 'task':
    //     // タスク詳細画面へ
    //     break;
    //   case 'cost':
    //     // コスト記録画面へ
    //     break;
    //   case 'letter':
    //     // レター画面へ
    //     break;
    //   case 'inactivity':
    //     // ホーム画面へ
    //     break;
    // }
  }

  /// ペイロードをエンコード
  String _encodePayload(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// ペイロードをデコード
  Map<String, dynamic> _decodePayload(String payload) {
    try {
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (e) {
      print('⚠️ ペイロードデコードエラー: $e');
      return {};
    }
  }

  // ========================================
  // アクティビティ追跡
  // ========================================

  /// ユーザーアクティビティを更新（デバウンス付き）
  void trackActivity() {
    // 既存のタイマーをキャンセル
    _activityDebounceTimer?.cancel();

    // 新しいタイマーを設定（10秒後に実行）
    _activityDebounceTimer = Timer(const Duration(seconds: 10), () {
      _updateLastActivityTimestamp();
    });
  }

  /// lastActivityAtをFirestoreに更新
  Future<void> _updateLastActivityTimestamp() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('📍 アクティビティ更新: ${DateTime.now()}');
      }
    } catch (e) {
      print('❌ アクティビティ更新エラー: $e');
    }
  }

  /// アクティビティを即座に更新（記録作成時など）
  Future<void> trackActivityNow() async {
    _activityDebounceTimer?.cancel();
    await _updateLastActivityTimestamp();
  }

  // ========================================
  // 設定管理
  // ========================================

  /// デフォルト設定を初期化
  Future<void> _initializeDefaultSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      // 既に設定がある場合はスキップ
      if (data != null && data.containsKey('notificationsEnabled')) {
        print('ℹ️ 通知設定は既に存在します');
        return;
      }

      // デフォルト設定を保存
      await _firestore.collection('users').doc(user.uid).set({
        'notificationsEnabled': true,
        'notifyPartnerActions': true,
        'notifyInactivity': true,
      }, SetOptions(merge: true));

      print('✅ デフォルト通知設定を初期化');
    } catch (e) {
      print('❌ 設定初期化エラー: $e');
    }
  }

  /// 通知設定を取得
  Future<Map<String, bool>> getNotificationSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'notificationsEnabled': true,
        'notifyPartnerActions': true,
        'notifyInactivity': true,
      };
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      return {
        'notificationsEnabled': data?['notificationsEnabled'] as bool? ?? true,
        'notifyPartnerActions': data?['notifyPartnerActions'] as bool? ?? true,
        'notifyInactivity': data?['notifyInactivity'] as bool? ?? true,
      };
    } catch (e) {
      print('❌ 設定取得エラー: $e');
      return {
        'notificationsEnabled': true,
        'notifyPartnerActions': true,
        'notifyInactivity': true,
      };
    }
  }

  /// 通知設定を更新
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? notifyPartnerActions,
    bool? notifyInactivity,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final updates = <String, dynamic>{};

      if (notificationsEnabled != null) {
        updates['notificationsEnabled'] = notificationsEnabled;
      }
      if (notifyPartnerActions != null) {
        updates['notifyPartnerActions'] = notifyPartnerActions;
      }
      if (notifyInactivity != null) {
        updates['notifyInactivity'] = notifyInactivity;
      }

      if (updates.isEmpty) return;

      await _firestore.collection('users').doc(user.uid).update(updates);
      print('✅ 通知設定更新: $updates');
    } catch (e) {
      print('❌ 設定更新エラー: $e');
      rethrow;
    }
  }

  /// 通知設定をStreamで監視
  Stream<Map<String, bool>> watchNotificationSettings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value({
        'notificationsEnabled': true,
        'notifyPartnerActions': true,
        'notifyInactivity': true,
      });
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      return {
        'notificationsEnabled': data?['notificationsEnabled'] as bool? ?? true,
        'notifyPartnerActions': data?['notifyPartnerActions'] as bool? ?? true,
        'notifyInactivity': data?['notifyInactivity'] as bool? ?? true,
      };
    });
  }

  // ========================================
  // クリーンアップ
  // ========================================

  /// サービスをクリーンアップ
  Future<void> dispose() async {
    _activityDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // 現在のトークンを削除（ログアウト時など）
    if (_currentToken != null) {
      await _removeTokenFromFirestore(_currentToken!);
    }

    _initialized = false;
    _tokenSavedToFirestore = false;
    print('🗑️ FCMService: クリーンアップ完了');
  }
}

// ========================================
// バックグラウンドメッセージハンドラー
// （トップレベル関数として定義 - main.dartから呼び出し）
// ========================================

/// バックグラウンド/終了時のメッセージハンドラー
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌙 バックグラウンド通知受信: ${message.messageId}');
  print('   タイトル: ${message.notification?.title}');
  print('   本文: ${message.notification?.body}');
  print('   データ: ${message.data}');

  // バックグラウンドでの追加処理が必要な場合はここに記述
}
