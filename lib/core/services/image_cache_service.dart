import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_cache_service.g.dart';

/// 图片缓存服务 - 管理本地图片缓存的路径和访问
@riverpod
class ImageCacheService extends _$ImageCacheService {
  @override
  void build() {}

  /// 获取封面图路径（按菜名）
  /// 返回本地缓存路径，如果不存在则返回null
  Future<String?> getCoverImagePath(String category, String recipeName) async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final coverPath = '${cacheDir.path}/recipe_images/covers/$category/$recipeName.webp';
      final file = File(coverPath);

      if (await file.exists()) {
        return coverPath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 获取封面图路径失败: $category/$recipeName, 错误: $e');
      return null;
    }
  }

  /// 获取详情图路径（按ID和索引）
  /// 返回本地缓存路径，如果不存在则返回null
  Future<String?> getDetailImagePath(String category, String recipeId, int index) async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final imagePath = '${cacheDir.path}/recipe_images/details/$category/${recipeId}_$index.webp';
      final file = File(imagePath);

      if (await file.exists()) {
        return imagePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ 获取详情图路径失败: $category/${recipeId}_$index, 错误: $e');
      return null;
    }
  }

  /// 获取所有详情图路径列表
  /// 返回已缓存的详情图路径列表
  Future<List<String>> getDetailImagePaths(String category, String recipeId, int imageCount) async {
    final paths = <String>[];

    for (int i = 0; i < imageCount; i++) {
      final path = await getDetailImagePath(category, recipeId, i);
      if (path != null) {
        paths.add(path);
      }
    }

    return paths;
  }

  /// 检查封面图是否已缓存
  Future<bool> hasCoverImage(String category, String recipeName) async {
    final path = await getCoverImagePath(category, recipeName);
    return path != null;
  }

  /// 检查详情图是否已缓存
  Future<bool> hasDetailImage(String category, String recipeId, int index) async {
    final path = await getDetailImagePath(category, recipeId, index);
    return path != null;
  }

  /// 获取已缓存的详情图数量
  Future<int> getCachedDetailImageCount(String category, String recipeId, int totalCount) async {
    int cachedCount = 0;

    for (int i = 0; i < totalCount; i++) {
      if (await hasDetailImage(category, recipeId, i)) {
        cachedCount++;
      }
    }

    return cachedCount;
  }

  /// 清除所有图片缓存
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/recipe_images');

      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
        debugPrint('✅ 图片缓存已清除');
      }
    } catch (e) {
      debugPrint('❌ 清除图片缓存失败: $e');
    }
  }

  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/recipe_images');

      if (!await imageCacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in imageCacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ 计算缓存大小失败: $e');
      return 0;
    }
  }
}
