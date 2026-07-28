import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:archive/archive.dart';
import '../../domain/entities/recipe.dart';
import '../../presentation/widgets/recipe_share_card.dart';

final recipeShareServiceProvider = Provider<RecipeShareService>((ref) {
  return RecipeShareService();
});

/// 分享结果枚举
enum RecipeShareResult {
  success, // 成功
  cancelled, // 用户取消
  failed, // 失败
}

class RecipeQrPayload {
  final String data;
  final bool isComplete;
  final String note;

  const RecipeQrPayload({
    required this.data,
    required this.isComplete,
    required this.note,
  });
}

/// 菜谱分享服务
/// 提供两种分享方式:
/// 1. 纯文本分享(复制到剪贴板)
/// 2. 图片分享(生成菜谱卡片图片并分享,底部内嵌App专用二维码)
class RecipeShareService {
  /// 分享为纯文本(复制到剪贴板)
  ///
  /// 将菜谱格式化为美观的纯文本格式,并复制到剪贴板
  /// 包含: 菜谱名称、难度星级、食材列表、烹饪步骤、小贴士
  Future<RecipeShareResult> shareAsText(Recipe recipe) async {
    try {
      final text = formatRecipeText(recipe);
      await Share.share(text, subject: recipe.name);
      return RecipeShareResult.success;
    } catch (e) {
      debugPrint('分享文本失败: $e');
      return RecipeShareResult.failed;
    }
  }

  String formatRecipeText(Recipe recipe) {
    final buffer = StringBuffer();

    // 标题
    buffer.writeln('🍳【${recipe.name}】');
    buffer.writeln();

    // 难度
    final difficultyStars = '⭐' * recipe.difficulty;
    buffer.writeln('🔥 难度: $difficultyStars');
    buffer.writeln();

    // 分类
    buffer.writeln('📂 分类: ${recipe.categoryName}');
    if (recipe.estimatedCaloriesKcal != null) {
      buffer.writeln('🔥 估算总热量: ${recipe.estimatedCaloriesKcal} kcal');
    }
    buffer.writeln();

    if (recipe.description?.trim().isNotEmpty == true) {
      buffer.writeln('📖 菜谱简介:');
      buffer.writeln(recipe.description!.trim());
      buffer.writeln();
    }

    if (recipe.requirements.isNotEmpty || recipe.tools.isNotEmpty) {
      buffer.writeln('🧺 必备原料和工具:');
      for (final requirement in recipe.requirements) {
        buffer.writeln('• ${requirement.text}');
      }
      for (final tool in recipe.tools.where(
        (tool) => !recipe.requirements.any((item) => item.text == tool),
      )) {
        buffer.writeln('• $tool');
      }
      buffer.writeln();
    }

    buffer.writeln('🧮 用量与计算:');
    for (final note in recipe.calculationNotes) {
      buffer.writeln(note);
    }
    for (final ingredient in recipe.ingredients) {
      buffer.writeln('• ${ingredient.text}');
      if (ingredient.table.isNotEmpty) {
        buffer.writeln(
          '  ${ingredient.table.entries.map((e) => '${e.key}: ${e.value}').join(' | ')}',
        );
      }
    }
    buffer.writeln();

    buffer.writeln('👨‍🍳 操作:');
    for (final step in recipe.steps) {
      if (step.title?.isNotEmpty == true) buffer.writeln(step.title);
      buffer.writeln('• ${step.description}');
    }
    buffer.writeln();

    // 小贴士(如果有)
    if (recipe.tips != null && recipe.tips!.isNotEmpty) {
      buffer.writeln('💡 小贴士:');
      buffer.writeln(recipe.tips);
      buffer.writeln();
    }

    // 警告(如果有)
    if (recipe.warnings.isNotEmpty) {
      buffer.writeln('⚠️ 注意事项:');
      for (final warning in recipe.warnings) {
        buffer.writeln('• $warning');
      }
      buffer.writeln();
    }

    // 分享来源
    buffer.writeln('---');
    buffer.writeln('分享自「智能菜谱助手」');

    return buffer.toString();
  }

  /// 分享为图片
  ///
  /// 生成菜谱卡片图片（底部内嵌 App 专用二维码）
  /// [context] 必须是一个有效的 BuildContext，用于访问 Overlay
  /// [saveOnly] 为true时仅保存到相册,为false时打开系统分享面板
  Future<RecipeShareResult> shareAsImage(
    Recipe recipe,
    BuildContext context, {
    bool saveOnly = false,
  }) async {
    try {
      // 1. 生成二维码数据
      final qrPayload = generateQRPayload(recipe);
      debugPrint('🔄 开始生成分享图片（Overlay方案）...');

      // 2. 使用 Overlay + RepaintBoundary + toImage() 捕获完整长截图
      final Uint8List? imageBytes = await _captureWidgetAsImage(
        recipe: recipe,
        qrData: qrPayload.data,
        qrNote: qrPayload.note,
        context: context,
      );

      if (imageBytes == null) {
        debugPrint('❌ 生成图片失败: imageBytes is null');
        return RecipeShareResult.failed;
      }

      debugPrint('✅ 图片生成成功: ${imageBytes.length} 字节');

      // 4. 保存或分享
      if (saveOnly) {
        // 保存到相册（使用 gal 包）
        try {
          await Gal.putImageBytes(
            imageBytes,
            name:
                'recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}', // gal 会自动添加 .png
          );
          debugPrint('图片已保存到相册');
          return RecipeShareResult.success;
        } catch (e) {
          debugPrint('保存图片失败: $e');
          return RecipeShareResult.failed;
        }
      } else {
        // 分享到其他应用
        // 先保存到临时目录
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(imageBytes);

        // 使用 share_plus 分享
        final result = await Share.shareXFiles([
          XFile(file.path),
        ], text: '分享食谱：${recipe.name}');

        // 清理临时文件
        try {
          await file.delete();
        } catch (e) {
          debugPrint('清理临时文件失败: $e');
        }

        return result.status == ShareResultStatus.success
            ? RecipeShareResult.success
            : RecipeShareResult.cancelled;
      }
    } catch (e, stackTrace) {
      debugPrint('分享图片失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return RecipeShareResult.failed;
    }
  }

  /// 生成二维码数据（公共方法供外部调用）
  ///
  /// 返回包含菜谱完整信息的 Custom Scheme 格式数据
  /// 格式: howtocook://recipe?data=BASE64URL(GZIP(JSON))
  String generateQRData(Recipe recipe) {
    return generateQRPayload(recipe).data;
  }

  /// 生成菜谱卡片图片字节（公共方法供预览使用）
  ///
  /// 返回 PNG 格式的图片字节数据，如果生成失败返回 null
  /// [context] 必须是一个有效的 BuildContext，用于访问 Overlay
  Future<Uint8List?> generateRecipeImageBytes(
    Recipe recipe,
    BuildContext context,
  ) async {
    final qrPayload = generateQRPayload(recipe);
    return await _captureWidgetAsImage(
      recipe: recipe,
      qrData: qrPayload.data,
      qrNote: qrPayload.note,
      context: context,
    );
  }

  /// 生成 Custom Scheme 二维码数据（智能压缩策略）
  ///
  /// 根据食谱来源生成不同格式的二维码数据：
  /// - bundled: 只包含 ID 和基本信息（扫描后直接跳详情页）
  /// - userModified: 包含基础 ID + 改动字段（扫描后预览修改版）
  /// - userCreated/scanned/aiGenerated: 包含完整信息（扫描后预览）
  ///
  /// 使用短键命名以减小数据量：
  /// src=source, n=name, d=difficulty, c=category, i=ingredients, s=steps, t=tips
  ///
  /// 智能压缩策略（基于数据大小）：
  /// - 小数据（<1000字节）：不压缩，使用 Base64URL（避免压缩开销）
  /// - 大数据（≥1000字节）：GZIP + Base64URL（减小二维码复杂度）
  ///
  /// 注意：增加 800ms 渲染延迟可彻底解决二维码乱码问题
  static const int maxReliableQrCharacters = 2400;

  RecipeQrPayload generateQRPayload(Recipe recipe) {
    try {
      if (recipe.source == RecipeSource.bundled ||
          recipe.source == RecipeSource.cloud) {
        return RecipeQrPayload(
          data:
              'howtocook://recipe?v=2&ref=${Uri.encodeQueryComponent(recipe.id)}',
          isComplete: true,
          note: '扫码打开完整云端菜谱',
        );
      }

      final fullScheme = _encodeQrPayload(_buildV2Payload(recipe));
      if (fullScheme.length <= maxReliableQrCharacters) {
        return RecipeQrPayload(
          data: fullScheme,
          isComplete: true,
          note: '扫码导入完整 V2 菜谱',
        );
      }

      if (recipe.source == RecipeSource.userModified) {
        return RecipeQrPayload(
          data:
              'howtocook://recipe?v=2&ref=${Uri.encodeQueryComponent(recipe.id)}',
          isComplete: false,
          note: '内容过长，二维码打开原菜谱；修改内容以分享图为准',
        );
      }

      var summaryScheme = _encodeQrPayload(_buildSummaryPayload(recipe));
      if (summaryScheme.length > maxReliableQrCharacters) {
        summaryScheme = _encodeQrPayload({
          'v': 2,
          'src': 'p',
          'p': true,
          'id': recipe.id,
          'n': _truncate(recipe.name, 80),
          'c': recipe.category,
          'cn': _truncate(recipe.categoryName, 30),
          'd': recipe.difficulty,
          if (recipe.estimatedCaloriesKcal != null)
            'k': recipe.estimatedCaloriesKcal,
          'w': const ['二维码仅含基础摘要，完整内容以分享图/文本为准。'],
        });
      }
      return RecipeQrPayload(
        data: summaryScheme,
        isComplete: false,
        note: '内容过长，二维码仅含摘要；完整内容以分享图/文本为准',
      );
    } catch (e) {
      debugPrint('生成 Custom Scheme 失败: $e');
      return RecipeQrPayload(
        data: _fallbackScheme(recipe),
        isComplete: false,
        note: '二维码仅含基础摘要',
      );
    }
  }

  Map<String, dynamic> _buildV2Payload(Recipe recipe) => {
    'v': 2,
    'src': recipe.source == RecipeSource.aiGenerated
        ? 'a'
        : recipe.source == RecipeSource.userModified
        ? 'm'
        : 'u',
    'id': recipe.id,
    'n': recipe.name,
    if (recipe.description?.isNotEmpty == true) 'ds': recipe.description,
    'd': recipe.difficulty,
    'c': recipe.category,
    'cn': recipe.categoryName,
    if (recipe.estimatedCaloriesKcal != null) 'k': recipe.estimatedCaloriesKcal,
    if (recipe.requirements.isNotEmpty)
      'r': recipe.requirements
          .map(
            (item) => item.kind == 'unknown' && item.group == null
                ? item.text
                : {
                    't': item.text,
                    if (item.kind != 'unknown') 'k': item.kind,
                    if (item.group != null) 'g': item.group,
                  },
          )
          .toList(),
    'i': recipe.ingredients
        .map(
          (item) => !item.optional && item.source == null && item.table.isEmpty
              ? item.text
              : {
                  'n': item.name,
                  't': item.text,
                  if (item.optional) 'o': true,
                  if (item.source != null) 'x': item.source,
                  if (item.table.isNotEmpty) 'b': item.table,
                },
        )
        .toList(),
    if (recipe.tools.isNotEmpty) 'tl': recipe.tools,
    if (recipe.calculationNotes.isNotEmpty) 'cl': recipe.calculationNotes,
    's': recipe.steps
        .map(
          (step) => step.kind == 'step' && step.title == null
              ? step.description
              : {
                  'k': step.kind,
                  if (step.title != null) 't': step.title,
                  'd': step.description,
                },
        )
        .toList(),
    if (recipe.tips?.isNotEmpty == true) 't': recipe.tips,
    if (recipe.warnings.isNotEmpty) 'w': recipe.warnings,
  };

  Map<String, dynamic> _buildSummaryPayload(Recipe recipe) => {
    'v': 2,
    'src': 'p',
    'p': true,
    'id': recipe.id,
    'n': _truncate(recipe.name, 80),
    if (recipe.description?.isNotEmpty == true)
      'ds': _truncate(recipe.description!, 80),
    'd': recipe.difficulty,
    'c': recipe.category,
    'cn': recipe.categoryName,
    if (recipe.estimatedCaloriesKcal != null) 'k': recipe.estimatedCaloriesKcal,
    'r': recipe.requirements
        .take(5)
        .map((item) => _truncate(item.text, 40))
        .toList(),
    'i': recipe.ingredients
        .take(6)
        .map((item) => _truncate(item.text, 60))
        .toList(),
    's': recipe.steps
        .take(2)
        .map((step) => _truncate(step.description, 100))
        .toList(),
    'w': const ['该菜谱的二维码只包含摘要，完整内容请查看分享图或分享文本。'],
  };

  String _truncate(String value, int maxLength) =>
      value.length <= maxLength ? value : '${value.substring(0, maxLength)}…';

  String _encodeQrPayload(Map<String, dynamic> payload) {
    final rawBytes = utf8.encode(jsonEncode(payload));
    final gzipBytes = GZipEncoder().encode(rawBytes);
    if (gzipBytes != null && gzipBytes.length < rawBytes.length) {
      return 'howtocook://recipe?data=${base64Url.encode(gzipBytes).replaceAll('=', '')}';
    }
    return 'howtocook://recipe?raw=${base64Url.encode(rawBytes).replaceAll('=', '')}';
  }

  /// 使用 Overlay + RepaintBoundary 捕获 Widget 为图片（真正的长截图）
  ///
  /// 此方法在真实渲染树中渲染 widget（通过 Overlay），避免离屏渲染的复杂性
  /// [context] 必须是一个有效的 BuildContext
  Future<Uint8List?> _captureWidgetAsImage({
    required Recipe recipe,
    required String qrData,
    required String qrNote,
    required BuildContext context,
  }) async {
    try {
      // 创建 GlobalKey 用于获取 RepaintBoundary
      final GlobalKey repaintBoundaryKey = GlobalKey();
      OverlayEntry? overlayEntry;

      // 创建 Overlay Widget（在屏幕外渲染，用户不可见）
      overlayEntry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          left: -10000, // 放在屏幕外，用户看不到
          top: 0,
          child: RepaintBoundary(
            key: repaintBoundaryKey,
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
                  child: Material(
                    color: Colors.transparent,
                    child: RecipeShareCard(
                      recipe: recipe,
                      qrData: qrData,
                      qrNote: qrNote,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 延迟到下一帧再插入 Overlay，避免在 build 阶段调用 markNeedsBuild
      final overlayState = Overlay.of(context, rootOverlay: true);
      await Future.delayed(Duration.zero);
      overlayState.insert(overlayEntry);

      // 等待渲染完成（包括二维码）
      await Future.delayed(const Duration(milliseconds: 1000));

      // 获取 RenderRepaintBoundary
      final RenderObject? renderObject = repaintBoundaryKey.currentContext
          ?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint(
          '❌ 无法获取 RenderRepaintBoundary，类型: ${renderObject.runtimeType}',
        );
        overlayEntry.remove();
        return null;
      }

      final size = renderObject.size;
      debugPrint('📐 渲染尺寸: ${size.width} x ${size.height}');

      // 转换为图片
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // 移除 Overlay
      overlayEntry.remove();

      if (byteData == null) {
        debugPrint('❌ 无法转换图片为字节数据');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      debugPrint(
        '✅ Overlay截图成功: ${bytes.length} 字节, 图片尺寸: ${image.width}x${image.height}',
      );

      return bytes;
    } catch (e, stackTrace) {
      debugPrint('❌ Overlay截图失败: $e');
      debugPrint('堆栈: $stackTrace');
      return null;
    }
  }

  /// 降级方案：简化版 JSON（不压缩）
  String _fallbackScheme(Recipe recipe) {
    final payload = {
      'n': recipe.name,
      'd': recipe.difficulty,
      'i': recipe.ingredients.take(3).map((i) => i.text).toList(),
      's': recipe.steps.take(3).map((s) => s.description).toList(),
    };
    final jsonString = jsonEncode(payload);
    return 'howtocook://recipe?json=${Uri.encodeComponent(jsonString)}';
  }
}
