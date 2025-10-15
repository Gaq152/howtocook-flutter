import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
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
      print('\n🔍 检查本地���引文件...');
      final localIndex = await loadLocalIndex();

      // 调试：检查本地索引是否为空
      if (localIndex == null || localIndex.isEmpty) {
        print('⚠️  本地索引为空，可能是首次同步或数据丢失');
      } else {
        print('✅ 本地索引加载成功，开始比对...');
      }

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
      print('\n💾 保存更新后的本地索引...');
      await saveLocalIndex(remoteIndex);
      print('✅ 本地索引保存完成');

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

        final data = jsonDecode(responseData) as Map<String, dynamic>;

        print('✅ 远程清单下载成功:');
        print('   - 版本: ${data['version']}');
        print('   - 生成时间: ${data['generatedAt']}');
        print('   - 总食谱数: ${data['totalRecipes']}');
        print('   - 实际食谱数组长度: ${(data['recipes'] as List<dynamic>?)?.length ?? 0}');

        if (data['recipes'] is List && (data['recipes'] as List).isNotEmpty) {
          final firstRecipe = (data['recipes'] as List)[0];
          if (firstRecipe is Map) {
            print('   - 示例食谱结构: ${firstRecipe.keys.toList()}');
            print('   - 示例食谱: ${firstRecipe['name']} (${firstRecipe['id']})');
          }
        }

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
      // 1. 首先尝试从文档目录读取已下载的索引
      final localData = await _loadFromDocumentsDirectory();
      if (localData != null) {
        print('✅ 从文档目录加载本地索引成功');
        return localData;
      }

      // 2. 如果文档目录没有，则从assets中读取预置数据
      print('📦 文档目录无数据，尝试从assets加载预置索引...');
      final assetsData = await _loadFromAssets();
      if (assetsData != null) {
        print('✅ 从assets加载预置索引成功');
        return assetsData;
      }

      // 3. 如果都没有，返回空索引
      print('⚠️  未找到任何本地索引数据');
      return {};
    } catch (e) {
      print('❌ 加载本地清单失败: $e');
      print('   - 错误类型: ${e.runtimeType}');
      return {};
    }
  }

  /// 从文档目录加载索引
  Future<Map<String, dynamic>?> _loadFromDocumentsDirectory() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${cacheDir.path}/$_localDataDirName');
      final manifestPath = '${cacheDir.path}/$_localDataDirName/manifest.json';
      final file = File(manifestPath);

      print('📁 尝试从文档目录加载索引: $manifestPath');

      // 检查数据目录是否存在
      if (!await dataDir.exists()) {
        print('   - ❌ 数据目录不存在');
        return null;
      }
      print('   - ✅ 数据目录存在');

      // 检查清单文件是否存在
      if (!await file.exists()) {
        print('   - ❌ 清单文件不存在');
        return null;
      }
      print('   - ✅ 清单文件存在');

      // 检查文件大小
      final fileSize = await file.length();
      print('   - 文件大小: $fileSize 字节');

      if (fileSize == 0) {
        print('   - ❌ 文件为空');
        return null;
      }

      final content = await file.readAsString();
      print('   - 文件内容长度: ${content.length} 字符');

      if (content.isEmpty) {
        print('   - ❌ 文件内容为空');
        return null;
      }

      final data = jsonDecode(content) as Map<String, dynamic>;

      print('✅ 文档目录索引加载成功:');
      print('   - 版本: ${data['version']}');
      print('   - 生成时间: ${data['generatedAt']}');
      print('   - 总食谱数: ${data['totalRecipes']}');
      print('   - 实际食谱数组长度: ${(data['recipes'] as List<dynamic>?)?.length ?? 0}');

      return data;
    } catch (e) {
      print('❌ 从文档目录加载索引失败: $e');
      return null;
    }
  }

  /// 从assets加载预置索引
  Future<Map<String, dynamic>?> _loadFromAssets() async {
    try {
      print('📦 尝试从assets加载预置索引...');

      final String manifestContent = await rootBundle.loadString('assets/manifest.json');

      if (manifestContent.isEmpty) {
        print('   - ❌ assets中的manifest.json为空');
        return null;
      }

      print('   - ✅ assets文件读取成功，内容长度: ${manifestContent.length} 字符');

      final data = jsonDecode(manifestContent) as Map<String, dynamic>;

      print('✅ assets索引解析成功:');
      print('   - 版本: ${data['version']}');
      print('   - 生成时间: ${data['generatedAt']}');
      print('   - 总食谱数: ${data['totalRecipes']}');
      print('   - 实际食谱数组长度: ${(data['recipes'] as List<dynamic>?)?.length ?? 0}');

      if (data['recipes'] is List && (data['recipes'] as List).isNotEmpty) {
        final firstRecipe = (data['recipes'] as List)[0];
        if (firstRecipe is Map) {
          print('   - 示例食谱: ${firstRecipe['name']} (${firstRecipe['id']})');
        }
      }

      return data;
    } catch (e) {
      print('❌ 从assets加载索引失败: $e');
      print('   - 错误类型: ${e.runtimeType}');
      return null;
    }
  }

  /// 识别需要更新的食谱
  List<RecipeUpdate> identifyUpdates(
    Map<String, dynamic>? localIndex,
    Map<String, dynamic> remoteIndex,
  ) {
    print('🔍 开始分析需要更新的食谱...');

    final updates = <RecipeUpdate>[];
    final remoteRecipes = remoteIndex['recipes'] as List<dynamic>? ?? [];

    // 本地索引格式：{recipes: []}
    final localRecipes = localIndex?['recipes'] as List<dynamic>? ?? [];

    print('📊 数据统计:');
    print('   - 远程食谱数量: ${remoteRecipes.length}');
    print('   - 本地食谱数量: ${localRecipes.length}');

    // 创建本地食谱的映射表以便快速查找
    final localRecipeMap = <String, Map<String, dynamic>>{};
    print('\n📋 构建本地食谱映射表:');
    for (final recipe in localRecipes) {
      final recipeId = recipe['id'] as String;
      final recipeName = recipe['name'] as String? ?? '未知';
      final recipeHash = recipe['hash'] as String? ?? '无hash';
      localRecipeMap[recipeId] = recipe as Map<String, dynamic>;
      print('   - $recipeId ($recipeName): $recipeHash');
    }

    print('\n🌐 开始比对食谱...');
    int newCount = 0;
    int updateCount = 0;
    int unchangedCount = 0;
    int sampleCount = 0; // 只显示前3个示例

    for (int i = 0; i < remoteRecipes.length; i++) {
      final remoteRecipe = remoteRecipes[i];
      final recipeId = remoteRecipe['id'] as String;
      final recipeName = remoteRecipe['name'] as String? ?? '未知';
      final category = remoteRecipe['category'] as String;
      final recipeHash = remoteRecipe['hash'] as String;

      final localRecipe = localRecipeMap[recipeId];

      if (localRecipe == null) {
        if (sampleCount < 3) {
          print('   - 示例$sampleCount: $recipeName ($recipeId) - ❌ 不存在 (新增)');
          sampleCount++;
        }
        updates.add(RecipeUpdate(
          category: category,
          recipeId: recipeId,
          lastModified: remoteRecipe['generatedAt'] as String? ?? '',
          isNew: true,
          hash: recipeHash,
        ));
        newCount++;
      } else {
        final localHash = localRecipe['hash'] as String? ?? '无hash';

        if (localHash != recipeHash) {
          if (sampleCount < 3) {
            print('   - 示例$sampleCount: $recipeName ($recipeId) - 🔄 hash不匹配 (更新)');
            print('     本地hash: $localHash');
            print('     远程hash: $recipeHash');
            sampleCount++;
          }
          updates.add(RecipeUpdate(
            category: category,
            recipeId: recipeId,
            lastModified: remoteRecipe['generatedAt'] as String? ?? '',
            isNew: false,
            hash: recipeHash,
          ));
          updateCount++;
        } else {
          unchangedCount++;
        }
      }
    }

    if (newCount > 3) {
      print('   - ... 还有 ${newCount - 3} 个新增食谱');
    }
    if (updateCount > 3) {
      print('   - ... 还有 ${updateCount - 3} 个更新食谱');
    }

    print('\n📈 比对结果汇总:');
    print('   - 新增食谱: $newCount 个');
    print('   - 更新食谱: $updateCount 个');
    print('   - 无需更新: $unchangedCount 个');
    print('   - 总计需要处理: ${updates.length} 个');

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

  /// 从assets中的食谱JSON提取详情图下载任务
  Future<List<DownloadTask>> extractDetailImageTasksFromAssets(RecipeUpdate update) async {
    final tasks = <DownloadTask>[];

    try {
      // 从assets读取JSON文件，路径格式：assets/recipes/{category}/{recipeId}.json
      final assetPath = 'assets/recipes/${update.category}/${update.recipeId}.json';

      String content;
      try {
        content = await rootBundle.loadString(assetPath);
      } catch (e) {
        // Assets中没有该文件，跳过
        return tasks;
      }

      final recipeData = jsonDecode(content);
      final images = recipeData['images'] as List<dynamic>? ?? [];

      if (images.isEmpty) {
        return tasks;
      }

      final cacheDir = await getApplicationDocumentsDirectory();

      for (int i = 0; i < images.length; i++) {
        // 详情图按ID存储：images/{category}/{recipeId}_$i.webp
        final imageUrl = '$_remoteBaseUrl/images/${update.category}/${update.recipeId}_$i.webp';
        final localPath = '${cacheDir.path}/recipe_images/details/${update.category}/${update.recipeId}_$i.webp';

        tasks.add(DownloadTask(
          id: 'detail_${update.category}_${update.recipeId}_$i',
          category: update.category,
          recipeId: update.recipeId,
          imageUrl: imageUrl,
          localPath: localPath,
          priority: 1,
        ));
      }

      return tasks;
    } catch (e) {
      print('❌ 从Assets提取详情图任务失败: ${update.category}/${update.recipeId}, 错误: $e');
      return tasks;
    }
  }

  /// 从文档目录的食谱JSON中提取详情图下载任务（按ID）
  Future<List<DownloadTask>> extractDetailImageTasks(RecipeUpdate update) async {
    final tasks = <DownloadTask>[];

    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      // 修复：recipeId已经包含了category前缀，不需要再拼接
      final jsonPath = '${cacheDir.path}/$_localDataDirName/recipes/${update.category}/${update.recipeId}.json';
      final file = File(jsonPath);

      if (!await file.exists()) {
        print('!  JSON文件不存在，跳过详情图提取: $jsonPath');
        return tasks;
      }

      final content = await file.readAsString();
      final recipeData = jsonDecode(content);
      final images = recipeData['images'] as List<dynamic>? ?? [];

      if (images.isEmpty) {
        return tasks;
      }

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
      final dataDir = Directory('${cacheDir.path}/$_localDataDirName');
      final manifestPath = '${cacheDir.path}/$_localDataDirName/manifest.json';
      final file = File(manifestPath);

      print('💾 保存本地索引文件:');
      print('   - 缓存目录: ${cacheDir.path}');
      print('   - 数据目录: ${dataDir.path}');
      print('   - 清单路径: $manifestPath');

      // 创建目录
      await file.parent.create(recursive: true);
      print('   - ✅ 目录创建完成');

      // 检查索引数据
      final recipeCount = (index['recipes'] as List<dynamic>?)?.length ?? 0;
      print('   - 索引包含食谱数量: $recipeCount');

      // 写入文件
      final jsonContent = jsonEncode(index);
      print('   - JSON内容长度: ${jsonContent.length} 字符');

      await file.writeAsString(jsonContent);

      // 验证写入结果
      final writtenSize = await file.length();
      print('   - 写入文件大小: $writtenSize 字节');
      print('   - ✅ 本地清单保存完成');

    } catch (e) {
      print('❌ 保存本地清单失败: $e');
      print('   - 错误类型: ${e.runtimeType}');
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