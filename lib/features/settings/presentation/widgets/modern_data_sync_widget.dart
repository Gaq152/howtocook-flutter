import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:howtocook/features/settings/domain/models/sync_item_state.dart';
import 'package:howtocook/core/services/data_sync_service.dart';
import 'package:howtocook/core/services/image_download_manager.dart';

/// 现代化数据同步控制组件
class ModernDataSyncWidget extends ConsumerStatefulWidget {
  const ModernDataSyncWidget({super.key});

  @override
  ConsumerState<ModernDataSyncWidget> createState() => _ModernDataSyncWidgetState();
}

class _ModernDataSyncWidgetState extends ConsumerState<ModernDataSyncWidget> {
  // 各项同步状态
  final Map<SyncItemType, SyncItemState> _itemStates = {
    SyncItemType.json: SyncItemState.initial(SyncItemType.json),
    SyncItemType.coverImages: SyncItemState.initial(SyncItemType.coverImages),
    SyncItemType.detailImages: SyncItemState.initial(SyncItemType.detailImages),
  };

  // 缓存更新信息
  List<RecipeUpdate>? _pendingUpdates;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标题卡片
        _buildHeaderCard(context),
        const SizedBox(height: 16),

        // 同步项列表
        ...SyncItemInfo.items.map((info) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSyncItemCard(context, info),
            )),

        const SizedBox(height: 16),

        // 存储信息
        _buildStorageCard(context),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cloud_sync,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '数据同步',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '同步食谱数据和图片到本地',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncItemCard(BuildContext context, SyncItemInfo info) {
    final state = _itemStates[info.type]!;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                // 图标
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(state.status, theme).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    info.icon,
                    size: 24,
                    color: _getStatusColor(state.status, theme),
                  ),
                ),
                const SizedBox(width: 12),

                // 标题和描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // 操作按钮
                _buildActionButton(context, info.type, state),
              ],
            ),

            // 进度条（下载时显示）
            if (state.status == SyncItemStatus.downloading || state.status == SyncItemStatus.paused)
              _buildProgressSection(context, state),

            // 状态消息
            if (state.message != null) _buildStatusMessage(context, state),

            // 错误信息
            if (state.error != null) _buildErrorMessage(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, SyncItemType type, SyncItemState state) {
    final theme = Theme.of(context);

    switch (state.status) {
      case SyncItemStatus.idle:
        return FilledButton.tonalIcon(
          onPressed: () => _handleCheckUpdate(type),
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('更新'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );

      case SyncItemStatus.checking:
        return SizedBox(
          width: 90,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );

      case SyncItemStatus.updateAvailable:
        return FilledButton.icon(
          onPressed: () => _handleStartDownload(type),
          icon: const Icon(Icons.download, size: 20),
          label: const Text('下载'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );

      case SyncItemStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _handlePauseDownload(type),
              icon: const Icon(Icons.pause, size: 20),
              label: const Text('暂停'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _handleCancelDownload(type),
              icon: const Icon(Icons.close, size: 20),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        );

      case SyncItemStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => _handleResumeDownload(type),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('继续'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _handleCancelDownload(type),
              icon: const Icon(Icons.close, size: 20),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        );

      case SyncItemStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '已完成',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case SyncItemStatus.error:
        return FilledButton.tonalIcon(
          onPressed: () => _handleCheckUpdate(type),
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('重试'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
        );
    }
  }

  Widget _buildProgressSection(BuildContext context, SyncItemState state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.totalItems > 0 ? state.completedItems / state.totalItems : 0.0,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.status == SyncItemStatus.paused
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${state.completedItems}/${state.totalItems}项',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(BuildContext context, SyncItemState state) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(state.status, theme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(state.status),
            size: 16,
            color: _getStatusColor(state.status, theme),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(state.status, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, SyncItemState state) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.storage,
                size: 24,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本地存储',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '已使用: 计算中...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _handleClearCache,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('清理'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SyncItemStatus status, ThemeData theme) {
    switch (status) {
      case SyncItemStatus.idle:
        return theme.colorScheme.onSurfaceVariant;
      case SyncItemStatus.checking:
        return theme.colorScheme.tertiary;
      case SyncItemStatus.updateAvailable:
        return theme.colorScheme.secondary;
      case SyncItemStatus.downloading:
        return theme.colorScheme.primary;
      case SyncItemStatus.paused:
        return theme.colorScheme.tertiary;
      case SyncItemStatus.completed:
        return theme.colorScheme.primary;
      case SyncItemStatus.error:
        return theme.colorScheme.error;
    }
  }

  IconData _getStatusIcon(SyncItemStatus status) {
    switch (status) {
      case SyncItemStatus.idle:
        return Icons.info_outline;
      case SyncItemStatus.checking:
        return Icons.sync;
      case SyncItemStatus.updateAvailable:
        return Icons.cloud_download;
      case SyncItemStatus.downloading:
        return Icons.downloading;
      case SyncItemStatus.paused:
        return Icons.pause_circle_outline;
      case SyncItemStatus.completed:
        return Icons.check_circle;
      case SyncItemStatus.error:
        return Icons.error_outline;
    }
  }

  // 事件处理方法
  void _handleCheckUpdate(SyncItemType type) async {
    setState(() {
      _itemStates[type] = _itemStates[type]!.copyWith(
        status: SyncItemStatus.checking,
        message: '正在检查更新...',
      );
    });

    try {
      final dataSyncService = ref.read(dataSyncServiceProvider.notifier);

      if (type == SyncItemType.json) {
        // 检查JSON数据更新
        final remoteIndex = await dataSyncService.downloadRemoteIndex();
        final localIndex = await dataSyncService.loadLocalIndex();

        if (remoteIndex != null) {
          final updates = dataSyncService.identifyUpdates(localIndex, remoteIndex);

          setState(() {
            _pendingUpdates = updates;
            _itemStates[type] = _itemStates[type]!.copyWith(
              status: updates.isNotEmpty ? SyncItemStatus.updateAvailable : SyncItemStatus.idle,
              message: updates.isNotEmpty
                ? '发现 ${updates.length} 个食谱更新'
                : '已是最新版本',
              totalItems: updates.length,
            );

            // 如果有JSON更新，同时标记图片可能有更新
            if (updates.isNotEmpty) {
              _itemStates[SyncItemType.coverImages] = _itemStates[SyncItemType.coverImages]!.copyWith(
                status: SyncItemStatus.updateAvailable,
                message: '封面图可能需要更新',
                totalItems: updates.length,
              );
              _itemStates[SyncItemType.detailImages] = _itemStates[SyncItemType.detailImages]!.copyWith(
                status: SyncItemStatus.updateAvailable,
                message: '详情图可能需要更新',
                totalItems: updates.length * 2, // 估算
              );
            }
          });
        } else {
          setState(() {
            _itemStates[type] = _itemStates[type]!.copyWith(
              status: SyncItemStatus.error,
              error: '无法检查更新，请检查网络连接',
            );
          });
        }
      } else {
        // 对于图片类型，基于JSON更新状态
        final jsonState = _itemStates[SyncItemType.json];
        if (jsonState?.status == SyncItemStatus.updateAvailable && _pendingUpdates != null) {
          setState(() {
            _itemStates[type] = _itemStates[type]!.copyWith(
              status: SyncItemStatus.updateAvailable,
              message: '图片可以下载',
              totalItems: type == SyncItemType.coverImages
                ? _pendingUpdates!.length
                : _pendingUpdates!.length * 2,
            );
          });
        } else {
          setState(() {
            _itemStates[type] = _itemStates[type]!.copyWith(
              status: SyncItemStatus.idle,
              message: '请先检查JSON数据更新',
            );
          });
        }
      }
    } catch (e) {
      setState(() {
        _itemStates[type] = _itemStates[type]!.copyWith(
          status: SyncItemStatus.error,
          error: '检查更新失败: $e',
        );
      });
    }
  }

  void _handleStartDownload(SyncItemType type) async {
    if (_pendingUpdates == null || _pendingUpdates!.isEmpty) {
      setState(() {
        _itemStates[type] = _itemStates[type]!.copyWith(
          status: SyncItemStatus.error,
          error: '没有待下载的更新',
        );
      });
      return;
    }

    setState(() {
      _itemStates[type] = _itemStates[type]!.copyWith(
        status: SyncItemStatus.downloading,
        progress: 0,
        completedItems: 0,
        message: '正在下载...',
      );
    });

    try {
      final dataSyncService = ref.read(dataSyncServiceProvider.notifier);

      if (type == SyncItemType.json) {
        // 下载JSON数据
        int completedCount = 0;
        for (final update in _pendingUpdates!) {
          try {
            final success = await dataSyncService.downloadRecipeJson(update);
            if (success) {
              completedCount++;
              setState(() {
                _itemStates[type] = _itemStates[type]!.copyWith(
                  completedItems: completedCount,
                  message: '已下载 $completedCount/${_pendingUpdates!.length} 个食谱',
                );
              });
            }
          } catch (e) {
            print('❌ 下载单个食谱失败: $e');
          }
        }

        // 保存本地索引
        final remoteIndex = await dataSyncService.downloadRemoteIndex();
        if (remoteIndex != null) {
          await dataSyncService.saveLocalIndex(remoteIndex);
        }

        setState(() {
          _itemStates[type] = _itemStates[type]!.copyWith(
            status: SyncItemStatus.completed,
            completedItems: _pendingUpdates!.length,
            message: 'JSON数据下载完成',
          );
        });
      } else if (type == SyncItemType.coverImages) {
        // 下载封面图
        final imageTasks = <DownloadTask>[];
        for (final update in _pendingUpdates!) {
          final task = await dataSyncService.extractCoverImageTask(update);
          if (task != null) {
            imageTasks.add(task);
          }
        }

        if (imageTasks.isNotEmpty) {
          await _downloadImages(type, imageTasks);
        }
      } else if (type == SyncItemType.detailImages) {
        // 下载详情图
        final imageTasks = <DownloadTask>[];
        for (final update in _pendingUpdates!) {
          final tasks = await dataSyncService.extractDetailImageTasks(update);
          imageTasks.addAll(tasks);
        }

        if (imageTasks.isNotEmpty) {
          await _downloadImages(type, imageTasks);
        }
      }
    } catch (e) {
      setState(() {
        _itemStates[type] = _itemStates[type]!.copyWith(
          status: SyncItemStatus.error,
          error: '下载失败: $e',
        );
      });
    }
  }

  void _handlePauseDownload(SyncItemType type) {
    setState(() {
      _itemStates[type] = _itemStates[type]!.copyWith(
        status: SyncItemStatus.paused,
        message: '下载已暂停',
      );
    });
  }

  void _handleResumeDownload(SyncItemType type) {
    setState(() {
      _itemStates[type] = _itemStates[type]!.copyWith(
        status: SyncItemStatus.downloading,
        message: '正在下载...',
      );
    });

    _simulateDownload(type);
  }

  void _handleCancelDownload(SyncItemType type) {
    setState(() {
      _itemStates[type] = SyncItemState.initial(type);
    });
  }

  /// 下载图片
  Future<void> _downloadImages(SyncItemType type, List<DownloadTask> tasks) async {
    final imageDownloadManager = ref.read(imageDownloadManagerProvider.notifier);

    // 添加下载任务
    imageDownloadManager.addDownloadTasks(tasks);

    // 启动进度监听
    _monitorImageDownloadProgress(type, tasks.length);
  }

  /// 监听图片下载进度
  void _monitorImageDownloadProgress(SyncItemType type, int totalTasks) {
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;

      final imageDownloadState = ref.read(imageDownloadManagerProvider);

      setState(() {
        _itemStates[type] = _itemStates[type]!.copyWith(
          completedItems: imageDownloadState.completedTasks,
          message: '已下载 ${imageDownloadState.completedTasks}/$totalTasks 张图片',
        );
      });

      // 检查下载状态
      if (imageDownloadState.status == DownloadStatus.completed) {
        setState(() {
          _itemStates[type] = _itemStates[type]!.copyWith(
            status: SyncItemStatus.completed,
            completedItems: totalTasks,
            message: '图片下载完成',
          );
        });
      } else if (imageDownloadState.status == DownloadStatus.error) {
        setState(() {
          _itemStates[type] = _itemStates[type]!.copyWith(
            status: SyncItemStatus.error,
            error: '图片下载失败',
          );
        });
      } else if (imageDownloadState.status == DownloadStatus.downloading ||
                 imageDownloadState.status == DownloadStatus.paused) {
        // 继续监听
        _monitorImageDownloadProgress(type, totalTasks);
      }
    });
  }

  void _handleClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理所有本地数据吗？这将删除已下载的食谱和图片。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              // 实际清理逻辑
              ref.read(dataSyncServiceProvider.notifier).clearLocalData();
              ref.read(imageDownloadManagerProvider.notifier).clearCache();

              // 重置所有状态
              setState(() {
                _pendingUpdates = null;
                for (final type in SyncItemType.values) {
                  _itemStates[type] = SyncItemState.initial(type);
                }
              });

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清理')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 模拟下载进度
  void _simulateDownload(SyncItemType type) {
    final state = _itemStates[type]!;

    if (state.progress >= 100) {
      setState(() {
        _itemStates[type] = state.copyWith(
          status: SyncItemStatus.completed,
          progress: 100,
          completedItems: state.totalItems,
          message: '下载完成',
        );
      });
      return;
    }

    if (state.status != SyncItemStatus.downloading) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _itemStates[type]!.status == SyncItemStatus.downloading) {
        setState(() {
          final newProgress = (state.progress + 2).clamp(0, 100);
          final newCompleted = (state.totalItems * newProgress / 100).round();

          _itemStates[type] = state.copyWith(
            progress: newProgress,
            completedItems: newCompleted,
          );
        });

        _simulateDownload(type);
      }
    });
  }
}
