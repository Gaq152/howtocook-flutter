import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:archive/archive.dart';
import '../../domain/entities/recipe.dart';
import '../../presentation/widgets/recipe_share_card.dart';

/// 菜谱分享服务
/// 提供三种分享方式:
/// 1. 纯文本分享(复制到剪贴板)
/// 2. 图片分享(生成菜谱卡片图片并分享)
/// 3. 二维码分享(生成包含菜谱信息的二维码)
class RecipeShareService {
  /// 分享结果枚举
  enum ShareResult {
    success,      // 成功
    cancelled,    // 用户取消
    failed,       // 失败
  }

  /// 分享为纯文本(复制到剪贴板)
  ///
  /// 将菜谱格式化为美观的纯文本格式,并复制到剪贴板
  /// 包含: 菜谱名称、难度星级、食材列表、烹饪步骤、小贴士
  Future<ShareResult> shareAsText(Recipe recipe) async {
    try {
      final text = _formatRecipeText(recipe);
      await Clipboard.setData(ClipboardData(text: text));
      return ShareResult.success;
    } catch (e) {
      debugPrint('分享文本失败: $e');
      return ShareResult.failed;
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
  /// [saveOnly] 为true时仅保存到相册,为false时打开系统分享面板
  Future<ShareResult> shareAsImage(
    Recipe recipe, {
    bool saveOnly = false,
  }) async {
    try {
      // 1. 生成二维码数据（Custom Scheme with GZIP）
      final qrData = _generateCustomScheme(recipe);

      // 2. 创建截图控制器
      final screenshotController = ScreenshotController();

      // 3. 使用 screenshot 包捕获 Widget 为图片
      final Uint8List? imageBytes = await screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: RecipeShareCard(
              recipe: recipe,
              qrData: qrData,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: null,
      );

      if (imageBytes == null) {
        debugPrint('生成图片失败: imageBytes is null');
        return ShareResult.failed;
      }

      // 4. 保存或分享
      if (saveOnly) {
        // 保存到相册
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 95,
          name: 'recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (result['isSuccess'] == true) {
          debugPrint('图片已保存到相册: ${result['filePath']}');
          return ShareResult.success;
        } else {
          debugPrint('保存图片失败');
          return ShareResult.failed;
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
            ? ShareResult.success
            : ShareResult.cancelled;
      }
    } catch (e, stackTrace) {
      debugPrint('分享图片失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return ShareResult.failed;
    }
  }

  /// 分享为二维码
  ///
  /// 生成包含菜谱完整信息的二维码
  /// 扫描后能查看完整菜谱
  Future<ShareResult> shareAsQRCode(Recipe recipe) async {
    // TODO: 实现二维码分享功能
    // 1. 将菜谱数据编码为JSON
    // 2. 使用 qr_flutter 生成二维码
    // 3. 显示二维码或保存图片
    debugPrint('二维码分享功能待实现');
    return ShareResult.failed;
  }

  /// 将菜谱编码为二维码数据
  ///
  /// 只保留核心信息以减小数据量
  String _encodeRecipeForQR(Recipe recipe) {
    final data = {
      'type': 'recipe',
      'version': '1.0',
      'data': {
        'id': recipe.id,
        'name': recipe.name,
        'category': recipe.category,
        'categoryName': recipe.categoryName,
        'difficulty': recipe.difficulty,
        'ingredients': recipe.ingredients.map((i) => i.text).toList(),
        'steps': recipe.steps.map((s) => s.description).toList(),
        'tips': recipe.tips,
      },
    };

    return jsonEncode(data);
  }
}
