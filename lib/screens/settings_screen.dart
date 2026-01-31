import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode用
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../constants/famica_colors.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';
import '../widgets/famica_header.dart';
import 'family_invite_screen.dart';
import 'notification_debug_screen.dart';

/// Famica 設定画面（広告付き無料版）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nicknameController = TextEditingController();

  // 法務ページのURL
  static const String _privacyPolicyUrl = 'https://careful-ear-c48.notion.site/Famica-2ae091d63f5a8040b56eef4f659ab262';
  static const String _termsOfServiceUrl = 'https://careful-ear-c48.notion.site/Famica-2ae091d63f5a8068ba07c22cccc65738';
  static const String _helpUrl = 'https://careful-ear-c48.notion.site/Famica-2ae091d63f5a8080bc24ce20458e5bca';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadNickname() async {
    final nickname = await _firestoreService.getMyNickname();
    if (nickname != null && mounted) {
      setState(() {
        _nicknameController.text = nickname;
      });
    }
  }

  /// URLを外部ブラウザで開く
  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('URLを開けませんでした');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URLを開けませんでした: $e'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildPremiumFeatures(),
              _buildSettingsList(),
              const SizedBox(height: 16),
              _buildDebugSection(),
              _buildDeleteAccountButton(),
              const SizedBox(height: 80), // ボトムナビ用スペース
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FamicaHeader(
            fontSize: 32,
            showSubtitle: false,
          ),
          const SizedBox(height: 4),
          Text(
            'ふたりのがんばりを10秒で記録',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.group_add,
            title: 'パートナーを招待',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FamilyInviteScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(
            icon: Icons.person,
            title: 'ニックネーム変更',
            onTap: () => _showNicknameEditBottomSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'プライバシーポリシー',
            onTap: () => _launchUrl(_privacyPolicyUrl),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'ヘルプ・お問い合わせ',
            onTap: () => _launchUrl(_helpUrl),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: '利用規約',
            onTap: () => _launchUrl(_termsOfServiceUrl),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'ログアウト',
            onTap: _showLogoutDialog,
            textColor: FamicaColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    // Debug mode only
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildSettingsItem(
        icon: Icons.bug_report,
        title: 'Notification Debug (Debug)',
        subtitle: '開発者向け通知診断',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationDebugScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showDeleteAccountDialog,
          icon: const Icon(Icons.delete_forever),
          label: const Text('アカウント削除'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50],
            foregroundColor: FamicaColors.error,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: FamicaColors.error.withOpacity(0.5), width: 1),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: FractionallySizedBox(
            widthFactor: 0.95,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'アカウントを削除しますか？',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '削除すると、以下の情報が完全に削除されます',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• すべての記録データ',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '• パートナー共有情報',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Color(0xFFD32F2F),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'この操作は元に戻せません',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('キャンセル'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FamicaColors.error,
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('削除する'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        _deleteAccount();
      }
    });
  }

  /// アカウント削除処理
  Future<void> _deleteAccount() async {
    if (!mounted) return;

    debugPrint('[DeleteAccount] start');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('アカウントを削除しています...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      debugPrint('[DeleteAccount] reloading user token...');
      await user.reload();

      final uid = user.uid;

      debugPrint('[DeleteAccount] deleting Firestore data...');
      final result = await FirebaseFunctions.instance
          .httpsCallable('deleteUserData')
          .call({'uid': uid});

      if (result.data == null || result.data['success'] != true) {
        throw Exception('Firestoreデータの削除に失敗しました');
      }

      debugPrint('[DeleteAccount] Firestore data deleted');

      debugPrint('[DeleteAccount] deleting auth account...');
      await user.delete();

      debugPrint('[DeleteAccount] delete success');

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        debugPrint('[DeleteAccount] navigate to /auth');
        context.go('/auth');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[DeleteAccount] FirebaseAuthException: ${e.code}');

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (e.code == 'requires-recent-login') {
        debugPrint('[DeleteAccount] need reauth');
        if (mounted) {
          await _handleReauthentication();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除に失敗しました: ${e.message}'),
              backgroundColor: FamicaColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[DeleteAccount] error: $e');

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: ${e.toString()}'),
            backgroundColor: FamicaColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 再認証処理
  Future<void> _handleReauthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final providerData = user.providerData;
    if (providerData.isEmpty) {
      debugPrint('[DeleteAccount] no provider found');
      _showReauthErrorDialog('認証プロバイダーが見つかりません');
      return;
    }

    final providerId = providerData.first.providerId;
    debugPrint('[DeleteAccount] detected provider: $providerId');

    try {
      if (providerId == 'apple.com') {
        debugPrint('[DeleteAccount] reauthenticating with Apple...');
        
        final appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        
        final userCredential = await user.reauthenticateWithProvider(appleProvider);
        
        if (userCredential.user != null) {
          debugPrint('[DeleteAccount] reauth success with Apple');
          await _retryDeleteAccount();
        }
        return;
      } else if (providerId == 'google.com') {
        debugPrint('[DeleteAccount] reauthenticating with Google...');
        
        final googleProvider = GoogleAuthProvider();
        final userCredential = await user.reauthenticateWithProvider(googleProvider);
        
        if (userCredential.user != null) {
          debugPrint('[DeleteAccount] reauth success with Google');
          await _retryDeleteAccount();
        }
        return;
      } else if (providerId == 'password') {
        debugPrint('[DeleteAccount] email/password provider detected');
        _showReauthErrorDialog(
          'メール/パスワードでログインしている場合は、\n'
          '一度ログアウトして再ログイン後に\n'
          'アカウント削除を実行してください。'
        );
        return;
      }

      debugPrint('[DeleteAccount] unsupported provider: $providerId');
      _showReauthErrorDialog('サポートされていない認証方法です');

    } on FirebaseAuthException catch (e) {
      debugPrint('[DeleteAccount] reauth failed: ${e.code}');
      
      if (e.code == 'user-cancelled') {
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再認証に失敗しました: ${e.message}'),
            backgroundColor: FamicaColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DeleteAccount] reauth error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('再認証中にエラーが発生しました: $e'),
            backgroundColor: FamicaColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 再認証後のアカウント削除リトライ
  Future<void> _retryDeleteAccount() async {
    if (!mounted) return;

    debugPrint('[DeleteAccount] retrying delete after reauth...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('アカウントを削除しています...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      final uid = user.uid;

      debugPrint('[DeleteAccount] deleting Firestore data (retry)...');
      final result = await FirebaseFunctions.instance
          .httpsCallable('deleteUserData')
          .call({'uid': uid});

      if (result.data == null || result.data['success'] != true) {
        throw Exception('Firestoreデータの削除に失敗しました');
      }

      debugPrint('[DeleteAccount] Firestore data deleted (retry)');

      debugPrint('[DeleteAccount] deleting auth account (retry)...');
      await user.delete();

      debugPrint('[DeleteAccount] delete success (retry)');

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        debugPrint('[DeleteAccount] navigate to /auth');
        context.go('/auth');
      }
    } catch (e) {
      debugPrint('[DeleteAccount] retry failed: $e');

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: ${e.toString()}'),
            backgroundColor: FamicaColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 再認証エラーダイアログ
  void _showReauthErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('再認証が必要です'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              FirebaseAuth.instance.signOut();
              context.go('/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FamicaColors.primary,
            ),
            child: const Text('ログアウトする'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ログアウト',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ログアウトしますか？\n再度ログインが必要になります。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FamicaColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('ログアウト'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await FirebaseAuth.instance.signOut();
      }
    });
  }

  void _showNicknameEditBottomSheet() {
    final controller = TextEditingController(text: _nicknameController.text);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: FamicaColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'ニックネーム変更',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: FamicaColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'ニックネームを入力',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: FamicaColors.primary,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLength: 20,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nickname = controller.text.trim();
                    
                    if (nickname.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ニックネームを入力してください'),
                          backgroundColor: FamicaColors.error,
                        ),
                      );
                      return;
                    }

                    try {
                      await _firestoreService.updateMyNickname(nickname);
                      
                      _nicknameController.text = nickname;
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ 変更を保存しました'),
                            backgroundColor: FamicaColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ エラーが発生しました: $e'),
                            backgroundColor: FamicaColors.error,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FamicaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '変更を保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ℹ️ ニックネームは全画面で即時反映されます',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
