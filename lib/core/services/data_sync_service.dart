import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:howtocook/core/services/image_download_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final bool downloadCoverImages;  // 下载封面图
  final bool downloadDetailImages; // 下载详情图
  final bool onlyWifi;
  final int maxConcurrentDownloads;

  const SyncConfig({
    this.downloadCoverImages = true,
    this.downloadDetailImages = false,  // 默认不下载详情图
    this.onlyWifi = false,
    this.maxConcurrentDownloads = 3,
  });
}

/// 数据同步服务
@riverpod
class DataSyncService extends _$DataSyncService {
  late final String _remoteBaseUrl;
  late final String _manifestUrl;
  static const String _localDataDirName = 'recipe_data';

  String get _baseUrl => dotenv.env['STATIC_RESOURCE_URL'] ?? 'https://gaq152.github.io/HowToCook-assets';

  final Dio _dio = Dio();

  @override
  DataSyncState build() {
    // 初始化URL
    _remoteBaseUrl = _baseUrl;
    _manifestUrl = '$_remoteBaseUrl/manifest.json';

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
      final remoteIndex = await downloadRemoteIndex();
      if (remoteIndex == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          error: '无法下载远程索引文件',
        );
        return;
      }

      // 2. 检查本地索引
      final localIndex = await loadLocalIndex();

      // 3. 比较并识别需要更新的食谱
      final updates = identifyUpdates(localIndex, remoteIndex);
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
      final coverImageTasks = <DownloadTask>[];
      final detailImageTasks = <DownloadTask>[];

      for (final update in updates) {
        try {
          // 下载JSON文件
          final success = await downloadRecipeJson(update);
          if (success) {
            downloadedCount++;
            state = state.copyWith(
              downloadedRecipes: downloadedCount,
              progress: (downloadedCount / updates.length * 50).round(), // JSON下载占50%
            );

            // 如果启用封面图下载，添加封面图下载任务
            if (config.downloadCoverImages) {
              final coverTask = await extractCoverImageTask(update);
              if (coverTask != null) {
                coverImageTasks.add(coverTask);
              }
            }

            // 如果启用详情图下载，解析详情图路径并添加到下载任务
            if (config.downloadDetailImages) {
              final detailTasks = await extractDetailImageTasks(update);
              detailImageTasks.addAll(detailTasks);
            }
          }
        } catch (e) {
          print('❌ 下载食谱失败: ${update.category}/${update.recipeId}, 错误: $e');
        }
      }

      // 5. 保存更新后的索引
      await saveLocalIndex(remoteIndex);

      // 6. 开始下载图片
      final allImageTasks = [...coverImageTasks, ...detailImageTasks];
      if (allImageTasks.isNotEmpty) {
        print('🖼️ 开始下载图片...');
        print('  - 封面图: ${coverImageTasks.length} 张');
        print('  - 详情图: ${detailImageTasks.length} 张');

        // 按优先级排序：封面图优先（priority=0），详情图次之（priority=1）
        allImageTasks.sort((a, b) => a.priority.compareTo(b.priority));

        // 提交给图片下载管理器
        ref.read(imageDownloadManagerProvider.notifier).addDownloadTasks(allImageTasks);
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

  /// 下载远程清单文件
  Future<Map<String, dynamic>?> downloadRemoteIndex() async {
    try {
      print('🌐 正在下载远程清单: $_manifestUrl');
      final response = await _dio.get(_manifestUrl);

      if (response.statusCode == 200) {
        String responseData;
        if (response.data is String) {
          responseData = response.data;
        } else {
          responseData = jsonEncode(response.data);
        }

        final data = jsonDecode(responseData);
        print('✅ 远程清单下载成功');
        return data;
      } else {
        print('❌ 远程清单返回错误状态码: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('❌ 下载远程清单失败: ${e.type} - ${e.message}');
      if (e.response?.statusCode == 404) {
        print('❌ 远程清单文件不存在 (404): $_manifestUrl');
        print('💡 请检查远程服务器上是否有 manifest.json 文件');
      }
      return null;
    } catch (e) {
      print('❌ 下载远程清单失败: $e');
      return null;
    }
  }

  
  /// 加载本地清单文件
  Future<Map<String, dynamic>?> loadLocalIndex() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final manifestPath = '${cacheDir.path}/$_localDataDirName/manifest.json';
      final file = File(manifestPath);

      if (!await file.exists()) return {};

      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      print('❌ 加载本地清单失败: $e');
      return {};
    }
  }

  /// 识别需要更新的食谱
  List<RecipeUpdate> identifyUpdates(
    Map<String, dynamic>? localIndex,
    Map<String, dynamic> remoteIndex,
  ) {
    final updates = <RecipeUpdate>[];
    final remoteRecipes = remoteIndex['recipes'] as List<dynamic>? ?? [];

    // 本地索引格式：{recipes: []}
    final localRecipes = localIndex?['recipes'] as List<dynamic>? ?? [];

    // 创建本地食谱的映射表以便快速查找
    final localRecipeMap = <String, Map<String, dynamic>>{};
    for (final recipe in localRecipes) {
      final recipeId = recipe['id'] as String;
      localRecipeMap[recipeId] = recipe as Map<String, dynamic>;
    }

    for (final remoteRecipe in remoteRecipes) {
      final recipeId = remoteRecipe['id'] as String;
      final category = remoteRecipe['category'] as String;
      final recipeHash = remoteRecipe['hash'] as String;

      final localRecipe = localRecipeMap[recipeId];

      // 如果本地不存在，或者hash不同，则需要更新
      if (localRecipe == null || localRecipe['hash'] != recipeHash) {
        updates.add(RecipeUpdate(
          category: category,
          recipeId: recipeId,
          lastModified: remoteRecipe['generatedAt'] as String? ?? '',
          isNew: localRecipe == null,
          hash: recipeHash,
        ));
      }
    }

    return updates;
  }

  /// 下载单个食谱JSON文件
  Future<bool> downloadRecipeJson(RecipeUpdate update) async {
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

  /// 提取封面图下载任务（按菜名）
  Future<DownloadTask?> extractCoverImageTask(RecipeUpdate update) async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final jsonPath = '${cacheDir.path}/$_localDataDirName/recipes/${update.category}/${update.category}_${update.recipeId}.json';
      final file = File(jsonPath);

      if (!await file.exists()) {
        print('⚠️  JSON文件不存在，跳过封面图提取: $jsonPath');
        return null;
      }

      final content = await file.readAsString();
      final recipeData = jsonDecode(content);
      final recipeName = recipeData['name'] as String;

      // 封面图按菜名存储：covers/{category}/{name}.webp
      final coverUrl = '$_remoteBaseUrl/covers/${update.category}/$recipeName.webp';
      final localPath = '${cacheDir.path}/recipe_images/covers/${update.category}/$recipeName.webp';

      print('📋 封面图下载任务:');
      print('   - 分类: ${update.category}');
      print('   - 菜名: $recipeName');
      print('   - URL: $coverUrl');
      print('   - 本地: $localPath');

      return DownloadTask(
        id: 'cover_${update.category}_${update.recipeId}',
        category: update.category,
        recipeId: update.recipeId,
        imageUrl: coverUrl,
        localPath: localPath,
        priority: 0, // 封面图优先级最高
      );
    } catch (e) {
      print('❌ 提取封面图任务失败: ${update.category}/${update.recipeId}, 错误: $e');
      return null;
    }
  }

  /// 从食谱JSON中提取详情图下载任务（按ID）
  Future<List<DownloadTask>> extractDetailImageTasks(RecipeUpdate update) async {
    final tasks = <DownloadTask>[];

    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final jsonPath = '${cacheDir.path}/$_localDataDirName/recipes/${update.category}/${update.category}_${update.recipeId}.json';
      final file = File(jsonPath);

      if (!await file.exists()) {
        print('⚠️  JSON文件不存在，跳过详情图提取: $jsonPath');
        return tasks;
      }

      final content = await file.readAsString();
      final recipeData = jsonDecode(content);
      final images = recipeData['images'] as List<dynamic>? ?? [];

      if (images.isEmpty) {
        print('ℹ️  食谱无详情图: ${update.category}/${update.recipeId}');
        return tasks;
      }

      print('📋 详情图下载任务（${update.category}/${update.recipeId}）: ${images.length} 张');

      for (int i = 0; i < images.length; i++) {
        // 详情图按ID存储：images/{category}/{recipeId}_$i.webp
        final imageUrl = '$_remoteBaseUrl/images/${update.category}/${update.recipeId}_$i.webp';
        final localPath = '${cacheDir.path}/recipe_images/details/${update.category}/${update.recipeId}_$i.webp';

        print('   [$i] URL: $imageUrl');
        print('   [$i] 本地: $localPath');

        tasks.add(DownloadTask(
          id: 'detail_${update.category}_${update.recipeId}_$i',
          category: update.category,
          recipeId: update.recipeId,
          imageUrl: imageUrl,
          localPath: localPath,
          priority: 1, // 详情图优先级次之
        ));
      }
    } catch (e) {
      print('❌ 提取详情图任务失败: ${update.category}/${update.recipeId}, 错误: $e');
    }

    return tasks;
  }

  /// 保存本地清单文件
  Future<void> saveLocalIndex(Map<String, dynamic> index) async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final manifestPath = '${cacheDir.path}/$_localDataDirName/manifest.json';
      final file = File(manifestPath);

      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(index));
      print('✅ 本地清单已更新');
    } catch (e) {
      print('❌ 保存本地清单失败: $e');
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
  final String hash;

  RecipeUpdate({
    required this.category,
    required this.recipeId,
    required this.lastModified,
    required this.isNew,
    required this.hash,
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