import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/tip.dart';
import '../../presentation/widgets/tip_share_card.dart';

enum TipShareResult { success, cancelled, failed }

/// 教程分享服务
///
/// - 纯文本分享：复制格式化内容到剪贴板
/// - 图片分享：通过 Overlay 捕获分享卡片，生成包含二维码的长图
class TipShareService {
  Future<TipShareResult> shareAsText(Tip tip) async {
    try {
      final text = _formatTipText(tip);
      await Clipboard.setData(ClipboardData(text: text));
      return TipShareResult.success;
    } catch (e, stackTrace) {
      debugPrint('分享教程文本失败: $e');
      debugPrint('Stack: $stackTrace');
      return TipShareResult.failed;
    }
  }

  Future<TipShareResult> shareAsImage(
    Tip tip,
    BuildContext context, {
    bool saveOnly = false,
  }) async {
    try {
      final imageBytes = await generateTipImageBytes(tip, context);

      if (imageBytes == null) {
        debugPrint('生成教程分享图片失败：imageBytes is null');
        return TipShareResult.failed;
      }

      if (saveOnly) {
        return await saveImageBytes(imageBytes, tip);
      }

      return await shareImageBytes(imageBytes, tip);
    } catch (e, stackTrace) {
      debugPrint('分享教程图片失败: $e');
      debugPrint('Stack: $stackTrace');
      return TipShareResult.failed;
    }
  }

  Future<Uint8List?> generateTipImageBytes(
    Tip tip,
    BuildContext context,
  ) async {
    final qrData = _generateCustomScheme(tip);
    return _captureWidgetAsImage(tip: tip, qrData: qrData, context: context);
  }

  String _formatTipText(Tip tip) {
    final buffer = StringBuffer();

    buffer.writeln('📘「${tip.title}」');
    buffer.writeln();
    buffer.writeln('📂 分类：${tip.categoryName}');
    buffer.writeln();

    if (tip.content.isNotEmpty) {
      buffer.writeln('📝 正文');
      buffer.writeln(tip.content.trim());
      buffer.writeln();
    }

    if (tip.sections.isNotEmpty) {
      buffer.writeln('🔍 教程分节');
      for (var i = 0; i < tip.sections.length; i++) {
        final section = tip.sections[i];
        buffer.writeln('${i + 1}. ${section.title}');
        buffer.writeln(section.content.trim());
        if (i != tip.sections.length - 1) {
          buffer.writeln();
        }
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('分享自「智能菜谱助手」');
    return buffer.toString();
  }

  String _generateCustomScheme(Tip tip) {
    try {
      final payload = {
        'type': 'tip',
        'id': tip.id,
        'title': tip.title,
        'category': tip.category,
        'categoryName': tip.categoryName,
        'content': tip.content,
        'sections': [
          for (final section in tip.sections)
            {'title': section.title, 'content': section.content},
        ],
        'hash': tip.hash,
      };

      final jsonString = jsonEncode(payload);
      final utf8Bytes = utf8.encode(jsonString);

      if (utf8Bytes.length < 1000) {
        final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
        return 'howtocook://tip?raw=$base64String';
      }

      final gzipBytes = GZipEncoder().encode(utf8Bytes);
      if (gzipBytes == null) {
        final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
        return 'howtocook://tip?raw=$base64String';
      }

      if (gzipBytes.length >= utf8Bytes.length * 0.9) {
        final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
        return 'howtocook://tip?raw=$base64String';
      }

      final base64String = base64Url.encode(gzipBytes).replaceAll('=', '');
      return 'howtocook://tip?data=$base64String';
    } catch (e, stackTrace) {
      debugPrint('生成 Tip Custom Scheme 失败: $e');
      debugPrint('Stack: $stackTrace');
      return _fallbackScheme(tip);
    }
  }

  String _fallbackScheme(Tip tip) {
    final payload = {
      'id': tip.id,
      'title': tip.title,
      'categoryName': tip.categoryName,
      if (tip.sections.isNotEmpty)
        'sections': tip.sections
            .take(2)
            .map((section) => section.title)
            .toList(),
    };
    final jsonString = jsonEncode(payload);
    final encoded = Uri.encodeComponent(jsonString);
    return 'howtocook://tip?json=$encoded';
  }

  Future<Uint8List?> _captureWidgetAsImage({
    required Tip tip,
    required String qrData,
    required BuildContext context,
  }) async {
    try {
      final repaintKey = GlobalKey();
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: repaintKey,
            child: SizedBox(
              width: 375,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 10000),
                  devicePixelRatio: 2.0,
                  textScaler: TextScaler.linear(1.0),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TipShareCard(tip: tip, qrData: qrData),
                ),
              ),
            ),
          ),
        ),
      );

      final overlayState = Overlay.of(context, rootOverlay: true);
      overlayState.insert(overlayEntry);

      await Future<void>.delayed(const Duration(milliseconds: 1000));

      final renderObject = repaintKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('无法获取 RenderRepaintBoundary');
        overlayEntry.remove();
        return null;
      }

      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      overlayEntry.remove();

      if (byteData == null) {
        debugPrint('图片转换失败：byteData 为 null');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      debugPrint('捕获教程分享图片失败: $e');
      debugPrint('Stack: $stackTrace');
      return null;
    }
  }

  Future<TipShareResult> saveImageBytes(Uint8List imageBytes, Tip tip) async {
    try {
      await Gal.putImageBytes(
        imageBytes,
        name: 'tip_${tip.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      return TipShareResult.success;
    } catch (e, stackTrace) {
      debugPrint('保存教程图片失败: $e');
      debugPrint('Stack: $stackTrace');
      return TipShareResult.failed;
    }
  }

  Future<TipShareResult> shareImageBytes(Uint8List imageBytes, Tip tip) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/tip_${tip.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)], text: '分享教程「${tip.title}」');
      return TipShareResult.success;
    } catch (e, stackTrace) {
      debugPrint('分享教程图片（二次）失败: $e');
      debugPrint('Stack: $stackTrace');
      return TipShareResult.failed;
    }
  }
}
