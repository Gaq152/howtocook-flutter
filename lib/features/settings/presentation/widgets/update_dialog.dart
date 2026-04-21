import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/update_download_service.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/theme/app_colors.dart';

/// 显示更新对话框（复用 [UpdateDownloadNotifier] 状态）。
Future<void> showUpdateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required UpdateInfo info,
  required String currentVersionName,
}) async {
  final notifier = ref.read(updateDownloadNotifierProvider.notifier);
  notifier.setUpdateInfo(info, currentVersionName);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _UpdateDialog(),
  );
}

class _UpdateDialog extends ConsumerWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateDownloadNotifierProvider);
    final notifier = ref.read(updateDownloadNotifierProvider.notifier);
    final info = state.info;
    if (info == null) return const SizedBox.shrink();

    final sizeMB = info.size > 0 ? (info.size / 1024 / 1024).toStringAsFixed(1) : '--';
    final isDownloading = state.status == UpdateDownloadStatus.downloading;
    final isPaused = state.status == UpdateDownloadStatus.paused;
    final isDone = state.status == UpdateDownloadStatus.done;
    final isError = state.status == UpdateDownloadStatus.error;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('发现新版本 ${info.versionName}')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本：${state.currentVersionName}', style: _dimStyle(context)),
            Text('安装包大小：约 $sizeMB MB', style: _dimStyle(context)),
            const SizedBox(height: 12),
            if (info.notes.trim().isNotEmpty) ...[
              const Text('更新内容', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: MarkdownBody(
                      data: info.notes.trim(),
                      selectable: true,
                      shrinkWrap: true,
                      onTapLink: (text, href, title) {
                        if (href == null) return;
                        final uri = Uri.tryParse(href);
                        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isDownloading || isPaused) ...[
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 6),
              Text(
                isPaused
                    ? '已暂停 ${(state.progress * 100).toStringAsFixed(0)}%'
                    : '下载中 ${(state.progress * 100).toStringAsFixed(0)}%',
                style: _dimStyle(context),
              ),
            ],
            if (isDone)
              Text('下载完成，正在安装…', style: _dimStyle(context)),
            if (isError) ...[
              const SizedBox(height: 8),
              Text('下载失败：${state.error}',
                  style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        if (!isDownloading && !isPaused && !isDone)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        if (isDownloading)
          TextButton(
            onPressed: notifier.pause,
            child: const Text('暂停'),
          ),
        if (isPaused)
          TextButton(
            onPressed: notifier.cancel,
            child: const Text('取消'),
          ),
        if (isDownloading || isPaused)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('后台下载'),
          ),
        if (!isDownloading && !isDone)
          FilledButton(
            onPressed: isPaused ? notifier.resume : notifier.startDownload,
            child: Text(isPaused ? '继续' : '立即更新'),
          ),
        if (isDone)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        if (isError)
          FilledButton(
            onPressed: notifier.startDownload,
            child: const Text('重试'),
          ),
      ],
    );
  }

  TextStyle? _dimStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);
}
