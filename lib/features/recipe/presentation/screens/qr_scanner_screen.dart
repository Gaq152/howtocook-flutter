import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recipe.dart';
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
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false; // 防止重复处理

  @override
  void dispose() {
    _controller.dispose();
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
          MobileScanner(
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

  /// 处理条码检测
  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _processQRCode(code);
  }

  /// 从相册选择图片扫描
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      // 使用 mobile_scanner 分析图片中的二维码
      final BarcodeCapture? result = await _controller.analyzeImage(image.path);

      if (result == null || result.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未在图片中找到二维码'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final String? code = result.barcodes.first.rawValue;
      if (code == null || code.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法识别二维码内容'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      _processQRCode(code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: $e'),
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
      final Recipe? recipe = _parseQRCode(code);

      if (recipe == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('二维码格式不正确'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 跳转到预览页面
      if (mounted) {
        context.push('/recipe/preview', extra: recipe);
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
  Recipe _buildRecipeFromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['baseId'] as String? ?? '', // 原始 ID（如果有）
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
    );
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
