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
    print('🔷 [BannerAd] 広告読み込み開始');
    print('   プラットフォーム: ${Platform.isIOS ? "iOS" : "Android"}');
    
    // テストモード制御: const USE_TEST_ADS = true; にするとテスト広告を使用
    const bool USE_TEST_ADS = false;
    
    String adUnitId;
    if (USE_TEST_ADS) {
      // Googleの公式テスト広告ID
      adUnitId = Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716' // iOS テスト
          : 'ca-app-pub-3940256099942544/6300978111'; // Android テスト
      print('   ⚠️ テストモード: テスト広告IDを使用');
    } else {
      // 本番広告ID
      adUnitId = Platform.isIOS
          ? 'ca-app-pub-3184270565267183/7433426282' // iOS 本番
          : 'ca-app-pub-3184270565267183/5633035433'; // Android 本番
      print('   本番モード: 本番広告IDを使用');
    }
    
    print('   広告ユニットID: $adUnitId');

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
          _diagnoseError(error);
          
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
  void _diagnoseError(LoadAdError error) {
    switch (error.code) {
      case 0: // ERROR_CODE_INTERNAL_ERROR
        print('💡 診断: 内部エラー。AdMobサーバー側の一時的な問題の可能性があります。');
        break;
      case 1: // ERROR_CODE_INVALID_REQUEST
        print('💡 診断: 無効なリクエスト。広告ユニットIDが正しいか確認してください。');
        print('   現在の広告ユニットID: ${_bannerAd?.adUnitId}');
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
    if (Platform.isIOS) {
      print('📱 iOS特有のチェック:');
      print('   - Info.plistにGADApplicationIdentifierが設定されているか確認');
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
