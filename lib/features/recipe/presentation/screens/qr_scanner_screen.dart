import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile;
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/recipe.dart';
import '../../infrastructure/services/wechat_qr_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 二维码扫描页面
///
/// 支持相机实时扫描和从相册选择图片扫描
/// 扫描成功后解析菜谱数据并跳转到预览页面
class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final mobile.MobileScannerController _controller = mobile.MobileScannerController(
    detectionSpeed: mobile.DetectionSpeed.normal,
    facing: mobile.CameraFacing.back,
  );

  final WeChatQRScanner _wechatScanner = WeChatQRScanner();
  bool _isProcessing = false; // 防止重复处理

  @override
  void dispose() {
    _controller.dispose();
    _wechatScanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: () => _controller.toggleTorch(),
            tooltip: '手电筒',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
            tooltip: '切换相机',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 相机扫描区域
          mobile.MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetect,
          ),

          // 扫描框遮罩
          _buildScanMask(),

          // 提示文字
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Text(
              '将二维码放入框内',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                shadows: [
                  const Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),

          // 底部相册按钮
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('从相册选择'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建扫描框遮罩
  Widget _buildScanMask() {
    const double scanAreaSize = 250.0;

    return CustomPaint(
      painter: _ScanMaskPainter(scanAreaSize: scanAreaSize),
      child: const SizedBox.expand(),
    );
  }

  /// 处理条码检测（相机实时扫描 - 使用 WeChatQRCode）
  Future<void> _onBarcodeDetect(mobile.BarcodeCapture capture) async {
    if (_isProcessing) return;

    // 获取图像数据
    final image = capture.image;
    if (image == null) {
      debugPrint('⚠️  相机帧无图像数据');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('📸 捕获相机帧...');

      // 1. 将相机帧保存为临时文件
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/camera_frame_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);

      // 写入图像字节
      await tempFile.writeAsBytes(image);
      debugPrint('✅ 相机帧已保存: $tempPath (${image.length} 字节)');

      // 2. 初始化扫描器（首次调用）
      await _wechatScanner.initialize();

      // 3. 使用 WeChatQRCode 扫描
      final results = await _wechatScanner.detectAndDecode(tempPath);

      // 4. 清理临时文件
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('清理临时文件失败: $e');
      }

      // 5. 处理结果
      if (results.isNotEmpty) {
        final code = results.first;
        debugPrint('✅ 相机实时扫描成功！二维码长度: ${code.length} 字符');
        _processQRCode(code);
      } else {
        // 未找到二维码，重置状态继续扫描
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 相机实时扫描失败: $e');
      debugPrint('堆栈: $stackTrace');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 从相册选择图片扫描（使用 WeChat QRCode 强力扫描）
  Future<void> _pickImageFromGallery() async {
    try {
      debugPrint('🔍 开始从相册选择图片...');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        debugPrint('❌ 用户取消选择图片');
        return;
      }

      debugPrint('✅ 图片已选择: ${image.path}');

      // 使用 WeChat QRCode 扫描器（强力 CNN 模型）
      debugPrint('🚀 使用 WeChatQRCode 扫描器...');

      // 初始化扫描器（首次调用会加载模型）
      await _wechatScanner.initialize();

      // 扫描图片
      final results = await _wechatScanner.detectAndDecode(image.path);

      if (results.isEmpty) {
        debugPrint('❌ WeChatQRCode 未找到二维码');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未在图片中找到二维码\n请确保图片清晰且二维码完整'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 找到了！使用第一个结果
      final code = results.first;
      debugPrint('✅ WeChatQRCode 扫描成功！二维码长度: ${code.length} 字符');
      _processQRCode(code);
    } catch (e, stackTrace) {
      debugPrint('❌ WeChatQRCode 扫描失败: $e');
      debugPrint('堆栈: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描图片失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 处理二维码内容
  void _processQRCode(String code) {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 解析二维码数据
      final parseResult = _parseQRCode(code);

      // 检查是否是内置食谱（已经直接跳转）
      if (parseResult == null) {
        // 内置食谱已经在 _buildRecipeFromJson 中跳转，重置状态并返回
        debugPrint('✅ 内置食谱跳转完成');
        // 延迟重置状态，确保跳转动画完成
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });
        return;
      }

      final recipe = parseResult;

      // 跳转到预览页面（其他类型的食谱）
      if (mounted) {
        debugPrint('🚀 准备跳转到预览页面...');
        debugPrint('  - Recipe ID: ${recipe.id}');
        debugPrint('  - Recipe Name: ${recipe.name}');
        debugPrint('  - mounted: $mounted');
        debugPrint('  - context: ${context.toString()}');

        try {
          // 使用 push 代替 go，保留返回按钮
          context.push('/recipe-preview', extra: recipe);
          debugPrint('✅ context.push 调用成功');

          // 延迟重置状态，确保跳转动画完成
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
            }
            debugPrint('⏰ 500ms 后重置：_isProcessing = false');
          });
        } catch (e, stackTrace) {
          debugPrint('❌ 跳转失败: $e');
          debugPrint('堆栈: $stackTrace');

          // 显示错误对话框
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('跳转失败'),
                content: Text('错误: $e\n\n堆栈:\n$stackTrace'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        debugPrint('❌ 无法跳转：widget 已卸载 (mounted=false)');
      }
    } catch (e) {
      debugPrint('解析二维码失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解析失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 解析二维码数据为 Recipe 对象
  ///
  /// 支持三种格式：
  /// 1. Raw Scheme: howtocook://recipe?raw=BASE64URL(JSON) - 未压缩格式
  /// 2. Compressed Scheme: howtocook://recipe?data=BASE64URL(GZIP(JSON)) - 压缩格式
  /// 3. Fallback Scheme: howtocook://recipe?json=URL_ENCODED_JSON - 降级格式
  Recipe? _parseQRCode(String code) {
    try {
      final uri = Uri.parse(code);

      // 检查协议和路径
      if (uri.scheme != 'howtocook' || uri.host != 'recipe') {
        debugPrint('不是有效的 howtocook 协议');
        return null;
      }

      // 优先处理未压缩 Base64URL 格式
      if (uri.queryParameters.containsKey('raw')) {
        return _parseRawData(uri.queryParameters['raw']!);
      }

      // 处理 GZIP 压缩格式
      if (uri.queryParameters.containsKey('data')) {
        return _parseCompressedData(uri.queryParameters['data']!);
      }

      // 处理降级格式（URL 编码 JSON）
      if (uri.queryParameters.containsKey('json')) {
        return _parseFallbackData(uri.queryParameters['json']!);
      }

      debugPrint('二维码缺少数据参数');
      return null;
    } catch (e) {
      debugPrint('解析二维码 URI 失败: $e');
      return null;
    }
  }

  /// 解析未压缩 Base64URL 数据
  Recipe? _parseRawData(String base64Data) {
    try {
      // 1. Base64URL 解码（补齐 padding）
      String paddedBase64 = base64Data;
      while (paddedBase64.length % 4 != 0) {
        paddedBase64 += '=';
      }
      final utf8Bytes = base64Url.decode(paddedBase64);

      // 2. UTF-8 解码为 JSON 字符串
      final jsonString = utf8.decode(utf8Bytes);

      // 3. JSON 解析
      final Map<String, dynamic> json = jsonDecode(jsonString);

      debugPrint('✅ 解析未压缩数据成功: ${utf8Bytes.length} 字节');
      return _buildRecipeFromJson(json);
    } catch (e) {
      debugPrint('解析未压缩数据失败: $e');
      return null;
    }
  }

  /// 解析 GZIP 压缩数据
  Recipe? _parseCompressedData(String base64Data) {
    try {
      // 1. Base64URL 解码（补齐 padding）
      String paddedBase64 = base64Data;
      while (paddedBase64.length % 4 != 0) {
        paddedBase64 += '=';
      }
      final gzipBytes = base64Url.decode(paddedBase64);

      // 2. GZIP 解压缩
      final utf8Bytes = GZipDecoder().decodeBytes(gzipBytes);

      // 3. UTF-8 解码
      final jsonString = utf8.decode(utf8Bytes);

      // 4. JSON 解析
      final Map<String, dynamic> json = jsonDecode(jsonString);

      debugPrint('✅ 解析压缩数据成功: ${gzipBytes.length} → ${utf8Bytes.length} 字节');
      return _buildRecipeFromJson(json);
    } catch (e) {
      debugPrint('解析压缩数据失败: $e');
      return null;
    }
  }

  /// 解析降级格式数据（未压缩 JSON）
  Recipe? _parseFallbackData(String encodedJson) {
    try {
      final jsonString = Uri.decodeComponent(encodedJson);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return _buildRecipeFromJson(json);
    } catch (e) {
      debugPrint('解析降级数据失败: $e');
      return null;
    }
  }

  /// 从 JSON 构建 Recipe 对象
  ///
  /// 根据 'src' 字段决定处理方式：
  /// - 'b' (bundled): 内置食谱，直接跳转详情页
  /// - 'm' (modified): 修改的内置食谱，显示预览页
  /// - 'u' (user): 用户创建食谱，显示预览页
  /// - 'a' (ai): AI 生成食谱，显示预览页
  Recipe? _buildRecipeFromJson(Map<String, dynamic> json) {
    debugPrint('📋 开始构建 Recipe 对象...');
    debugPrint('JSON keys: ${json.keys.toList()}');

    // 1. 读取来源类型标记
    final String? sourceType = json['src'] as String?;
    debugPrint('📦 食谱来源类型: $sourceType');

    // 2. 处理内置食谱（直接跳转到详情页，不显示预览页）
    if (sourceType == 'b') {
      debugPrint('🔄 内置食谱：准备跳转到详情页');
      final recipeId = json['id'] as String?;

      if (recipeId == null || recipeId.isEmpty) {
        debugPrint('❌ 内置食谱缺少 ID');
        return null;
      }

      // 直接跳转到详情页（使用 push 保留返回按钮）
      if (mounted) {
        debugPrint('🚀 跳转到内置食谱详情页: $recipeId');
        context.push('/recipe/$recipeId');
      }
      return null;
    }

    // 3. 处理其他类型（需要显示预览页）
    // 优先使用新格式的 'id' 字段，兼容旧格式的 'baseId'
    final rawId = json['id'] as String? ?? json['baseId'] as String? ?? '';
    final recipeId = rawId.isNotEmpty
        ? rawId
        : 'preview_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('🆔 原始 ID: $rawId');
    debugPrint('🆔 最终 ID: $recipeId');

    // 4. 确定食谱来源
    RecipeSource recipeSource;
    switch (sourceType) {
      case 'm':
        recipeSource = RecipeSource.userModified;
        debugPrint('✏️  修改的内置食谱');
        break;
      case 'u':
        recipeSource = RecipeSource.userCreated;
        debugPrint('👤 用户创建食谱');
        break;
      case 'a':
        recipeSource = RecipeSource.aiGenerated;
        debugPrint('🤖 AI 生成食谱');
        break;
      default:
        // 兼容旧版本（没有 src 字段）
        recipeSource = RecipeSource.scanned;
        debugPrint('📥 默认：扫码导入食谱');
    }

    // 5. 构建 Recipe 对象
    final recipe = Recipe(
      id: recipeId,
      name: json['n'] as String,
      category: json['c'] as String,
      categoryName: json['cn'] as String,
      difficulty: json['d'] as int,
      ingredients: (json['i'] as List<dynamic>).map((text) {
        final textStr = text as String;
        // 从字符串提取食材名称（第一个空格前的部分）
        final firstSpaceIndex = textStr.indexOf(' ');
        final name = firstSpaceIndex > 0 ? textStr.substring(0, firstSpaceIndex) : textStr;
        return Ingredient(name: name, text: textStr);
      }).toList(),
      steps: (json['s'] as List<dynamic>)
          .map((desc) => CookingStep(description: desc as String))
          .toList(),
      tips: json['t'] as String?,
      warnings: json['w'] != null
          ? List<String>.from(json['w'] as List<dynamic>)
          : [],
      tools: [], // 二维码中不包含工具列表
      images: [], // 二维码中不包含图片
      hash: json['hash'] as String? ?? '', // 用于版本追踪（默认空字符串）
      source: recipeSource,
    );

    debugPrint('✅ Recipe 构建完成:');
    debugPrint('  - ID: ${recipe.id}');
    debugPrint('  - Name: ${recipe.name}');
    debugPrint('  - Source: ${recipe.source}');
    debugPrint('  - Category: ${recipe.category}');
    debugPrint('  - CategoryName: ${recipe.categoryName}');

    return recipe;
  }

}

/// 扫描框遮罩绘制器
class _ScanMaskPainter extends CustomPainter {
  final double scanAreaSize;

  _ScanMaskPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // 绘制半透明背景
    final Paint maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final Path maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(maskPath, maskPaint);

    // 绘制扫描框边角
    final Paint cornerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const double cornerLength = 20;

    // 左上角
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // 右上角
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top),
        Offset(left + scanAreaSize, top + cornerLength), cornerPaint);

    // 左下角
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left + cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize),
        Offset(left, top + scanAreaSize - cornerLength), cornerPaint);

    // 右下角
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize),
        Offset(left + scanAreaSize - cornerLength, top + scanAreaSize), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize),
        Offset(left + scanAreaSize, top + scanAreaSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
