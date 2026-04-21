import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../recipe/application/providers/recipe_providers.dart'
    show manifestProvider;
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';
import '../utils/tip_share_helpers.dart';

class TipsOverviewScreen extends ConsumerStatefulWidget {
  const TipsOverviewScreen({super.key});

  @override
  ConsumerState<TipsOverviewScreen> createState() => _TipsOverviewScreenState();
}

class _TipsOverviewScreenState extends ConsumerState<TipsOverviewScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(manifestProvider);
    final tipsAsync = _selectedCategory == null
        ? ref.watch(allTipsProvider)
        : ref.watch(tipsByCategoryProvider(_selectedCategory!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('教程中心'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allTipsProvider);
              if (_selectedCategory != null) {
                ref.invalidate(tipsByCategoryProvider(_selectedCategory!));
              }
            },
          ),
          IconButton(
            tooltip: '新建教程',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/tips/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          manifestAsync.when(
            data: (manifest) {
              final categories = <String?, String>{
                null: '全部',
                for (final entry in manifest.tipsCategories.entries)
                  entry.key: entry.value.name,
              };

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.entries.map((entry) {
                    final categoryId = entry.key;
                    final categoryName = entry.value;
                    final isSelected = _selectedCategory == categoryId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          categoryName,
                          style: AppTextStyles.label.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.4),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        pressElevation: 0,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = categoryId;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('加载分类失败: $error'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tipsAsync.when(
              data: (tips) {
                if (tips.isEmpty) {
                  return const _EmptyTipsView();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allTipsProvider);
                    if (_selectedCategory != null) {
                      ref.invalidate(
                        tipsByCategoryProvider(_selectedCategory!),
                      );
                    }
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: tips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tip = tips[index];
                      return _TipListTile(
                        tip: tip,
                        onTap: () =>
                            context.push('/tips/${tip.category}/${tip.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('加载教程失败: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipListTile extends ConsumerWidget {
  const _TipListTile({
    required this.tip,
    required this.onTap,
  });

  final Tip tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
        ),
        title: Text(tip.title, style: AppTextStyles.h4),
        subtitle: Text(
          tip.categoryName,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            tip.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: tip.isFavorite ? AppColors.error : AppColors.textSecondary,
            size: 22,
          ),
          tooltip: tip.isFavorite ? '取消收藏' : '收藏',
          onPressed: () => _toggleFavorite(context, ref),
        ),
        onTap: onTap,
        onLongPress: () => _showLongPressMenu(context, ref),
      ),
    );
  }

  void _showLongPressMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                tip.title,
                style: AppTextStyles.h5,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/tips/${tip.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(sheetContext);
                showTipShareSheet(context: context, ref: ref, tip: tip);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('删除', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteTip(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(tipRepositoryProvider)
          .toggleFavorite(tip.id, !tip.isFavorite);

      // 刷新相关数据
      ref.invalidate(allTipsProvider);
      ref.invalidate(favoriteTipsProvider);
      ref.invalidate(favoriteTipIdsProvider);

      if (!context.mounted) return;

      final message = tip.isFavorite ? '已取消收藏' : '已收藏';
      AppSnackBar.show(context, '$message「${tip.title}」');
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, '操作失败: $e');
      }
    }
  }

  /// 检查是否可以删除
  bool _canDeleteTip(Tip tip) {
    return tip.source != TipSource.bundled;
  }

  /// 确认删除教程
  Future<void> _confirmDeleteTip(BuildContext context, WidgetRef ref) async {
    if (!_canDeleteTip(tip)) {
      AppSnackBar.show(
        context,
        '【${tip.title}】为内置教程，无法删除',
        backgroundColor: AppColors.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除教程'),
        content: Text('确定要删除「${tip.title}」吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteTip(context, ref);
    }
  }

  /// 删除教程
  Future<void> _deleteTip(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(tipRepositoryProvider);
      await repository.deleteTip(tip.id);

      // 刷新相关数据
      ref.invalidate(allTipsProvider);
      ref.invalidate(favoriteTipsProvider);

      if (!context.mounted) return;

      AppSnackBar.show(context, '已删除「${tip.title}」');
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          '删除失败: $e',
          backgroundColor: AppColors.error,
        );
      }
    }
  }
}

class _EmptyTipsView extends StatelessWidget {
  const _EmptyTipsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text('暂无教程', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('点击右下角按钮创建你的第一个教程'),
        ],
      ),
    );
  }
}
