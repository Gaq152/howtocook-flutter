import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:archive/archive.dart';
import '../../domain/entities/recipe.dart';
import '../../presentation/widgets/recipe_share_card.dart';

/// 分享结果枚举
enum RecipeShareResult {
  success,      // 成功
  cancelled,    // 用户取消
  failed,       // 失败
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
      final text = _formatRecipeText(recipe);
      await Clipboard.setData(ClipboardData(text: text));
      return RecipeShareResult.success;
    } catch (e) {
      debugPrint('分享文本失败: $e');
      return RecipeShareResult.failed;
    }
  }

  /// 格式化菜谱为纯文本
  String _formatRecipeText(Recipe recipe) {
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
    buffer.writeln();

    // 食材
    buffer.writeln('📝 食材:');
    for (final ingredient in recipe.ingredients) {
      buffer.writeln('• ${ingredient.text}');
    }
    buffer.writeln();

    // 工具(如果有)
    if (recipe.tools.isNotEmpty) {
      buffer.writeln('🔧 所需工具:');
      for (final tool in recipe.tools) {
        buffer.writeln('• $tool');
      }
      buffer.writeln();
    }

    // 步骤
    buffer.writeln('👨‍🍳 制作步骤:');
    for (int i = 0; i < recipe.steps.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.steps[i].description}');
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
      final qrData = _generateCustomScheme(recipe);
      debugPrint('🔄 开始生成分享图片（Overlay方案）...');

      // 2. 使用 Overlay + RepaintBoundary + toImage() 捕获完整长截图
      final Uint8List? imageBytes = await _captureWidgetAsImage(
        recipe: recipe,
        qrData: qrData,
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
            name: 'recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}', // gal 会自动添加 .png
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
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          text: '分享食谱：${recipe.name}',
        );

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
    return _generateCustomScheme(recipe);
  }

  /// 生成菜谱卡片图片字节（公共方法供预览使用）
  ///
  /// 返回 PNG 格式的图片字节数据，如果生成失败返回 null
  /// [context] 必须是一个有效的 BuildContext，用于访问 Overlay
  Future<Uint8List?> generateRecipeImageBytes(
    Recipe recipe,
    BuildContext context,
  ) async {
    final qrData = _generateCustomScheme(recipe);
    return await _captureWidgetAsImage(
      recipe: recipe,
      qrData: qrData,
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
  String _generateCustomScheme(Recipe recipe) {
    try {
      // 1. 根据食谱来源构建不同格式的 JSON 数据
      final Map<String, dynamic> payload;

      switch (recipe.source) {
        case RecipeSource.bundled:
          // 内置食谱：只包含 ID 和基本信息
          payload = {
            'src': 'b',  // bundled
            'id': recipe.id,
            'n': recipe.name,  // 用于显示
            if (recipe.hash.isNotEmpty) 'hash': recipe.hash,
          };
          debugPrint('📦 生成内置食谱二维码: ${recipe.name}');
          break;

        case RecipeSource.userModified:
          // 修改的内置食谱：包含基础 ID + 所有字段（简化处理，不做 diff）
          // TODO: 未来可以优化为只传递改动字段
          payload = {
            'src': 'm',  // modified
            'id': recipe.id,
            'n': recipe.name,
            'd': recipe.difficulty,
            'c': recipe.category,
            'cn': recipe.categoryName,
            'i': recipe.ingredients.map((ing) => ing.text).toList(),
            's': recipe.steps.map((step) => step.description).toList(),
            if (recipe.tips != null && recipe.tips!.isNotEmpty) 't': recipe.tips,
            if (recipe.warnings.isNotEmpty) 'w': recipe.warnings,
            if (recipe.hash.isNotEmpty) 'hash': recipe.hash,
          };
          debugPrint('✏️  生成修改版食谱二维码: ${recipe.name}');
          break;

        case RecipeSource.userCreated:
          // 用户创建：完整信息
          payload = {
            'src': 'u',  // user
            'id': recipe.id,
            'n': recipe.name,
            'd': recipe.difficulty,
            'c': recipe.category,
            'cn': recipe.categoryName,
            'i': recipe.ingredients.map((ing) => ing.text).toList(),
            's': recipe.steps.map((step) => step.description).toList(),
            if (recipe.tips != null && recipe.tips!.isNotEmpty) 't': recipe.tips,
            if (recipe.warnings.isNotEmpty) 'w': recipe.warnings,
            if (recipe.hash.isNotEmpty) 'hash': recipe.hash,
          };
          debugPrint('👤 生成用户创建食谱二维码: ${recipe.name}');
          break;

        case RecipeSource.aiGenerated:
          // AI 生成：完整信息
          payload = {
            'src': 'a',  // ai
            'id': recipe.id,
            'n': recipe.name,
            'd': recipe.difficulty,
            'c': recipe.category,
            'cn': recipe.categoryName,
            'i': recipe.ingredients.map((ing) => ing.text).toList(),
            's': recipe.steps.map((step) => step.description).toList(),
            if (recipe.tips != null && recipe.tips!.isNotEmpty) 't': recipe.tips,
            if (recipe.warnings.isNotEmpty) 'w': recipe.warnings,
            if (recipe.hash.isNotEmpty) 'hash': recipe.hash,
          };
          debugPrint('🤖 生成 AI 创建食谱二维码: ${recipe.name}');
          break;

        case RecipeSource.scanned:
        case RecipeSource.cloud:
          // 扫码导入/云端下载：完整信息（兼容旧版，默认当作用户创建处理）
          payload = {
            'src': 'u',  // 默认当作用户创建
            'id': recipe.id,
            'n': recipe.name,
            'd': recipe.difficulty,
            'c': recipe.category,
            'cn': recipe.categoryName,
            'i': recipe.ingredients.map((ing) => ing.text).toList(),
            's': recipe.steps.map((step) => step.description).toList(),
            if (recipe.tips != null && recipe.tips!.isNotEmpty) 't': recipe.tips,
            if (recipe.warnings.isNotEmpty) 'w': recipe.warnings,
            if (recipe.hash.isNotEmpty) 'hash': recipe.hash,
          };
          debugPrint('📥 生成扫码/云端食谱二维码: ${recipe.name}');
      }

      // 2. 转为 JSON 字符串
      final jsonString = jsonEncode(payload);
      final utf8Bytes = utf8.encode(jsonString);

      // 3. 智能选择压缩策略（提高阈值到 1000 字节）
      if (utf8Bytes.length < 1000) {
        // 小数据：不压缩，直接 Base64URL 编码
        final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
        final scheme = 'howtocook://recipe?raw=$base64String';

        debugPrint('📦 二维码数据（未压缩）: ${scheme.length} 字节 (JSON: ${utf8Bytes.length} 字节)');
        return scheme;
      } else {
        // 大数据：GZIP 压缩后 Base64URL 编码
        final gzipBytes = GZipEncoder().encode(utf8Bytes);

        if (gzipBytes == null || gzipBytes.length >= utf8Bytes.length * 0.9) {
          // 压缩效果不明显（节省<10%），使用未压缩
          final base64String = base64Url.encode(utf8Bytes).replaceAll('=', '');
          final scheme = 'howtocook://recipe?raw=$base64String';

          debugPrint('⚠️  GZIP 压缩效果不佳，使用未压缩: ${scheme.length} 字节');
          return scheme;
        }

        final base64String = base64Url.encode(gzipBytes).replaceAll('=', '');
        final scheme = 'howtocook://recipe?data=$base64String';

        debugPrint('📦 二维码数据（GZIP 压缩）: ${scheme.length} 字节');
        debugPrint('   压缩前: ${utf8Bytes.length} 字节 → 压缩后: ${gzipBytes.length} 字节 (节省 ${((1 - gzipBytes.length / utf8Bytes.length) * 100).toStringAsFixed(1)}%)');

        return scheme;
      }
    } catch (e) {
      debugPrint('生成 Custom Scheme 失败: $e');
      return _fallbackScheme(recipe);
    }
  }

  /// 使用 Overlay + RepaintBoundary 捕获 Widget 为图片（真正的长截图）
  ///
  /// 此方法在真实渲染树中渲染 widget（通过 Overlay），避免离屏渲染的复杂性
  /// [context] 必须是一个有效的 BuildContext
  Future<Uint8List?> _captureWidgetAsImage({
    required Recipe recipe,
    required String qrData,
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
                  child: RecipeShareCard(
                    recipe: recipe,
                    qrData: qrData,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 插入到 Overlay（使用传入的 context）
      Overlay.of(context, rootOverlay: true).insert(overlayEntry);

      // 等待渲染完成（包括二维码）
      await Future.delayed(const Duration(milliseconds: 1000));

      // 获取 RenderRepaintBoundary
      final RenderObject? renderObject =
          repaintBoundaryKey.currentContext?.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('❌ 无法获取 RenderRepaintBoundary，类型: ${renderObject.runtimeType}');
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
      debugPrint('✅ Overlay截图成功: ${bytes.length} 字节, 图片尺寸: ${image.width}x${image.height}');

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
