import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile;
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/recipe.dart';
import '../../application/providers/recipe_providers.dart';
import '../../infrastructure/services/wechat_qr_scanner.dart';

import '../../../tips/application/providers/tip_providers.dart';

import '../../../tips/domain/entities/tip.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/widgets/app_snack_bar.dart';

import '../../../../core/theme/app_text_styles.dart';

/// 二维码扫描页面

///

/// 支持相机实时扫描和从相册选择图片扫描

/// 扫描成功后解析菜谱数据并跳转到预览页面。

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final mobile.MobileScannerController _controller =
      mobile.MobileScannerController(
        detectionSpeed: mobile.DetectionSpeed.normal,
        facing: mobile.CameraFacing.back,
        returnImage: true,
      );

  final WeChatQRScanner _wechatScanner = WeChatQRScanner();
  final GlobalKey _cameraKey = GlobalKey();
  bool _isProcessing = false;
  bool _isWechatDecoding = false;
  DateTime? _lastWechatAttempt;
  Timer? _periodicScanTimer;
  Timer? _hintTimer;
  String _scanStatus = '';
  int _scanAttempts = 0;

  @override
  void initState() {
    super.initState();
    _wechatScanner.initialize().catchError((e) {
      debugPrint('WeChatQRCode init failed: $e');
      if (mounted) setState(() => _scanStatus = '增强识别引擎加载失败');
    });
    _periodicScanTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
      (_) => _periodicWeChatScan(),
    );
    // 6 秒后如果还没扫到，显示提示（备用）
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_isProcessing && _scanStatus.isEmpty) {
        setState(() => _scanStatus = '未识别到二维码，请调整距离或角度');
      }
    });
  }

  @override
  void dispose() {
    _periodicScanTimer?.cancel();
    _hintTimer?.cancel();
    _controller.dispose();
    _wechatScanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描二维码'),

        backgroundColor: AppColors.textPrimary,

        foregroundColor: AppColors.surface,

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

      backgroundColor: AppColors.textPrimary,

      body: Stack(
        children: [
          // 相机扫描区域
          RepaintBoundary(
            key: _cameraKey,
            child: mobile.MobileScanner(
              controller: _controller,
              onDetect: _onBarcodeDetect,
            ),
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
                color: AppColors.surface,

                shadows: [
                  const Shadow(
                    offset: Offset(0, 1),

                    blurRadius: 4,

                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),

          // 扫描状态提示
          if (_scanStatus.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _scanStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
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
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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

  /// 处理条码检测：MLKit 定位到二维码但解不出内容时，交给 WeChatQRCode 解码
  Future<void> _onBarcodeDetect(mobile.BarcodeCapture capture) async {
    if (_isProcessing) return;

    // MLKit 成功解码，直接用
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue ?? barcode.displayValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _processQRCode(rawValue);
        return;
      }
    }

    // MLKit 定位到二维码但解不出内容（高密度码）→ WeChatQRCode 兜底
    if (mounted && _scanStatus != '已定位到二维码，正在解析...') {
      setState(() => _scanStatus = '已定位到二维码，正在解析...');
    }
    // 降频：每 800ms 最多触发一次
    if (_isWechatDecoding) return;
    final now = DateTime.now();
    if (_lastWechatAttempt != null &&
        now.difference(_lastWechatAttempt!).inMilliseconds < 800) {
      return;
    }
    final image = capture.image;
    if (image == null || capture.barcodes.isEmpty) return;

    _isWechatDecoding = true;
    _lastWechatAttempt = now;
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/qr_frame_${now.millisecondsSinceEpoch}.jpg';
      tempFile = File(tempPath);
      await tempFile.writeAsBytes(image);
      final results = await _wechatScanner.detectAndDecode(tempPath);
      if (results.isNotEmpty) _processQRCode(results.first);
    } catch (_) {
    } finally {
      _isWechatDecoding = false;
      try { await tempFile?.delete(); } catch (_) {}
    }
  }

  /// 定时截取相机预览画面，交给 WeChatQRCode 识别
  /// 解决 MLKit 对高密度二维码完全无法触发 onDetect 的问题
  Future<void> _periodicWeChatScan() async {
    if (_isProcessing || _isWechatDecoding) return;
    if (!mounted) return;

    final renderObject = _cameraKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;

    _isWechatDecoding = true;
    _scanAttempts++;
    File? tempFile;
    try {
      final image = await renderObject.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/periodic_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      tempFile = File(tempPath);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      final results = await _wechatScanner.detectAndDecode(tempPath);
      if (results.isNotEmpty && mounted) {
        _processQRCode(results.first);
      } else if (mounted && _scanAttempts > 3 && _scanStatus.isEmpty) {
        setState(() => _scanStatus = '未识别到二维码，请调整距离或角度');
      }
    } catch (e) {
      debugPrint('定时扫描异常: $e');
    } finally {
      _isWechatDecoding = false;
      try { await tempFile?.delete(); } catch (_) {}
    }
  }

  /// 从相册选择图片扫描（使用 WeChatQRCode 强力扫描）

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing) return;

    try {
      debugPrint('🔍 开始从相册选择图片...');

      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        debugPrint('ℹ️ 用户取消选择图片');

        return;
      }

      debugPrint('🖼 图片已选择: ${image.path}');

      // 使用 WeChatQRCode 扫描器（强力 CNN 模型）

      debugPrint('🚀 使用 WeChatQRCode 扫描...');

      // 初始化扫描器（首次调用会加载模型）

      await _wechatScanner.initialize();

      // 扫描图片

      final results = await _wechatScanner.detectAndDecode(image.path);

      if (results.isEmpty) {
        debugPrint('ℹ️ WeChatQRCode 未找到二维码');

        if (mounted) {
          AppSnackBar.show(
            context,
            '未在图片中找到二维码\n请确保图片清晰且二维码完整',
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
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
        AppSnackBar.show(
          context,
          '扫描图片失败: $e',
          backgroundColor: AppColors.error,
        );
      }
    }
  }

  /// 处理二维码内容

  void _processQRCode(String code) {
    if (_isProcessing) return;
    _isProcessing = true;
    _periodicScanTimer?.cancel();
    _controller.stop();
    if (mounted) setState(() => _scanStatus = '识别成功，正在解析内容...');

    Uri? uri;

    try {
      uri = Uri.parse(code);
    } catch (_) {
      uri = null;
    }

    if (uri != null && uri.scheme == 'howtocook' && uri.host == 'tip') {
      _handleTipQRCode(uri);

      return;
    }

    try {
      final recipe = _parseRecipeQRCode(code);

      if (recipe == null) {
        debugPrint('✅ 内置食谱跳转完成');

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });

        return;
      }

      if (mounted) {
        try {
          context.push('/recipe-preview', extra: recipe);

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
            }
          });
        } catch (e, stackTrace) {
          debugPrint('❌ 跳转失败: $e');

          debugPrint('堆栈: $stackTrace');

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
        AppSnackBar.show(
          context,
          '解析失败: $e',
          backgroundColor: AppColors.error,
        );
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleTipQRCode(Uri uri) async {
    try {
      final tip = _parseTipUri(uri);

      if (tip == null) {
        if (mounted) {
          AppSnackBar.show(
            context,
            '无法解析教程二维码',
            backgroundColor: AppColors.error,
          );

          setState(() => _isProcessing = false);
        }

        return;
      }

      Tip? existing;

      try {
        existing = await ref.read(tipRepositoryProvider).getTipById(tip.id);
      } catch (_) {
        existing = null;
      }

      if (!mounted) return;

      if (existing != null && existing.hash == tip.hash) {
        context.push('/tips/${existing.category}/${existing.id}');
      } else {
        context.push('/tip-preview', extra: tip);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
    } catch (e) {
      debugPrint('处理教程二维码失败: $e');

      if (mounted) {
        AppSnackBar.show(
          context,
          '解析教程失败: $e',
          backgroundColor: AppColors.error,
        );

        setState(() => _isProcessing = false);
      }
    }
  }

  Tip? _parseTipUri(Uri uri) {
    try {
      Map<String, dynamic>? json;

      if (uri.queryParameters.containsKey('raw')) {
        json = _decodeTipRaw(uri.queryParameters['raw']!);
      } else if (uri.queryParameters.containsKey('data')) {
        json = _decodeTipCompressed(uri.queryParameters['data']!);
      } else if (uri.queryParameters.containsKey('json')) {
        final jsonString = Uri.decodeComponent(uri.queryParameters['json']!);

        json = jsonDecode(jsonString) as Map<String, dynamic>;
      }

      if (json == null) {
        return null;
      }

      return _tipFromJson(json);
    } catch (e) {
      debugPrint('解析教程 URI 失败: $e');

      return null;
    }
  }

  Map<String, dynamic>? _decodeTipRaw(String base64Data) {
    try {
      var padded = base64Data;

      while (padded.length % 4 != 0) {
        padded += '=';
      }

      final bytes = base64Url.decode(padded);

      final jsonString = utf8.decode(bytes);

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('解析教程 raw 数据失败: $e');

      return null;
    }
  }

  Map<String, dynamic>? _decodeTipCompressed(String base64Data) {
    try {
      var padded = base64Data;

      while (padded.length % 4 != 0) {
        padded += '=';
      }

      final gzipBytes = base64Url.decode(padded);

      final utf8Bytes = GZipDecoder().decodeBytes(gzipBytes);

      final jsonString = utf8.decode(utf8Bytes);

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('解析教程压缩数据失败: $e');

      return null;
    }
  }

  Tip _tipFromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? [];

    final sections = sectionsJson.map((item) {
      if (item is Map<String, dynamic>) {
        return TipSection(
          title: (item['title'] as String? ?? '').trim(),

          content: (item['content'] as String? ?? '').trim(),
        );
      }

      return TipSection(title: '', content: item?.toString() ?? '');
    }).toList();

    DateTime? createdAt;

    DateTime? updatedAt;

    final createdAtString = json['createdAt'] as String?;

    final updatedAtString = json['updatedAt'] as String?;

    if (createdAtString != null) {
      createdAt = DateTime.tryParse(createdAtString);
    }

    if (updatedAtString != null) {
      updatedAt = DateTime.tryParse(updatedAtString);
    }

    return Tip(
      id:
          json['id'] as String? ??
          'tip_${DateTime.now().millisecondsSinceEpoch}',

      title: json['title'] as String? ?? '未命名教程',

      category: json['category'] as String? ?? 'general',

      categoryName: json['categoryName'] as String? ?? '教程',

      content: json['content'] as String? ?? '',

      sections: sections,

      hash: json['hash'] as String? ?? '',

      source: TipSource.scanned,

      createdAt: createdAt,

      updatedAt: updatedAt,
    );
  }

  /// 解析二维码数据为 Recipe 对象

  ///

  /// 支持三种格式：

  /// 1. Raw Scheme: howtocook://recipe?raw=BASE64URL(JSON) - 未压缩格式

  /// 2. Compressed Scheme: howtocook://recipe?data=BASE64URL(GZIP(JSON)) - 压缩格式

  /// 3. Fallback Scheme: howtocook://recipe?json=URL_ENCODED_JSON - 降级格式

  Recipe? _parseRecipeQRCode(String code) {
    try {
      final uri = Uri.parse(code);

      // 检查协议和路径

      if (uri.scheme != 'howtocook' || uri.host != 'recipe') {
        debugPrint('不是有效的 howtocook 协议');

        return null;
      }

      // 优先处理未压缩的 Base64URL 格式

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
      // 1. Base64URL 解码（补全 padding）

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
      // 1. Base64URL 解码（补全 padding）

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

      debugPrint('✅ 解析压缩数据成功: ${gzipBytes.length} -> ${utf8Bytes.length} 字节');

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

        debugPrint('✏️ 修改的内置食谱');

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

    final category = json['c'] as String;
    final categoryMap = ref.read(categoryNameMapProvider).valueOrNull ?? {};
    final categoryName = json['cn'] as String? ?? categoryMap[category] ?? category;

    // 兼容新旧格式：新格式用 \n 分隔字符串，旧格式是 List
    final rawIngredients = json['i'];
    final ingredientTexts = rawIngredients is String
        ? rawIngredients.split('\n')
        : List<String>.from(rawIngredients as List<dynamic>);

    final rawSteps = json['s'];
    final stepTexts = rawSteps is String
        ? rawSteps.split('\n')
        : List<String>.from(rawSteps as List<dynamic>);

    final rawWarnings = json['w'];
    final warnings = rawWarnings == null
        ? <String>[]
        : rawWarnings is String
            ? rawWarnings.split('\n')
            : List<String>.from(rawWarnings as List<dynamic>);

    final rawTools = json['tl'];
    final tools = rawTools == null
        ? <String>[]
        : rawTools is String
            ? rawTools.split('\n').where((t) => t.isNotEmpty).toList()
            : List<String>.from(rawTools as List<dynamic>);

    final recipe = Recipe(
      id: recipeId,
      name: json['n'] as String,
      category: category,
      categoryName: categoryName,
      difficulty: json['d'] as int,
      ingredients: ingredientTexts.where((t) => t.isNotEmpty).map((textStr) {
        final firstSpaceIndex = textStr.indexOf(' ');
        final name = firstSpaceIndex > 0
            ? textStr.substring(0, firstSpaceIndex)
            : textStr;
        return Ingredient(name: name, text: textStr);
      }).toList(),
      steps: stepTexts.where((d) => d.isNotEmpty)
          .map((desc) => CookingStep(description: desc))
          .toList(),
      tips: json['t'] as String?,
      warnings: warnings,
      tools: tools,
      images: [],
      hash: '',
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
      ..color = AppColors.textPrimary.withValues(alpha: 0.5)
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

    canvas.drawLine(
      Offset(left, top),

      Offset(left + cornerLength, top),

      cornerPaint,
    );

    canvas.drawLine(
      Offset(left, top),

      Offset(left, top + cornerLength),

      cornerPaint,
    );

    // 右上角

    canvas.drawLine(
      Offset(left + scanAreaSize, top),

      Offset(left + scanAreaSize - cornerLength, top),

      cornerPaint,
    );

    canvas.drawLine(
      Offset(left + scanAreaSize, top),

      Offset(left + scanAreaSize, top + cornerLength),

      cornerPaint,
    );

    // 左下角

    canvas.drawLine(
      Offset(left, top + scanAreaSize),

      Offset(left + cornerLength, top + scanAreaSize),

      cornerPaint,
    );

    canvas.drawLine(
      Offset(left, top + scanAreaSize),

      Offset(left, top + scanAreaSize - cornerLength),

      cornerPaint,
    );

    // 右下角

    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),

      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),

      cornerPaint,
    );

    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),

      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),

      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
