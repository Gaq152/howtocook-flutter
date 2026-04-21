import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'update_service.dart';

part 'update_download_service.g.dart';

enum UpdateDownloadStatus { idle, downloading, paused, done, error }

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
      status == UpdateDownloadStatus.paused;

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

const _kNotifChannelId = 'update_download';
const _kNotifId = 1001;

@riverpod
class UpdateDownloadNotifier extends _$UpdateDownloadNotifier {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _notifInitialized = false;

  CancelToken? _cancelToken;
  bool _paused = false;

  @override
  UpdateDownloadState build() => const UpdateDownloadState();

  /// 初始化通知（仅 Android，调用一次）
  static Future<void> initNotifications() async {
    if (_notifInitialized || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(const InitializationSettings(android: android));
    const channel = AndroidNotificationChannel(
      _kNotifChannelId,
      '应用更新',
      description: '显示应用更新下载进度',
      importance: Importance.low,
      showBadge: false,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    _notifInitialized = true;
  }

  void setUpdateInfo(UpdateInfo info, String currentVersionName) {
    state = state.copyWith(info: info, currentVersionName: currentVersionName);
  }

  Future<void> startDownload() async {
    final info = state.info;
    if (info == null) return;
    _paused = false;
    _cancelToken = CancelToken();
    state = state.copyWith(
      status: UpdateDownloadStatus.downloading,
      progress: 0.0,
      error: null,
    );

    try {
      final service = ref.read(updateServiceProvider);
      final path = await service.downloadUpdate(
        info,
        cancelToken: _cancelToken,
        onProgress: (p) {
          if (_paused) return;
          state = state.copyWith(progress: p);
          _showProgressNotification(p);
        },
      );
      await _cancelNotification();
      state = state.copyWith(
        status: UpdateDownloadStatus.done,
        progress: 1.0,
        apkPath: path,
      );
      _showDoneNotification();
      // 自动触发安装
      await service.installApk(path);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // 暂停或取消，状态已在 pause/cancel 中设置
      } else {
        await _cancelNotification();
        state = state.copyWith(
          status: UpdateDownloadStatus.error,
          error: e.message,
        );
      }
    } catch (e) {
      await _cancelNotification();
      state = state.copyWith(
        status: UpdateDownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  void pause() {
    if (state.status != UpdateDownloadStatus.downloading) return;
    _paused = true;
    _cancelToken?.cancel('paused');
    _cancelToken = null;
    state = state.copyWith(status: UpdateDownloadStatus.paused);
    _showPausedNotification();
  }

  Future<void> resume() async {
    if (state.status != UpdateDownloadStatus.paused) return;
    await startDownload();
  }

  void cancel() {
    _cancelToken?.cancel('cancelled');
    _cancelToken = null;
    _cancelNotification();
    state = const UpdateDownloadState();
  }

  void dismiss() {
    if (state.status == UpdateDownloadStatus.done ||
        state.status == UpdateDownloadStatus.error) {
      state = const UpdateDownloadState();
    }
  }

  // ── 通知辅助 ──────────────────────────────────────────

  void _showProgressNotification(double progress) {
    if (kIsWeb || !Platform.isAndroid) return;
    final percent = (progress * 100).round();
    _notifications.show(
      _kNotifId,
      '正在下载更新',
      '${state.info?.versionName ?? ''} — $percent%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kNotifChannelId,
          '应用更新',
          channelDescription: '显示应用更新下载进度',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: percent,
          ongoing: true,
          autoCancel: false,
          actions: [
            const AndroidNotificationAction('pause', '暂停'),
            const AndroidNotificationAction('cancel', '取消'),
          ],
        ),
      ),
    );
  }

  void _showPausedNotification() {
    if (kIsWeb || !Platform.isAndroid) return;
    _notifications.show(
      _kNotifId,
      '下载已暂停',
      state.info?.versionName ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kNotifChannelId,
          '应用更新',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          actions: [
            const AndroidNotificationAction('resume', '继续'),
            const AndroidNotificationAction('cancel', '取消'),
          ],
        ),
      ),
    );
  }

  void _showDoneNotification() {
    if (kIsWeb || !Platform.isAndroid) return;
    _notifications.show(
      _kNotifId,
      '下载完成',
      '点击安装 ${state.info?.versionName ?? ''}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kNotifChannelId,
          '应用更新',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
        ),
      ),
    );
  }

  Future<void> _cancelNotification() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _notifications.cancel(_kNotifId);
  }
}
