import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../constants/famica_colors.dart';

/// Notification Debug Screen (DEBUG ONLY)
/// 
/// プッシュ通知の診断画面。
/// - 権限ステータス確認
/// - APNsトークン確認（iOS）
/// - FCMトークン表示・コピー
/// - 手動権限リクエスト
class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String _buildMode = 'unknown';
  String _authStatus = 'checking...';
  String? _apnsToken;
  String? _fcmToken;
  DateTime? _lastRefresh;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _determineBuildMode();
    _checkStatus();
  }

  void _determineBuildMode() {
    if (kDebugMode) {
      _buildMode = 'debug';
    } else if (kProfileMode) {
      _buildMode = 'profile';
    } else {
      _buildMode = 'release';
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);

    try {
      final messaging = FirebaseMessaging.instance;

      // Permission status
      final settings = await messaging.getNotificationSettings();
      final authStatus = _formatAuthStatus(settings.authorizationStatus);

      print('[NOTIF_DEBUG] Permission status: $authStatus');

      // APNs token (iOS only)
      String? apns;
      if (Platform.isIOS) {
        apns = await messaging.getAPNSToken();
        if (apns != null) {
          print('[NOTIF_DEBUG] APNs token: ${apns.substring(0, apns.length > 20 ? 20 : apns.length)}...');
        } else {
          print('[NOTIF_DEBUG] APNs token: (none)');
        }
      }

      // FCM token
      final fcm = await messaging.getToken();
      if (fcm != null) {
        print('[NOTIF_DEBUG] FCM token length: ${fcm.length}, first 20 chars: ${fcm.substring(0, fcm.length > 20 ? 20 : fcm.length)}...');
      } else {
        print('[NOTIF_DEBUG] FCM token: (none)');
      }

      if (mounted) {
        setState(() {
          _authStatus = authStatus;
          _apnsToken = apns;
          _fcmToken = fcm;
          _lastRefresh = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[NOTIF_DEBUG] Error checking status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータス取得エラー: $e'),
            backgroundColor: FamicaColors.error,
          ),
        );
      }
    }
  }

  String _formatAuthStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return 'authorized';
      case AuthorizationStatus.denied:
        return 'denied';
      case AuthorizationStatus.notDetermined:
        return 'notDetermined';
      case AuthorizationStatus.provisional:
        return 'provisional';
      default:
        return status.toString();
    }
  }

  Future<void> _requestPermission() async {
    print('[NOTIF_DEBUG] Requesting notification permission...');

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = _formatAuthStatus(settings.authorizationStatus);
      print('[NOTIF_DEBUG] Permission request result: $status');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('権限リクエスト完了: $status'),
            backgroundColor: settings.authorizationStatus == AuthorizationStatus.authorized
                ? FamicaColors.success
                : Colors.orange,
          ),
        );

        // Refresh status after permission request
        await _checkStatus();
      }
    } catch (e) {
      print('[NOTIF_DEBUG] Permission request error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('権限リクエストエラー: $e'),
            backgroundColor: FamicaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _retryApnsToken() async {
    if (!Platform.isIOS) return;

    print('[NOTIF_DEBUG] Retrying APNs token (3 attempts with 500ms delay)...');

    setState(() => _isLoading = true);

    try {
      final messaging = FirebaseMessaging.instance;
      String? token;

      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        token = await messaging.getAPNSToken();

        print('[NOTIF_DEBUG] APNs retry attempt ${i + 1}/3: ${token != null ? "success" : "null"}');

        if (token != null) {
          if (mounted) {
            setState(() {
              _apnsToken = token;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('APNsトークン取得成功（${i + 1}回目）'),
                backgroundColor: FamicaColors.success,
              ),
            );
          }
          return;
        }
      }

      // Still null after 3 attempts
      print('[NOTIF_DEBUG] APNs token still null after 3 retries');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('APNsトークンを取得できませんでした。\nアプリ再起動またはネットワーク確認が必要です。'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('[NOTIF_DEBUG] APNs retry error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('APNsトークン取得エラー: $e'),
            backgroundColor: FamicaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _copyFcmToken() async {
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCMトークンがありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: _fcmToken!));
    print('[NOTIF_DEBUG] FCM token copied to clipboard');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ FCMトークンをクリップボードにコピーしました'),
          backgroundColor: FamicaColors.success,
        ),
      );
    }
  }

  Future<void> _printFullTokenToConsole() async {
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCMトークンがありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('[NOTIF_DEBUG] ========================================');
    print('[NOTIF_DEBUG] FULL FCM TOKEN (for Firebase Console):');
    print('[NOTIF_DEBUG] $_fcmToken');
    print('[NOTIF_DEBUG] ========================================');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ FCMトークンをコンソールに出力しました'),
          backgroundColor: FamicaColors.success,
        ),
      );
    }
  }

  Future<void> _openAppSettings() async {
    if (!Platform.isIOS) return;

    try {
      const url = 'app-settings:';
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        print('[NOTIF_DEBUG] Opened iOS app settings');
      } else {
        throw Exception('Cannot open app settings');
      }
    } catch (e) {
      print('[NOTIF_DEBUG] Failed to open app settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定を開けませんでした: $e'),
            backgroundColor: FamicaColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildApnsCard(),
                const SizedBox(height: 16),
                _buildFcmCard(),
                const SizedBox(height: 16),
                _buildActionsCard(),
                const SizedBox(height: 24),
                if (_lastRefresh != null)
                  Center(
                    child: Text(
                      '最終更新: ${_formatTimestamp(_lastRefresh!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Platform', Platform.isIOS ? 'iOS' : 'Android'),
            _buildInfoRow('Build Mode', _buildMode),
            _buildInfoRow(
              'Permission Status',
              _authStatus,
              statusColor: _getStatusColor(_authStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApnsCard() {
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.apple, size: 20),
                SizedBox(width: 8),
                Text(
                  'APNs Token (iOS)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _apnsToken != null ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _apnsToken != null ? Icons.check_circle : Icons.error,
                    color: _apnsToken != null ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _apnsToken != null ? '✅ Available' : '❌ Not Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _apnsToken != null ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_apnsToken == null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _retryApnsToken,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry APNs Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFcmCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'FCM Token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fcmToken != null ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _fcmToken != null ? Icons.check_circle : Icons.error,
                    color: _fcmToken != null ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fcmToken != null ? '✅ Available' : '❌ Not Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _fcmToken != null ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_fcmToken != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _fcmToken!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyFcmToken,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FamicaColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printFullTokenToConsole,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FamicaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Request Notification Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FamicaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FamicaColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open iOS Notification Settings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: statusColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'authorized') return Colors.green;
    if (status == 'denied') return Colors.red;
    if (status == 'notDetermined') return Colors.orange;
    return Colors.grey;
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
