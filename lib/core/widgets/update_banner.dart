import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/update_download_service.dart';
import '../theme/app_colors.dart';
import '../../features/settings/presentation/widgets/update_dialog.dart';

/// 全局更新横幅，嵌入 [MainScaffold] 顶部。
/// 仅在下载进行中或暂停时显示。
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateDownloadNotifierProvider);
    if (!state.isActive) return const SizedBox.shrink();

    final notifier = ref.read(updateDownloadNotifierProvider.notifier);
    final isPaused = state.status == UpdateDownloadStatus.paused;
    final percent = (state.progress * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _openDialog(context, ref, state),
      child: Material(
        color: colorScheme.primaryContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isPaused ? Icons.pause_circle_outline : Icons.download_outlined,
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPaused
                          ? '下载已暂停 $percent% — 点击查看'
                          : '正在下载更新 $percent% — 点击查看',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  if (isPaused)
                    _BannerIconButton(
                      icon: Icons.play_arrow,
                      tooltip: '继续',
                      color: colorScheme.onPrimaryContainer,
                      onPressed: notifier.resume,
                    )
                  else
                    _BannerIconButton(
                      icon: Icons.pause,
                      tooltip: '暂停',
                      color: colorScheme.onPrimaryContainer,
                      onPressed: notifier.pause,
                    ),
                  _BannerIconButton(
                    icon: Icons.close,
                    tooltip: '取消',
                    color: colorScheme.onPrimaryContainer,
                    onPressed: notifier.cancel,
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: isPaused ? state.progress : state.progress,
              minHeight: 3,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.warning : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDialog(BuildContext context, WidgetRef ref, UpdateDownloadState state) {
    final info = state.info;
    if (info == null) return;
    showUpdateDialog(
      context: context,
      ref: ref,
      info: info,
      currentVersionName: state.currentVersionName,
    );
  }
}

class _BannerIconButton extends StatelessWidget {
  const _BannerIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }
}
