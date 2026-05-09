import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'update_service.dart';

// ── 状态定义 ────────────────────────────────────────────

enum UpdateDownloadStatus { idle, preparing, downloading, done, error }

class UpdateDownloadState {
  const UpdateDownloadState({
    this.status = UpdateDownloadStatus.idle,
    this.progress = 0.0,
    this.info,
    this.currentVersionName = '',
    this.error,
    this.apkPath,
  });

  final UpdateDownloadStatus status;
  final double progress;
  final UpdateInfo? info;
  final String currentVersionName;
  final String? error;
  final String? apkPath;

  bool get isActive =>
      status == UpdateDownloadStatus.downloading ||
      status == UpdateDownloadStatus.preparing;

  UpdateDownloadState copyWith({
    UpdateDownloadStatus? status,
    double? progress,
    UpdateInfo? info,
    String? currentVersionName,
    String? error,
    String? apkPath,
  }) =>
      UpdateDownloadState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        info: info ?? this.info,
        currentVersionName: currentVersionName ?? this.currentVersionName,
        error: error,
        apkPath: apkPath ?? this.apkPath,
      );
}

// ── 底层服务 ────────────────────────────────────────────

class _DownloadService {
  static const String _taskGroup = 'howtocook-update';

  static Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final downloader = FileDownloader();
    await downloader.ready;

    downloader.configureNotificationForGroup(
      _taskGroup,
      running: const TaskNotification(
        '正在下载更新 {filename}',
        '{progress} · {networkSpeed}',
      ),
      complete: const TaskNotification('下载完成', '点击安装新版本'),
      error: const TaskNotification('下载失败', '请在应用内重试'),
      progressBar: true,
    );

    downloader.registerCallbacks(
      group: _taskGroup,
      taskNotificationTapCallback: _onNotificationTap,
    );

    await downloader.trackTasks();
    await downloader.start();
  }

  static void _onNotificationTap(Task task, NotificationType notificationType) async {
    if (notificationType != NotificationType.complete) return;
    try {
      final filePath = await task.filePath();
      if (File(filePath).existsSync()) {
        await InstallPlugin.installApk(filePath, appId: 'com.anlife.howtocook');
      }
    } catch (e) {
      debugPrint('通知栏点击安装失败: $e');
    }
  }

  Future<Directory> _apkDir() async {
    final external = await getExternalStorageDirectory();
    final root = external ?? await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/update');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> resolveApkPath(String version) async {
    final dir = await _apkDir();
    return '${dir.path}/howtocook-v$version.apk';
  }

  Future<bool> isApkAlreadyDownloaded(String version) async {
    final path = await resolveApkPath(version);
    final file = File(path);
    if (!file.existsSync()) return false;
    try {
      return file.lengthSync() > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> cleanupOldApks({String? keepVersion}) async {
    try {
      final dir = await _apkDir();
      final keepName =
          keepVersion != null ? 'howtocook-v$keepVersion.apk' : null;
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith('howtocook-v') || !name.endsWith('.apk')) continue;
        if (keepName != null && name == keepName) continue;
        try {
          entity.deleteSync();
        } catch (e) {
          debugPrint('cleanupOldApks: $name 删除失败: $e');
        }
      }
    } catch (e) {
      debugPrint('cleanupOldApks 异常: $e');
    }
  }

  Future<DownloadTask> buildTask({
    required String version,
    required String url,
    required int mirrorIndex,
  }) async {
    final dir = await _apkDir();
    return DownloadTask(
      taskId: 'howtocook-update-v$version-m$mirrorIndex',
      url: url,
      filename: 'howtocook-v$version.apk',
      baseDirectory: BaseDirectory.root,
      directory: dir.path,
      group: _taskGroup,
      updates: Updates.statusAndProgress,
      retries: 0,
      allowPause: false,
      displayName: 'HowToCook v$version',
    );
  }

  Future<TaskStatusUpdate> runTask(
    DownloadTask task, {
    required void Function(double progress) onProgress,
  }) {
    return FileDownloader().download(
      task,
      onProgress: (progress) {
        onProgress(progress.clamp(0.0, 1.0));
      },
    );
  }

  Future<void> cancelByVersion(String version) async {
    final prefix = 'howtocook-update-v$version';
    try {
      final tasks = await FileDownloader().allTasks(group: _taskGroup);
      final ids = tasks
          .map((t) => t.taskId)
          .where((id) => id.startsWith(prefix))
          .toList();
      if (ids.isNotEmpty) {
        await FileDownloader().cancelTasksWithIds(ids);
      }
    } catch (e) {
      debugPrint('cancelByVersion 异常: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      final tasks = await FileDownloader().allTasks(group: _taskGroup);
      final ids = tasks.map((t) => t.taskId).toList();
      if (ids.isNotEmpty) {
        await FileDownloader().cancelTasksWithIds(ids);
      }
    } catch (e) {
      debugPrint('cancelAll 异常: $e');
    }
  }

  Future<bool> installApk(String filePath) async {
    try {
      await InstallPlugin.installApk(filePath, appId: 'com.anlife.howtocook');
      return true;
    } catch (e) {
      debugPrint('installApk 失败: $e');
      return false;
    }
  }

  Future<bool> ensureInstallPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;
    final result = await Permission.requestInstallPackages.request();
    return result.isGranted;
  }

  Future<bool> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }
}

// ── 状态管理 ────────────────────────────────────────────

class UpdateDownloadNotifier extends StateNotifier<UpdateDownloadState> {
  UpdateDownloadNotifier() : super(const UpdateDownloadState());

  final _service = _DownloadService();

  static Future<void> initialize() => _DownloadService.initialize();

  void setUpdateInfo(UpdateInfo info, String currentVersionName) {
    state = state.copyWith(info: info, currentVersionName: currentVersionName);
  }

  Future<void> startDownload() async {
    final info = state.info;
    if (info == null) return;

    if (await _service.isApkAlreadyDownloaded(info.versionName)) {
      final path = await _service.resolveApkPath(info.versionName);
      state = state.copyWith(
        status: UpdateDownloadStatus.done,
        progress: 1.0,
        apkPath: path,
      );
      return;
    }

    state = state.copyWith(
      status: UpdateDownloadStatus.preparing,
      progress: 0.0,
      error: null,
    );

    await _service.ensureNotificationPermission();
    await _service.cleanupOldApks(keepVersion: info.versionName);

    final resolved = await info.resolveForDevice();
    final mirrors = _buildMirrorList(resolved.url);

    await _tryMirror(info, mirrors, 0);
  }

  Future<void> _tryMirror(
    UpdateInfo info,
    List<String> mirrors,
    int index,
  ) async {
    if (index >= mirrors.length) {
      state = state.copyWith(
        status: UpdateDownloadStatus.error,
        error: '所有下载源均失败',
      );
      return;
    }

    state = state.copyWith(
      status: UpdateDownloadStatus.downloading,
      progress: 0.0,
    );

    DownloadTask task;
    try {
      task = await _service.buildTask(
        version: info.versionName,
        url: mirrors[index],
        mirrorIndex: index,
      );
    } catch (e) {
      debugPrint('buildTask 失败: $e');
      await _tryMirror(info, mirrors, index + 1);
      return;
    }

    TaskStatusUpdate result;
    try {
      result = await _service.runTask(
        task,
        onProgress: (progress) {
          if (state.status == UpdateDownloadStatus.downloading) {
            state = state.copyWith(progress: progress);
          }
        },
      );
    } catch (e) {
      debugPrint('镜像 $index 下载异常: $e');
      await _tryMirror(info, mirrors, index + 1);
      return;
    }

    switch (result.status) {
      case TaskStatus.complete:
        final path = await _service.resolveApkPath(info.versionName);
        if (!File(path).existsSync()) {
          await _tryMirror(info, mirrors, index + 1);
          return;
        }
        state = state.copyWith(
          status: UpdateDownloadStatus.done,
          progress: 1.0,
          apkPath: path,
        );
        return;

      case TaskStatus.canceled:
        return;

      case TaskStatus.failed:
      case TaskStatus.notFound:
        await _tryMirror(info, mirrors, index + 1);
        return;

      default:
        await _tryMirror(info, mirrors, index + 1);
        return;
    }
  }

  Future<bool> install() async {
    final path = state.apkPath;
    if (path == null || state.status != UpdateDownloadStatus.done) return false;

    final granted = await _service.ensureInstallPermission();
    if (!granted) {
      state = state.copyWith(
        status: UpdateDownloadStatus.error,
        error: '需要授予安装权限才能更新',
      );
      return false;
    }

    return _service.installApk(path);
  }

  void cancel() {
    final info = state.info;
    if (info != null) {
      _service.cancelByVersion(info.versionName);
    }
    state = const UpdateDownloadState();
  }

  void dismiss() {
    if (state.status == UpdateDownloadStatus.done ||
        state.status == UpdateDownloadStatus.error) {
      state = const UpdateDownloadState();
    }
  }

  List<String> _buildMirrorList(String url) {
    if (!url.contains('github.com')) return [url];
    final mirrored = url.replaceFirst(
      'https://github.com',
      'https://ghfast.top/https://github.com',
    );
    return [mirrored, url];
  }
}

// ── Provider ────────────────────────────────────────────

final updateDownloadNotifierProvider =
    StateNotifierProvider<UpdateDownloadNotifier, UpdateDownloadState>(
  (ref) => UpdateDownloadNotifier(),
);
