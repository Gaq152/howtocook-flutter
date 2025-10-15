import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:howtocook/core/services/image_download_manager.dart';

part 'data_sync_service.g.dart';
part 'data_sync_service.freezed.dart';

/// 同步状态枚举
enum SyncStatus {
  idle,          // 空闲
  checking,      // 检查更新
  downloading,   // 下载中
  completed,     // 已完成
  error,         // 出错
}

/// 同步配置
class SyncConfig {
  final bool downloadImages;
  final bool onlyWifi;
  final int maxConcurrentDownloads;

  const SyncConfig({
    this.downloadImages = true,
    this.onlyWifi = false,
    this.maxConcurrentDownloads = 3,
  });
}

/// 数据同步服务
@riverpod
class DataSyncService extends _$DataSyncService {
  static const String _remoteBaseUrl = 'https://username.github.io/recipe-data';
  static const String _indexUrl = '$_remoteBaseUrl/index.json';
  static const String _localDataDirName = 'recipe_data';

  final Dio _dio = Dio();

  @override
  DataSyncState build() {
    return const DataSyncState(
      status: SyncStatus.idle,
      progress: 0,
      downloadedRecipes: 0,
      totalRecipes: 0,
      downloadedImages: 0,
      totalImages: 0,
    );
  }

  /// 开始数据同步
  Future<void> startSync(SyncConfig config) async {
    try {
      state = state.copyWith(status: SyncStatus.checking);
      print('🔄 开始检查数据更新...');

      // 1. 下载远程索引
      final remoteIndex = await _downloadRemoteIndex();
      if (remoteIndex == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          error: '无法下载远程索引文件',
        );
        return;
      }

      // 2. 检查本地索引
      final localIndex = await _loadLocalIndex();

      // 3. 比较并识别需要更新的食谱
      final updates = _identifyUpdates(localIndex, remoteIndex);
      state = state.copyWith(
        totalRecipes: updates.length,
        totalImages: _estimateImageCount(updates),
      );

      if (updates.isEmpty) {
        state = state.copyWith(
          status: SyncStatus.completed,
          progress: 100,
        );
        print('✅ 数据已是最新，无需更新');
        return;
      }

      // 4. 开始下载更新的JSON文件
      state = state.copyWith(status: SyncStatus.downloading);
      print('📥 开始下载 ${updates.length} 个食谱更新...');

      int downloadedCount = 0;
      final imageDownloadTasks = <DownloadTask>[];

      for (final update in updates) {
        try {
          // 下载JSON文件
          final success = await _downloadRecipeJson(update);
          if (success) {
            downloadedCount++;
            state = state.copyWith(
              downloadedRecipes: downloadedCount,
              progress: (downloadedCount / updates.length * 50).round(), // JSON下载占50%
            );

            // 如果启用图片下载，解析图片路径并添加到下载任务
            if (config.downloadImages) {
              final imageTasks = await _extractImageTasks(update);
              imageDownloadTasks.addAll(imageTasks);
            }
          }
        } catch (e) {
          print('❌ 下载食谱失败: ${update.category}/${update.recipeId}, 错误: $e');
        }
      }

      // 5. 保存更新后的索引
      await _saveLocalIndex(remoteIndex);

      // 6. 开始下载图片
      if (config.downloadImages && imageDownloadTasks.isNotEmpty) {
        print('🖼️ 开始下载 ${imageDownloadTasks.length} 张图片...');

        // 按优先级排序：封面图优先
        imageDownloadTasks.sort((a, b) => a.priority.compareTo(b.priority));

        // 提交给图片下载管理器
        ref.read(imageDownloadManagerProvider.notifier).addDownloadTasks(imageDownloadTasks);
      }

      state = state.copyWith(
        status: SyncStatus.completed,
        progress: 100,
      );
      print('✅ 数据同步完成');

    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: e.toString(),
      );
      print('❌ 数据同步失败: $e');
    }
  }

  /// 下载远程索引文件
  Future<Map<String, dynamic>?> _downloadRemoteIndex() async {
    try {
      final response = await _dio.get(_indexUrl);
      return jsonDecode(response.data);
    } catch (e) {
      print('❌ 下载远程索引失败: $e');
      return null;
    }
  }

  /// 加载本地索引文件
  Future<Map<String, dynamic>?> _loadLocalIndex() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final indexPath = '${cacheDir.path}/$_localDataDirName/index.json';
      final file = File(indexPath);

      if (!await file.exists()) return {};

      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      print('❌ 加载本地索引失败: $e');
      return {};
    }
  }

  /// 识别需要更新的食谱
  List<RecipeUpdate> _identifyUpdates(
    Map<String, dynamic>? localIndex,
    Map<String, dynamic> remoteIndex,
  ) {
    final updates = <RecipeUpdate>[];
    final remoteRecipes = remoteIndex['recipes'] as Map<String, dynamic>? ?? {};

    for (final categoryEntry in remoteRecipes.entries) {
      final category = categoryEntry.key;
      final categoryData = categoryEntry.value as Map<String, dynamic>;

      for (final recipeEntry in categoryData.entries) {
        final recipeId = recipeEntry.key;
        final remoteRecipe = recipeEntry.value as Map<String, dynamic>;
        final remoteLastModified = remoteRecipe['lastModified'] as String? ?? '';

        final localRecipe = localIndex?['recipes']?[category]?[recipeId] as Map<String, dynamic>?;
        final localLastModified = localRecipe?['lastModified'] as String? ?? '';

        // 如果远程版本更新，或者本地不存在，则需要更新
        if (remoteLastModified.compareTo(localLastModified) > 0) {
          updates.add(RecipeUpdate(
            category: category,
            recipeId: recipeId,
            lastModified: remoteLastModified,
            isNew: localRecipe == null,
          ));
        }
      }
    }

    return updates;
  }

  /// 下载单个食谱JSON文件
  Future<bool> _downloadRecipeJson(RecipeUpdate update) async {
    try {
      final url = '$_remoteBaseUrl/recipes/${update.category}/${update.category}_${update.recipeId}.json';
      final cacheDir = await getApplicationDocumentsDirectory();
      final localPath = '${cacheDir.path}/$_localDataDirName/recipes/${update.category}/${update.category}_${update.recipeId}.json';

      final file = File(localPath);
      await file.parent.create(recursive: true);

      final response = await _dio.get(url);
      await file.writeAsString(response.data);

      print('✅ 食谱JSON下载完成: ${update.category}/${update.recipeId}');
      return true;
    } catch (e) {
      print('❌ 食谱JSON下载失败: ${update.category}/${update.recipeId}, 错误: $e');
      return false;
    }
  }

  /// 从食谱JSON中提取图片下载任务
  Future<List<DownloadTask>> _extractImageTasks(RecipeUpdate update) async {
    final tasks = <DownloadTask>[];

    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final jsonPath = '${cacheDir.path}/$_localDataDirName/recipes/${update.category}/${update.category}_${update.recipeId}.json';
      final file = File(jsonPath);

      if (!await file.exists()) return tasks;

      final content = await file.readAsString();
      final recipeData = jsonDecode(content);
      final images = recipeData['images'] as List<dynamic>? ?? [];

      for (int i = 0; i < images.length; i++) {
        final imagePath = images[i] as String;
        final imageUrl = '$_remoteBaseUrl/$imagePath';
        final localPath = '${cacheDir.path}/recipe_images/${update.category}/${update.category}_${update.recipeId}_$i.webp';

        tasks.add(DownloadTask(
          id: '${update.category}_${update.recipeId}_$i',
          category: update.category,
          recipeId: update.recipeId,
          imageUrl: imageUrl,
          localPath: localPath,
          priority: i == 0 ? 0 : 1, // 第一张图片（封面）优先级更高
        ));
      }
    } catch (e) {
      print('❌ 提取图片任务失败: ${update.category}/${update.recipeId}, 错误: $e');
    }

    return tasks;
  }

  /// 保存本地索引文件
  Future<void> _saveLocalIndex(Map<String, dynamic> index) async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final indexPath = '${cacheDir.path}/$_localDataDirName/index.json';
      final file = File(indexPath);

      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(index));
      print('✅ 本地索引已更新');
    } catch (e) {
      print('❌ 保存本地索引失败: $e');
    }
  }

  /// 估算图片数量
  int _estimateImageCount(List<RecipeUpdate> updates) {
    // 简单估算：每个食谱平均2张图片
    return updates.length * 2;
  }

  /// 获取本地数据大小
  Future<int> getLocalDataSize() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${cacheDir.path}/$_localDataDirName');

      if (!await dataDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dataDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('❌ 计算本地数据大小失败: $e');
      return 0;
    }
  }

  /// 清理本地数据
  Future<void> clearLocalData() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${cacheDir.path}/$_localDataDirName');

      if (await dataDir.exists()) {
        await dataDir.delete(recursive: true);
        print('🗑️ 本地数据已清理');
      }
    } catch (e) {
      print('❌ 清理本地数据失败: $e');
    }
  }
}

/// 食谱更新信息
class RecipeUpdate {
  final String category;
  final String recipeId;
  final String lastModified;
  final bool isNew;

  RecipeUpdate({
    required this.category,
    required this.recipeId,
    required this.lastModified,
    required this.isNew,
  });
}

/// 数据同步状态
@freezed
class DataSyncState with _$DataSyncState {
  const factory DataSyncState({
    required SyncStatus status,
    required int progress,
    required int downloadedRecipes,
    required int totalRecipes,
    required int downloadedImages,
    required int totalImages,
    String? error,
  }) = _DataSyncState;
}