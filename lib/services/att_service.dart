import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// ATT（App Tracking Transparency）管理サービス
/// iOS 14.5以降の広告ID取得に必須
class ATTService {
  static final ATTService _instance = ATTService._internal();
  factory ATTService() => _instance;
  ATTService._internal();

  bool _hasRequestedPermission = false;
  TrackingStatus? _currentStatus;

  /// ATT許可をリクエスト（1回のみ実行）
  /// iOS以外では何もしない
  Future<TrackingStatus> requestPermission() async {
    if (!Platform.isIOS) {
      print('✅ [ATT] Android detected - skipping ATT request');
      return TrackingStatus.notSupported;
    }

    // 既にリクエスト済みなら再度リクエストしない
    if (_hasRequestedPermission && _currentStatus != null) {
      print('ℹ️ [ATT] Already requested - returning cached status: $_currentStatus');
      return _currentStatus!;
    }

    try {
      // 現在のステータスを確認
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      print('📊 [ATT] Current status: $status');

      if (status == TrackingStatus.notDetermined) {
        // 未決定の場合のみリクエスト
        print('🔔 [ATT] Requesting tracking authorization...');
        _currentStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        _hasRequestedPermission = true;
        print('✅ [ATT] Permission requested - result: $_currentStatus');
      } else {
        // 既に決定済み（authorized/denied/restricted）
        _currentStatus = status;
        _hasRequestedPermission = true;
        print('ℹ️ [ATT] Already determined - status: $_currentStatus');
      }

      return _currentStatus!;
    } catch (e) {
      print('❌ [ATT] Request error: $e');
      _currentStatus = TrackingStatus.notDetermined;
      return _currentStatus!;
    }
  }

  /// 現在のATTステータスを取得（リクエストせずに確認のみ）
  Future<TrackingStatus> getStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    try {
      _currentStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
      return _currentStatus!;
    } catch (e) {
      print('❌ [ATT] Get status error: $e');
      return TrackingStatus.notDetermined;
    }
  }

  /// トラッキング許可されているかどうか
  Future<bool> isAuthorized() async {
    final status = await getStatus();
    return status == TrackingStatus.authorized;
  }

  /// 広告IDの取得が可能かどうか
  Future<bool> canShowAds() async {
    if (!Platform.isIOS) {
      // Androidは常に広告表示可能
      return true;
    }

    // iOSの場合、ATTステータスに関わらず広告は表示可能
    // （非パーソナライズ広告として表示される）
    return true;
  }
}
