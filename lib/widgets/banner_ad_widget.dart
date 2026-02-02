import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

/// バナー広告ウィジェット（全ユーザー対象）
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  // iOS AdMob 設定
  static const String _iosAppId = 'ca-app-pub-3184270565267183~8340379507';
  static const String _iosBannerAdUnitIdProd = 'ca-app-pub-3184270565267183/7433426282';
  static const String _iosBannerAdUnitIdTest = 'ca-app-pub-3940256099942544/2934735716';
  
  // Android AdMob 設定（参考用 - 変更しない）
  static const String _androidBannerAdUnitIdProd = 'ca-app-pub-3184270565267183/5633035433';
  static const String _androidBannerAdUnitIdTest = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // ビルドモードに応じて自動切り替え
    // Debug/Profile: テスト広告、Release: 本番広告
    final bool useTestAds = kDebugMode || kProfileMode;
    
    // プラットフォーム判定
    final bool isIOS = Platform.isIOS;
    
    // 広告ユニットIDを決定
    String adUnitId;
    if (isIOS) {
      adUnitId = useTestAds ? _iosBannerAdUnitIdTest : _iosBannerAdUnitIdProd;
    } else {
      adUnitId = useTestAds ? _androidBannerAdUnitIdTest : _androidBannerAdUnitIdProd;
    }
    
    // ログ出力（要件準拠）
    print('🔷 [BannerAd] 広告読み込み開始');
    print('   プラットフォーム: ${isIOS ? "iOS" : "Android"}');
    print('   ビルドモード: ${kReleaseMode ? "Release" : (kProfileMode ? "Profile" : "Debug")}');
    print('   テスト広告使用: ${useTestAds ? "はい" : "いいえ"}');
    
    if (isIOS) {
      print('   iOS App ID: $_iosAppId');
    }
    
    // セキュリティのため、adUnitId の最初20文字のみ表示
    final String adUnitIdPreview = adUnitId.length > 20 
        ? '${adUnitId.substring(0, 20)}...' 
        : adUnitId;
    print('   広告ユニットID: $adUnitIdPreview');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ [BannerAd] 広告読み込み成功');
          if (ad is BannerAd) {
            print('   サイズ: ${ad.size.width}x${ad.size.height}');
          }
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _errorMessage = null;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ [BannerAd] 広告読み込み失敗');
          print('   エラーコード: ${error.code}');
          print('   エラーメッセージ: ${error.message}');
          print('   エラードメイン: ${error.domain}');
          print('   レスポンス情報: ${error.responseInfo}');
          
          // エラー原因の診断
          _diagnoseError(error, isIOS);
          
          if (mounted) {
            setState(() {
              _errorMessage = error.message;
            });
          }
          
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('📱 [BannerAd] 広告がタップされました');
        },
        onAdClosed: (ad) {
          print('🔙 [BannerAd] 広告が閉じられました');
        },
        onAdImpression: (ad) {
          print('👁️ [BannerAd] 広告が表示されました（インプレッション記録）');
        },
      ),
    );

    await _bannerAd!.load();
  }

  /// エラーの原因を診断して出力
  void _diagnoseError(LoadAdError error, bool isIOS) {
    switch (error.code) {
      case 0: // ERROR_CODE_INTERNAL_ERROR
        print('💡 診断: 内部エラー。AdMobサーバー側の一時的な問題の可能性があります。');
        break;
      case 1: // ERROR_CODE_INVALID_REQUEST
        print('💡 診断: 無効なリクエスト。広告ユニットIDが正しいか確認してください。');
        final String? currentAdUnitId = _bannerAd?.adUnitId;
        if (currentAdUnitId != null && currentAdUnitId.length > 20) {
          print('   現在の広告ユニットID: ${currentAdUnitId.substring(0, 20)}...');
        }
        break;
      case 2: // ERROR_CODE_NETWORK_ERROR
        print('💡 診断: ネットワークエラー。インターネット接続を確認してください。');
        break;
      case 3: // ERROR_CODE_NO_FILL
        print('💡 診断: 広告在庫なし（NO_FILL）。');
        print('   → 新しい広告ユニットIDの場合、広告配信まで数時間かかることがあります。');
        print('   → テスト広告IDで試すことを推奨します。');
        break;
      default:
        print('💡 診断: 不明なエラー（コード: ${error.code}）');
    }
    
    // iOS特有の問題チェック
    if (isIOS) {
      print('📱 iOS特有のチェック:');
      print('   - Info.plistにGADApplicationIdentifier ($_iosAppId) が設定されているか確認');
      print('   - 広告ユニットIDが同じPublisher ID (ca-app-pub-3184270565267183) であるか確認');
      print('   - ATT（App Tracking Transparency）の権限が許可されているか確認');
      print('   - SKAdNetworkItemsが設定されているか確認');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 広告が読み込まれたら表示
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // デバッグモードの場合、エラーメッセージを表示
    if (kDebugMode && _errorMessage != null) {
      return Container(
        height: 50,
        color: Colors.red.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            '広告エラー: $_errorMessage',
            style: const TextStyle(fontSize: 10, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 読み込み中またはエラー時は空のコンテナ
    return const SizedBox.shrink();
  }
}
