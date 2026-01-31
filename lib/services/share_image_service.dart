import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/famica_colors.dart';

/// SNS共有画像生成サービス
class ShareImageService {
  /// 記念日達成画像を生成してシェア
  static Future<void> shareAnniversary({
    required BuildContext context,
    required String title,
    required String icon,
    required int years,
    required DateTime date,
  }) async {
    try {
      // 画像生成用のWidgetを作成
      final widget = _AnniversaryShareCard(
        title: title,
        icon: icon,
        years: years,
        date: date,
      );

      // PNGに変換
      final file = await _widgetToImage(widget);

      // シェア
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$title 🎉 $years周年を迎えました！\n\n#Famica #${title.replaceAll(' ', '')} #カップル記録',
      );
    } catch (e) {
      debugPrint('❌ 共有画像生成エラー: $e');
      rethrow;
    }
  }

  /// バッジ達成画像を生成してシェア
  static Future<void> shareAchievement({
    required BuildContext context,
    required String title,
    required String badgeIcon,
    required String description,
    required int value,
  }) async {
    try {
      final widget = _AchievementShareCard(
        title: title,
        badgeIcon: badgeIcon,
        description: description,
        value: value,
      );

      final file = await _widgetToImage(widget);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$badgeIcon $title 達成！\n$description\n\n#Famica #カップル記録 #継続は力なり',
      );
    } catch (e) {
      debugPrint('❌ 共有画像生成エラー: $e');
      rethrow;
    }
  }

  /// WidgetをPNG画像ファイルに変換
  static Future<File> _widgetToImage(Widget widget) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    
    final RenderView renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: const ViewConfiguration(
        devicePixelRatio: 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(1080, 1920),
            devicePixelRatio: 1.0,
          ),
          child: Material(
            color: Colors.transparent,
            child: widget,
          ),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/famica_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }
}

/// 記念日共有カード
class _AnniversaryShareCard extends StatelessWidget {
  final String title;
  final String icon;
  final int years;
  final DateTime date;

  const _AnniversaryShareCard({
    required this.title,
    required this.icon,
    required this.years,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FamicaColors.background,
            FamicaColors.accent.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン
          Text(
            icon,
            style: const TextStyle(fontSize: 200),
          ),
          const SizedBox(height: 40),
          
          // タイトル
          Text(
            title,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: FamicaColors.text,
            ),
          ),
          const SizedBox(height: 20),
          
          // 周年表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
            decoration: BoxDecoration(
              color: FamicaColors.accent,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '$years周年 🎉',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // 日付
          Text(
            '${date.year}.${date.month}.${date.day}',
            style: TextStyle(
              fontSize: 48,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 100),
          
          // Famicaロゴ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Text(
              'Famica',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: FamicaColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// バッジ共有カード
class _AchievementShareCard extends StatelessWidget {
  final String title;
  final String badgeIcon;
  final String description;
  final int value;

  const _AchievementShareCard({
    required this.title,
    required this.badgeIcon,
    required this.description,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FamicaColors.accent.withOpacity(0.3),
            FamicaColors.background,
            Colors.amber.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // バッジアイコン
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                badgeIcon,
                style: const TextStyle(fontSize: 150),
              ),
            ),
          ),
          const SizedBox(height: 60),
          
          // Achievement!
          const Text(
            'Achievement!',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // タイトル
          Text(
            title,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: FamicaColors.text,
            ),
          ),
          const SizedBox(height: 20),
          
          // 説明
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 40),
          
          // 達成数値
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              '$value回達成',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: FamicaColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 100),
          
          // Famicaロゴ
          const Text(
            'Famica',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: FamicaColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
