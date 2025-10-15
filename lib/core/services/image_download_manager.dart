import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_download_manager.g.dart';
part 'image_download_manager.freezed.dart';

/// 下载状态枚举
enum DownloadStatus {
  idle,          // 空闲
  downloading,   // 下载中
  paused,        // 已暂停
  completed,     // 已完成
  error,         // 出错
}

/// 下载任务信息
class DownloadTask {
  final String id;
  final String category;
  final String recipeId;
  final String imageUrl;
  final String localPath;
  final int priority; // 优先级，数字越小优先级越高
  DownloadStatus status;
  int progress; // 下载进度 0-100
  String? error;

  DownloadTask({
    required this.id,
    required this.category,
    required this.recipeId,
    required this.imageUrl,
    required this.localPath,
    this.priority = 0,
    this.status = DownloadStatus.idle,
    this.progress = 0,
    this.error,
  });
}

/// 图片下载管理器
@riverpod
class ImageDownloadManager extends _$ImageDownloadManager {
  static const String _baseUrl = 'https://username.github.io/recipe-images';
  static const String _cacheDirName = 'recipe_images';

  final Dio _dio = Dio();
  final Map<String, DownloadTask> _tasks = {};
  final Map<String, CancelToken> _cancelTokens = {};
  bool _isDownloading = false;
  int _currentIndex = 0;

  @override
  ImageDownloadState build() {
    return const ImageDownloadState(
      status: DownloadStatus.idle,
      totalTasks: 0,
      completedTasks: 0,
      progress: 0,
    );
  }

  /// 添加下载任务
  void addDownloadTasks(List<DownloadTask> tasks) {
    print('📋 添加下载任务: ${tasks.length} 个');

    for (final task in tasks) {
      _tasks[task.id] = task;
      print('   - ${task.id}: ${task.imageUrl}');
    }

    // 按优先级排序
    final sortedTasks = _tasks.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    _tasks.clear();
    for (final task in sortedTasks) {
      _tasks[task.id] = task;
    }

    print('🎯 总下载任务数: ${_tasks.length}');

    state = state.copyWith(
      totalTasks: _tasks.length,
      completedTasks: _getCompletedCount(),
    );

    // 如果没有正在下载，开始下载
    if (!_isDownloading) {
      print('🚀 开始下载...');
      _startDownload();
    }
  }

  /// 开始下载
  void _startDownload() async {
    if (_tasks.isEmpty || _isDownloading) return;

    _isDownloading = true;
    _currentIndex = 0;

    state = state.copyWith(status: DownloadStatus.downloading);

    while (_currentIndex < _tasks.length) {
      // 检查是否应该停止下载
      if (!_isDownloading) {
        print('⏸️ 下载已被暂停或取消');
        break;
      }

      final task = _tasks.values.elementAt(_currentIndex);

      if (task.status == DownloadStatus.completed) {
        _currentIndex++;
        continue;
      }

      if (task.status == DownloadStatus.paused) {
        break;
      }

      await _downloadSingleTask(task);
      _currentIndex++;

      // 更新整体进度
      state = state.copyWith(
        completedTasks: _getCompletedCount(),
        progress: ((_currentIndex) / _tasks.length * 100).round(),
      );
    }

    _isDownloading = false;

    // 只有在真正完成所有任务时才标记为completed
    if (_currentIndex >= _tasks.length) {
      state = state.copyWith(
        status: DownloadStatus.completed,
        progress: 100,
      );
    }
  }

  /// 下载单个任务
  Future<void> _downloadSingleTask(DownloadTask task) async {
    // 在开始下载前检查是否应该继续
    if (!_isDownloading) {
      print('⏸️ 任务 ${task.id} 被跳过（下载已停止）');
      return;
    }

    task.status = DownloadStatus.downloading;
    task.progress = 0;
    task.error = null;

    print('📥 开始下载图片:');
    print('   - ID: ${task.id}');
    print('   - 分类: ${task.category}');
    print('   - 食谱ID: ${task.recipeId}');
    print('   - URL: ${task.imageUrl}');
    print('   - 本地路径: ${task.localPath}');

    state = state.copyWith(); // 触发状态更新

    try {
      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      // 创建本地目录
      final file = File(task.localPath);
      await file.parent.create(recursive: true);
      print('   - 目录已创建: ${file.parent.path}');

      // 下载文件
      await _dio.download(
        task.imageUrl,
        task.localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            task.progress = (received / total * 100).round();
            state = state.copyWith(); // 触发状态更新
          }
        },
        options: Options(
          receiveTimeout: Duration(seconds: 30),
        ),
      );

      task.status = DownloadStatus.completed;
      task.progress = 100;

      // 验证文件是否真的存在
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;

      print('✅ 图片下载完成:');
      print('   - 路径: ${task.localPath}');
      print('   - 文件存在: $exists');
      print('   - 文件大小: $fileSize 字节');

    } on DioException catch (e) {
      // 如果是取消操作，不标记为错误
      if (e.type == DioExceptionType.cancel) {
        print('⏸️ 图片下载被取消: ${task.imageUrl}');
        task.status = DownloadStatus.paused;
      } else {
        task.status = DownloadStatus.error;
        task.error = e.toString();
        print('❌ 图片下载失败:');
        print('   - URL: ${task.imageUrl}');
        print('   - 错误: $e');
      }
    } catch (e) {
      task.status = DownloadStatus.error;
      task.error = e.toString();
      print('❌ 图片下载失败:');
      print('   - URL: ${task.imageUrl}');
      print('   - 错误: $e');
    }

    _cancelTokens.remove(task.id);
    state = state.copyWith(); // 触发状态更新
  }

  /// 暂停下载
  void pauseDownload() {
    print('⏸️ 暂停下载请求...');
    print('   - 当前正在下载的任务数: ${_cancelTokens.length}');

    // 先设置标志，防止新任务开始
    _isDownloading = false;

    // 取消当前正在下载的任务
    for (final cancelToken in _cancelTokens.values) {
      cancelToken.cancel();
    }
    _cancelTokens.clear();

    // 标记当前任务为暂停状态
    if (_currentIndex < _tasks.length) {
      final currentTask = _tasks.values.elementAt(_currentIndex);
      currentTask.status = DownloadStatus.paused;
      print('   - 当前任务已标记为暂停: ${currentTask.id}');
    }

    state = state.copyWith(status: DownloadStatus.paused);
    print('✅ 下载已暂停');
  }

  /// 恢复下载
  void resumeDownload() {
    if (state.status == DownloadStatus.paused) {
      _startDownload();
    }
  }

  /// 取消所有下载
  void cancelAllDownloads() {
    pauseDownload();
    _tasks.clear();
    _currentIndex = 0;

    state = const ImageDownloadState(
      status: DownloadStatus.idle,
      totalTasks: 0,
      completedTasks: 0,
      progress: 0,
    );
  }

  /// 获取已完成任务数量
  int _getCompletedCount() {
    return _tasks.values.where((task) => task.status == DownloadStatus.completed).length;
  }

  /// 获取所有任务状态
  List<DownloadTask> getAllTasks() {
    return _tasks.values.toList();
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
}

/// 图片下载状态
@freezed
class ImageDownloadState with _$ImageDownloadState {
  const factory ImageDownloadState({
    required DownloadStatus status,
    required int totalTasks,
    required int completedTasks,
    required int progress,
    String? error,
  }) = _ImageDownloadState;
}