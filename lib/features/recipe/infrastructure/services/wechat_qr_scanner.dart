import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';

/// WeChat QRCode 扫描器服务
///
/// 使用微信开源的 CNN 模型进行高精度 QR 码检测和解码
/// 相比 ML Kit，对高密度、小尺寸、长图中的 QR 码识别能力更强
class WeChatQRScanner {
  cv.WeChatQRCode? _detector;
  bool _isInitialized = false;

  /// 初始化扫描器（加载模型文件）
  ///
  /// 需要 4 个模型文件：
  /// - detect.prototxt/detect.caffemodel: 目标检测模型
  /// - sr.prototxt/sr.caffemodel: 超分辨率模型
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ WeChatQRCode 已初始化，跳过');
      return;
    }

    try {
      debugPrint('🔄 开始初始化 WeChatQRCode...');

      // 1. 将 assets 中的模型文件复制到临时目录（OpenCV 需要文件路径）
      final tempDir = await getTemporaryDirectory();
      final modelDir = Directory('${tempDir.path}/wechat_qrcode_models');

      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      // 2. 复制所有模型文件
      final modelFiles = [
        'detect.prototxt',
        'detect.caffemodel',
        'sr.prototxt',
        'sr.caffemodel',
      ];

      for (final fileName in modelFiles) {
        final destFile = File('${modelDir.path}/$fileName');

        // 如果文件已存在且不为空，跳过
        if (await destFile.exists() && await destFile.length() > 0) {
          debugPrint('  ✅ $fileName 已存在，跳过复制');
          continue;
        }

        // 从 assets 读取并写入临时目录
        debugPrint('  📥 复制 $fileName...');
        final bytes = await rootBundle.load('assets/models/wechat_qrcode/$fileName');
        await destFile.writeAsBytes(bytes.buffer.asUint8List());
        debugPrint('  ✅ $fileName 复制完成 (${await destFile.length()} 字节)');
      }

      // 3. 初始化 WeChatQRCode 检测器
      debugPrint('🔧 初始化 WeChatQRCode 检测器...');
      _detector = cv.WeChatQRCode(
        '${modelDir.path}/detect.prototxt',
        '${modelDir.path}/detect.caffemodel',
        '${modelDir.path}/sr.prototxt',
        '${modelDir.path}/sr.caffemodel',
      );

      _isInitialized = true;
      debugPrint('✅ WeChatQRCode 初始化成功！');
    } catch (e, stackTrace) {
      debugPrint('❌ WeChatQRCode 初始化失败: $e');
      debugPrint('堆栈: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 扫描图片中的 QR 码
  ///
  /// [imagePath] 图片文件路径
  /// 返回：解码结果列表
  ///
  /// 如果找到多个 QR 码，返回多个结果
  /// 如果没有找到，返回空列表
  Future<List<String>> detectAndDecode(String imagePath) async {
    if (!_isInitialized) {
      debugPrint('⚠️  WeChatQRCode 未初始化，尝试初始化...');
      await initialize();
    }

    if (_detector == null) {
      throw Exception('WeChatQRCode 检测器未初始化');
    }

    try {
      debugPrint('📸 开始扫描: $imagePath');

      // 1. 读取图片
      final mat = cv.imread(imagePath);
      debugPrint('📐 图片尺寸: ${mat.width} x ${mat.height}');

      // 2. 检测并解码
      final (results, points) = _detector!.detectAndDecode(mat);

      debugPrint('✅ 扫描完成，找到 ${results.length} 个 QR 码');

      if (results.isNotEmpty) {
        for (int i = 0; i < results.length; i++) {
          debugPrint('  QR码 ${i + 1}:');
          debugPrint('    内容长度: ${results[i].length} 字符');
          if (results[i].length < 100) {
            debugPrint('    内容: ${results[i]}');
          }
          // 打印边界框信息
          debugPrint('    边界框数量: ${points.length}');
        }
      }

      return results;
    } catch (e, stackTrace) {
      debugPrint('❌ WeChatQRCode 扫描失败: $e');
      debugPrint('堆栈: $stackTrace');
      return <String>[];
    }
  }

  /// 释放资源
  void dispose() {
    _detector?.dispose();
    _detector = null;
    _isInitialized = false;
    debugPrint('🗑️  WeChatQRCode 资源已释放');
  }
}
