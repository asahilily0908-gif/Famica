import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'constants/famica_colors.dart';
import 'widgets/common_context_menu.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

/// Famica v3.0 認証画面
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AppLocalizations get l => AppLocalizations.of(context)!;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _householdNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isSignUpMode = false; // 新規登録モードかどうか
  bool _hasInviteCode = false; // 招待コードを持っているか

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _householdNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  /// ログイン/新規登録のメイン処理
  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    // 入力チェック
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(l.authErrorEmptyFields, isError: true);
      return;
    }

    // 新規登録モードの場合はニックネームとカップル名もチェック
    if (_isSignUpMode && nickname.isEmpty) {
      _showSnackBar(l.authErrorEmptyNickname, isError: true);
      return;
    }

    final householdName = _householdNameController.text.trim();
    final inviteCode = _inviteCodeController.text.trim().toUpperCase();
    
    // 招待コードがある場合はカップル名不要
    if (_isSignUpMode && !_hasInviteCode && householdName.isEmpty) {
      _showSnackBar(l.authErrorEmptyHousehold, isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar(l.authErrorInvalidEmail, isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar(l.authErrorWeakPassword, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUpMode) {
        // 新規登録モード
        if (_hasInviteCode && inviteCode.isNotEmpty) {
          // 招待コード経由で参加
          await _signUpWithInviteCode(email, password, nickname, inviteCode);
        } else {
          // 新しい世帯を作成
          await _signUp(email, password, nickname, householdName);
        }
      } else {
        // ログインモード
        await _signIn(email, password);
      }
    } on FirebaseAuthException catch (e) {
      // ログイン失敗時の処理
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // ユーザーが存在しない場合は新規登録モードに切り替え
        setState(() {
          _isSignUpMode = true;
          _isLoading = false;
        });
        _showSnackBar(l.authErrorUserNotFound, isError: true);
        return;
      } else if (e.code == 'wrong-password') {
        _showSnackBar(l.authErrorWrongPassword, isError: true);
      } else if (e.code == 'invalid-email') {
        _showSnackBar(l.authErrorInvalidEmail, isError: true);
      } else if (e.code == 'user-disabled') {
        _showSnackBar(l.authErrorDisabled, isError: true);
      } else if (e.code == 'too-many-requests') {
        _showSnackBar(l.authErrorTooMany, isError: true);
      } else if (e.code == 'network-request-failed') {
        _showSnackBar(l.authErrorNetwork, isError: true);
      } else {
        _showSnackBar('${l.authErrorLogin}: ${e.message}', isError: true);
      }
    } catch (e) {
      _showSnackBar('${l.authErrorUnexpected}: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ログイン処理
  Future<void> _signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    _showSnackBar(l.authLoginSuccess, isError: false);
  }

  /// 招待コード経由の新規登録処理（transaction化）
  Future<void> _signUpWithInviteCode(String email, String password, String nickname, String inviteCode) async {
    try {
      print('🔧 招待コード経由の登録開始: $inviteCode');

      // 1️⃣ Firebase Authenticationでユーザー作成
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('ユーザーの作成に失敗しました');
      }

      print('✅ Firebase Auth登録完了: uid=${user.uid}');

      // サインイン完了待機（認証トークン生成待ち）
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
      print('✅ Auth SignUp Completed: ${FirebaseAuth.instance.currentUser?.uid}');

      // 2️⃣ 認証完了後に招待コード検索を実行（inviteCodesコレクションを優先）
      print('🔥 招待コード検索開始: $inviteCode');

      String? householdId;

      // まず inviteCodes コレクションで検索（正規ルート）
      final inviteCodeDoc = await FirebaseFirestore.instance
          .collection('inviteCodes')
          .doc(inviteCode.toUpperCase())
          .get();

      if (inviteCodeDoc.exists) {
        final inviteData = inviteCodeDoc.data()!;
        final used = inviteData['used'] as bool? ?? false;
        if (used) {
          print('⚠️ 招待コードは既に使用されています: $inviteCode');
          _showSnackBar(l.authInviteUsed, isError: true);
          setState(() => _isLoading = false);
          return;
        }
        householdId = inviteData['householdId'] as String?;
      }

      // inviteCodesに無い場合はhouseholdsコレクションでフォールバック検索
      if (householdId == null) {
        final householdQuery = await FirebaseFirestore.instance
            .collection('households')
            .where('inviteCode', isEqualTo: inviteCode)
            .limit(1)
            .get();

        if (householdQuery.docs.isEmpty) {
          print('⚠️ 招待コードが見つかりません: $inviteCode');
          _showSnackBar(l.authInviteNotFound, isError: true);
          setState(() => _isLoading = false);
          return;
        }

        householdId = householdQuery.docs.first.id;
        final householdData = householdQuery.docs.first.data();
        final inviteActive = householdData['inviteActive'] as bool? ?? true;
        if (!inviteActive) {
          print('⚠️ 招待コードは既に使用されています: $inviteCode');
          _showSnackBar(l.authInviteUsed, isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      print('✅ 招待コード確認: $inviteCode → householdId: $householdId');

      // Firebase AuthにdisplayNameを設定
      await user.updateDisplayName(nickname);
      await user.reload();
      
      print('✅ displayName設定完了: ${user.displayName}');

      // 3️⃣  usersドキュメントを作成
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': nickname,
        'nickname': nickname,
        'email': email,
        'householdId': householdId,
        'role': 'partner',
        'lifeStage': 'couple',
        'plan': 'free',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ users/${user.uid} 作成完了 (nickname: $nickname)');

      // 4️⃣ householdのmembers配列に追加 & inviteActive無効化
      final householdRef = FirebaseFirestore.instance.collection('households').doc(householdId);
      final householdSnap = await householdRef.get();
      
      if (!householdSnap.exists) {
        throw Exception('世帯が見つかりません');
      }

      final currentHouseholdData = householdSnap.data()!;
      final members = List<Map<String, dynamic>>.from(currentHouseholdData['members'] ?? []);
      
      // 重複チェック
      final exists = members.any((m) => m['uid'] == user.uid);
      if (!exists) {
        members.add({
          'uid': user.uid,
          'name': nickname,
          'nickname': nickname,
          'role': 'partner',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$nickname',
        });

        await householdRef.update({
          'members': members,
          'inviteActive': false, // 招待コード無効化
        });

        // inviteCodesコレクションも使用済みに更新
        try {
          await FirebaseFirestore.instance
              .collection('inviteCodes')
              .doc(inviteCode.toUpperCase())
              .update({
            'used': true,
            'usedAt': FieldValue.serverTimestamp(),
            'usedBy': user.uid,
          });
        } catch (_) {
          // inviteCodesドキュメントが存在しない場合は無視
        }

        print('✅ households/$householdId/members に追加完了');
        print('🔒 招待コード無効化完了（households.inviteActive + inviteCodes.used）');
      }

      // デフォルトテンプレートを作成（transaction外で実行、失敗しても登録は成功とする）
      try {
        await _firestoreService.createDefaultQuickTemplates(householdId, 'couple');
        print('✅ デフォルトテンプレート作成完了');
      } catch (e) {
        print('⚠️ テンプレート作成エラー（登録は成功）: $e');
      }

      // Firestore書き込み完了を確認（最大3回リトライ）
      bool verified = false;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        
        final verifyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (verifyDoc.exists) {
          final data = verifyDoc.data();
          if (data?['householdId'] == householdId && data?['displayName'] == nickname) {
            verified = true;
            print('✅ Firestore書き込み確認成功: householdId=$householdId, nickname=$nickname');
            break;
          }
        }
        
        if (i < 2) {
          print('⚠️ Firestore確認失敗、リトライ中... (${i + 1}/3)');
        }
      }

      if (!verified) {
        print('⚠️ Firestore確認タイムアウト（登録は完了している可能性あり）');
      }

      _showSnackBar(l.authInviteSuccess, isError: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar(l.authErrorEmailInUse, isError: true);
      } else if (e.code == 'weak-password') {
        _showSnackBar(l.authErrorWeakPasswordSignUp, isError: true);
      } else {
        _showSnackBar('${l.authErrorSignUp}: ${e.message}', isError: true);
      }
      rethrow;
    }
  }

  /// 新規登録処理
  Future<void> _signUp(String email, String password, String nickname, String householdName) async {
    try {
      print('🔧 新規登録開始');

      // Firebase Authenticationでユーザー作成
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('ユーザーの作成に失敗しました');
      }

      print('✅ Firebase Auth登録完了: uid=${user.uid}');

      // Firebase AuthにdisplayNameを設定
      await user.updateDisplayName(nickname);
      await user.reload();
      
      print('✅ displayName設定完了: ${user.displayName}');

      // householdIdを生成（ユーザーUIDをベースに）
      final householdId = user.uid;

      // Firestoreにユーザー情報と世帯情報を作成（必ず完了を待つ）
      await _createUserAndHousehold(user.uid, email, nickname, householdName, householdId);

      // Firestore書き込み完了を確認（最大3回リトライ）
      bool verified = false;
      for (int i = 0; i < 3; i++) {
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        
        final verifyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (verifyDoc.exists) {
          final data = verifyDoc.data();
          if (data?['householdId'] == householdId && data?['displayName'] == nickname) {
            verified = true;
            print('✅ Firestore書き込み確認成功: householdId=$householdId, nickname=$nickname');
            break;
          }
        }
        
        if (i < 2) {
          print('⚠️ Firestore確認失敗、リトライ中... (${i + 1}/3)');
        }
      }

      if (!verified) {
        print('⚠️ Firestore確認タイムアウト（登録は完了している可能性あり）');
      }

      _showSnackBar(l.authSignUpSuccess, isError: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar(l.authErrorEmailInUse, isError: true);
      } else if (e.code == 'weak-password') {
        _showSnackBar(l.authErrorWeakPasswordSignUp, isError: true);
      } else if (e.code == 'operation-not-allowed') {
        _showSnackBar(l.authErrorOperationNotAllowed, isError: true);
      } else {
        _showSnackBar('${l.authErrorSignUp}: ${e.message}', isError: true);
      }
      rethrow;
    }
  }

  /// 新規ユーザーの情報と世帯情報を作成
  Future<void> _createUserAndHousehold(
    String uid,
    String email,
    String displayName,
    String householdName,
    String householdId,
  ) async {
    try {
      print('🔧 ユーザー情報作成開始: $displayName');

      // ユーザー情報を作成（必ず完了を待つ）
      await _firestoreService.createOrUpdateUser(
        uid: uid,
        email: email,
        displayName: displayName,
        householdId: householdId,
        role: 'main',
        lifeStage: 'couple',
      );
      
      print('✅ users/$uid 作成完了');

      // 世帯情報を作成（カップル名を使用）
      await _firestoreService.createOrUpdateHousehold(
        householdId: householdId,
        name: householdName,
        uid: uid,
        memberName: displayName,
        role: 'main',
        lifeStage: 'couple',
      );
      
      print('✅ households/$householdId 作成完了');

      // デフォルトテンプレートを作成
      await _firestoreService.createDefaultQuickTemplates(householdId, 'couple');
      print('✅ デフォルトテンプレート作成完了');

      print('🎉 新規ユーザーの情報と世帯情報を作成完了');
      print('   householdId: $householdId');
      print('   householdName: $householdName');
    } catch (e) {
      print('❌ ユーザー情報/世帯情報の作成エラー: $e');
      throw e; // エラーを上に伝播させる
    }
  }

  /// メールアドレスの形式チェック
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// スナックバーでメッセージを表示
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? FamicaColors.error : FamicaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: FamicaColors.backgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: FractionallySizedBox(
              widthFactor: 0.95,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // アプリロゴとタイトル
                      Icon(
                        Icons.favorite,
                        size: 80,
                        color: FamicaColors.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Famica',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayLarge.copyWith(
                          color: FamicaColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.appTagline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // メールアドレス入力欄
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l.authEmailLabel,
                          hintText: l.authEmailHint,
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        contextMenuBuilder: buildFamicaContextMenu,
                      ),
                      const SizedBox(height: 16),

                      // パスワード入力欄
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l.authPasswordLabel,
                          hintText: l.authPasswordHint,
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        enabled: !_isLoading,
                        contextMenuBuilder: buildFamicaContextMenu,
                      ),
                      
                      // ニックネーム入力欄（新規登録モードのみ表示）
                      if (_isSignUpMode) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: l.authNicknameLabel,
                            hintText: l.authNicknameHint,
                            prefixIcon: const Icon(Icons.person),
                            helperText: l.authNicknameHelper,
                          ),
                          enabled: !_isLoading,
                          contextMenuBuilder: buildFamicaContextMenu,
                        ),
                        const SizedBox(height: 16),
                        
                        // 招待コード選択
                        Row(
                          children: [
                            Checkbox(
                              value: _hasInviteCode,
                              onChanged: _isLoading ? null : (value) {
                                setState(() {
                                  _hasInviteCode = value ?? false;
                                });
                              },
                            ),
                            Text(l.authHasInviteCode),
                          ],
                        ),
                        
                        if (_hasInviteCode) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _inviteCodeController,
                            decoration: InputDecoration(
                              labelText: l.authInviteCodeLabel,
                              hintText: l.authInviteCodeHint,
                              prefixIcon: const Icon(Icons.vpn_key),
                              helperText: l.authInviteCodeHelper,
                            ),
                            enabled: !_isLoading,
                            textCapitalization: TextCapitalization.characters,
                            contextMenuBuilder: buildFamicaContextMenu,
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _householdNameController,
                            decoration: InputDecoration(
                              labelText: l.authHouseholdNameLabel,
                              hintText: l.authHouseholdNameHint,
                              prefixIcon: const Icon(Icons.home),
                              helperText: l.authHouseholdNameHelper,
                            ),
                            enabled: !_isLoading,
                            contextMenuBuilder: buildFamicaContextMenu,
                          ),
                        ],
                      ],
                      const SizedBox(height: 32),

                      // ログイン/登録ボタン
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.white, // ボタン文字を白に固定
                          disabledForegroundColor: Colors.white, // disabled時も白
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUpMode ? l.authSignUp : l.authLoginOrSignUp,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white, // 明示的に白指定
                                ),
                              ),
                      ),
                      
                      // モード切り替えボタン
                      if (_isSignUpMode) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _isSignUpMode = false;
                              _hasInviteCode = false;
                              _nicknameController.clear();
                              _householdNameController.clear();
                              _inviteCodeController.clear();
                            });
                          },
                          child: Text(l.authSwitchToLogin),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 説明文
                      Text(
                        _isSignUpMode
                            ? l.authSignUpNote
                            : l.authLoginNote,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
