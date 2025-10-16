import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
class TipShareService {
  Future<TipShareResult> shareAsText(Tip tip) async {
    try {
      final text = _formatTipText(tip);
      await Clipboard.setData(ClipboardData(text: text));
      return TipShareResult.success;
    } catch (e) {
      debugPrint('分享教程文本失败: $e');
      return TipShareResult.failed;
    }
  }

  Future<TipShareResult> shareAsImage(
    Tip tip,
    BuildContext context, {
    bool saveOnly = false,
  }) async {
    try {
      final qrData = _generateCustomScheme(tip);
      final imageBytes = await generateTipImageBytes(
        tip: tip,
        qrData: qrData,
        context: context,
      );

      if (imageBytes == null) {
        debugPrint('生成教程分享图片失败：imageBytes is null');
        return TipShareResult.failed;
      }

      if (saveOnly) {
        await Gal.putImageBytes(
          imageBytes,
          name: 'tip_${tip.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
        return TipShareResult.success;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/tip_${tip.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)], text: '分享教程《${tip.title}》');
      return TipShareResult.success;
    } catch (e) {
      debugPrint('分享教程图片失败: $e');
      return TipShareResult.failed;
    }
  }

  Future<Uint8List?> generateTipImageBytes({
    required Tip tip,
    required String qrData,
    required BuildContext context,
  }) async {
    try {
      final key = GlobalKey();
      OverlayEntry? overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (_) => Positioned(
          left: -10000,
          top: 0,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 375,
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 2000),
                  devicePixelRatio: 2.0,
                  textScaler: TextScaler.linear(1.0),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: TipShareCard(tip: tip, qrData: qrData),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      overlayEntry.remove();

      return pngBytes;
    } catch (e) {
      debugPrint('捕获教程分享图片失败: $e');
      return null;
    }
  }

  String _formatTipText(Tip tip) {
    final buffer = StringBuffer();

    buffer.writeln('📘《${tip.title}》');
    buffer.writeln('分类：${tip.categoryName}');
    buffer.writeln();

    if (tip.content.isNotEmpty) {
      buffer.writeln(tip.content);
      buffer.writeln();
    }

    for (int i = 0; i < tip.sections.length; i++) {
      final section = tip.sections[i];
      buffer.writeln('【${section.title}】');
      buffer.writeln(section.content);
      if (i != tip.sections.length - 1) {
        buffer.writeln();
      }
    }

    buffer.writeln();
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
        'sections': tip.sections
            .map(
              (section) => {'title': section.title, 'content': section.content},
            )
            .toList(),
        'hash': tip.hash,
      };

      final jsonString = jsonEncode(payload);
      final utf8Bytes = utf8.encode(jsonString);

      if (utf8Bytes.length < 1000) {
        final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
        return 'howtocook://tip?raw=$base64String';
      } else {
        final gzipBytes = GZipEncoder().encode(utf8Bytes);
        if (gzipBytes == null || gzipBytes.length >= utf8Bytes.length * 0.9) {
          final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
          return 'howtocook://tip?raw=$base64String';
        }
        final base64String = base64Url.encode(gzipBytes).replaceAll('=', '');
        return 'howtocook://tip?data=$base64String';
      }
    } catch (e) {
      debugPrint('生成 Tip Custom Scheme 失败: $e');
      return 'howtocook://tip?error=1';
    }
  }
}
