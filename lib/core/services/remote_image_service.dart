import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// 远程图片服务
///
/// 从 GitHub Pages 动态下载图片，减少 APK 体积
/// 配合新的图片下载管理器使用
class RemoteImageService {
  static const String _baseUrl = 'https://username.github.io/recipe-images';
  static const String _indexUrl = '$_baseUrl/index.json';
  static const String _cacheDirName = 'recipe_images';

  final Dio _dio = Dio();
  Map<String, dynamic>? _imageIndex;
  final Map<String, String> _downloading = {};

  /// 初始化服务（下载索引文件）
  Future<void> initialize() async {
    try {
      print('🔄 正在下载图片索引...');
      final response = await _dio.get(_indexUrl);
      _imageIndex = jsonDecode(response.data);
      print('✅ 图片索引下载成功');
    } catch (e) {
      print('❌ 图片索引下载失败: $e');
      _imageIndex = {};
    }
  }

  /// 获取本地图片路径
  ///
  /// 如果本地不存在，则从远程下载
  Future<String?> getImagePath(String category, String imageId) async {
    // 1. 检查本地缓存
    final localPath = await _getLocalImagePath(category, imageId);
    if (await File(localPath).exists()) {
      return localPath;
    }

    // 2. 检查是否正在下载
    final downloadKey = '$category/$imageId';
    if (_downloading.containsKey(downloadKey)) {
      // 等待下载完成
      await _waitForDownload(downloadKey);
      return File(localPath).exists() ? localPath : null;
    }

    // 3. 从远程下载
    return await _downloadImage(category, imageId, localPath);
  }

  /// 获取本地图片路径
  Future<String> _getLocalImagePath(String category, String imageId) async {
    final cacheDir = await getApplicationDocumentsDirectory();
    return '${cacheDir.path}/$_cacheDirName/$category/$imageId.webp';
  }

  /// 从远程下载图片
  Future<String?> _downloadImage(String category, String imageId, String localPath) async {
    final downloadKey = '$category/$imageId';
    _downloading[downloadKey] = 'downloading';

    try {
      // 获取远程图片信息
      final imageInfo = _getImageInfo(category, imageId);
      if (imageInfo == null) {
        print('⚠️ 图片信息未找到: $category/$imageId');
        _downloading.remove(downloadKey);
        return null;
      }

      // 创建本地目录
      final file = File(localPath);
      await file.parent.create(recursive: true);

      // 下载图片
      final imageUrl = '$_baseUrl/images/$category/${imageInfo['webp']}';
      print('📥 下载图片: $imageUrl');

      final response = await _dio.get(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: Duration(seconds: 30),
        ),
      );

      // 保存到本地
      await file.writeAsBytes(response.data);
      print('✅ 图片下载完成: $localPath');

      _downloading.remove(downloadKey);
      return localPath;
    } catch (e) {
      print('❌ 图片下载失败: $category/$imageId, 错误: $e');
      _downloading.remove(downloadKey);
      return null;
    }
  }

  /// 等待下载完成
  Future<void> _waitForDownload(String downloadKey) async {
    while (_downloading.containsKey(downloadKey)) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  /// 获取图片信息
  Map<String, dynamic>? _getImageInfo(String category, String imageId) {
    if (_imageIndex == null) return null;

    final categoryData = _imageIndex!['images']?[category];
    if (categoryData == null) return null;

    return categoryData[imageId];
  }

  /// 预加载图片
  ///
  /// 批量下载常用图片
  Future<void> preloadImages(List<String> categoryImageIds) async {
    print('🚀 开始预加载图片...');

    for (final categoryImageId in categoryImageIds) {
      final parts = categoryImageId.split('/');
      if (parts.length != 2) continue;

      await getImagePath(parts[0], parts[1]);
    }

    print('✅ 图片预加载完成');
  }

  /// 清理缓存
  Future<void> clearCache() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/$_cacheDirName');

      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
        print('🗑️ 图片缓存已清理');
      }
    } catch (e) {
      print('❌ 清理缓存失败: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/$_cacheDirName');

      if (!await imageCacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in imageCacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('❌ 计算缓存大小失败: $e');
      return 0;
    }
  }
}