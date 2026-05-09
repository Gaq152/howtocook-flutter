import 'dart:io';
import 'package:background_downloader/background_downloader.dart'
    hide DownloadTask;
import 'package:background_downloader/background_downloader.dart'
    as bd show DownloadTask;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'app_notification_service.dart';

part 'image_download_manager.g.dart';
part 'image_download_manager.freezed.dart';

enum DownloadStatus {
  idle,
  downloading,
  paused,
  completed,
  error,
}

class DownloadTask {
  final String id;
  final String category;
  final String recipeId;
  final String imageUrl;
  final String localPath;
  final int priority;
  DownloadStatus status;
  int progress;
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

@riverpod
class ImageDownloadManager extends _$ImageDownloadManager {
  static const String _cacheDirName = 'recipe_images';
  static const String _taskGroup = 'howtocook-images';
  static const String _groupNotifId = 'image-batch';

  final Map<String, DownloadTask> _tasks = {};
  bool _isPaused = false;

  @override
  ImageDownloadState build() {
    return const ImageDownloadState(
      status: DownloadStatus.idle,
      totalTasks: 0,
      completedTasks: 0,
      progress: 0,
    );
  }

  /// 配置 background_downloader 组通知：仅 running 状态显示纯文字提示
  static void configureNotifications() {
    FileDownloader().configureNotificationForGroup(
      _taskGroup,
      running: const TaskNotification(
        '正在下载详情图',
        '点击查看下载进度',
      ),
      complete: const TaskNotification(
        '详情图下载完成',
        '',
      ),
      error: const TaskNotification(
        '部分图片下载失败',
        '请在应用内重试',
      ),
      progressBar: false,
      groupNotificationId: _groupNotifId,
    );

    FileDownloader().registerCallbacks(
      group: _taskGroup,
      taskNotificationTapCallback: _onNotificationTap,
    );
  }

  static void _onNotificationTap(
      Task task, NotificationType notificationType) {
    AppNotificationService.instance.handleNotificationTap('data-sync');
  }

  void addDownloadTasks(List<DownloadTask> tasks) {
    for (final task in tasks) {
      _tasks[task.id] = task;
    }

    state = state.copyWith(
      totalTasks: _tasks.length,
      completedTasks: _getCompletedCount(),
    );

    if (!_isPaused) {
      _startBatchDownload();
    }
  }

  Future<void> _startBatchDownload() async {
    final pendingTasks = _tasks.values
        .where((t) =>
            t.status == DownloadStatus.idle ||
            t.status == DownloadStatus.error)
        .toList();

    if (pendingTasks.isEmpty) {
      state = state.copyWith(
        status: DownloadStatus.completed,
        progress: 100,
      );
      return;
    }

    state = state.copyWith(status: DownloadStatus.downloading, progress: 0);
    _isPaused = false;

    final bdTasks = <bd.DownloadTask>[];
    for (final task in pendingTasks) {
      final file = File(task.localPath);
      final dir = file.parent.path;
      final filename = file.uri.pathSegments.last;

      bdTasks.add(bd.DownloadTask(
        url: task.imageUrl,
        filename: filename,
        directory: dir,
        baseDirectory: BaseDirectory.root,
        group: _taskGroup,
        updates: Updates.statusAndProgress,
        retries: 1,
        priority: task.priority,
      ));

      task.status = DownloadStatus.downloading;
    }

    final baseCompleted = _getCompletedCount();

    try {
      final batch = await FileDownloader().downloadBatch(
        bdTasks,
        batchProgressCallback: (succeeded, failed) {
          final completed = succeeded + failed;

          state = state.copyWith(
            completedTasks: baseCompleted + succeeded,
            progress: _tasks.isEmpty
                ? 0
                : ((baseCompleted + completed) / _tasks.length * 100).round(),
          );
        },
        taskStatusCallback: (update) {
          final matchingTask = _findTaskByUrl(update.task.url);
          if (matchingTask == null) return;

          switch (update.status) {
            case TaskStatus.complete:
              matchingTask.status = DownloadStatus.completed;
              matchingTask.progress = 100;
            case TaskStatus.failed:
            case TaskStatus.notFound:
              matchingTask.status = DownloadStatus.error;
              matchingTask.error = update.exception?.description ?? '下载失败';
            case TaskStatus.canceled:
              matchingTask.status = DownloadStatus.paused;
            default:
              break;
          }
        },
      );

      final allCompleted =
          _tasks.values.every((t) => t.status == DownloadStatus.completed);

      state = state.copyWith(
        status: allCompleted ? DownloadStatus.completed : DownloadStatus.error,
        progress: allCompleted ? 100 : state.progress,
        completedTasks: _getCompletedCount(),
        error: batch.numFailed > 0 ? '${batch.numFailed} 张图片下载失败' : null,
      );

      // 下载结束后由 AppNotificationService 发完成通知（可点击跳转）
      if (allCompleted) {
        AppNotificationService.instance.showDownloadComplete(
          total: _getCompletedCount(),
        );
      } else if (batch.numFailed > 0) {
        AppNotificationService.instance.showDownloadComplete(
          total: _getCompletedCount(),
          failed: batch.numFailed,
        );
      }
    } catch (e) {
      debugPrint('❌ 批量下载异常: $e');
      state = state.copyWith(
        status: DownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  DownloadTask? _findTaskByUrl(String url) {
    return _tasks.values.where((t) => t.imageUrl == url).firstOrNull;
  }

  void pauseDownload() async {
    _isPaused = true;
    final activeTasks = await FileDownloader().allTasks(group: _taskGroup);
    if (activeTasks.isNotEmpty) {
      await FileDownloader().cancelTasksWithIds(
        activeTasks.map((t) => t.taskId).toList(),
      );
    }

    for (final task in _tasks.values) {
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.paused;
      }
    }

    state = state.copyWith(status: DownloadStatus.paused);
  }

  void resumeDownload() {
    if (state.status != DownloadStatus.paused) return;

    for (final task in _tasks.values) {
      if (task.status == DownloadStatus.paused) {
        task.status = DownloadStatus.idle;
      }
    }

    _isPaused = false;
    _startBatchDownload();
  }

  void cancelAllDownloads() async {
    _isPaused = true;
    final activeTasks = await FileDownloader().allTasks(group: _taskGroup);
    if (activeTasks.isNotEmpty) {
      await FileDownloader().cancelTasksWithIds(
        activeTasks.map((t) => t.taskId).toList(),
      );
    }

    _tasks.clear();
    state = const ImageDownloadState(
      status: DownloadStatus.idle,
      totalTasks: 0,
      completedTasks: 0,
      progress: 0,
    );
  }

  int _getCompletedCount() {
    return _tasks.values
        .where((t) => t.status == DownloadStatus.completed)
        .length;
  }

  List<DownloadTask> getAllTasks() => _tasks.values.toList();

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
      debugPrint('❌ 计算缓存大小失败: $e');
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/$_cacheDirName');
      if (await imageCacheDir.exists()) {
        await imageCacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('❌ 清理缓存失败: $e');
    }
  }
}

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
