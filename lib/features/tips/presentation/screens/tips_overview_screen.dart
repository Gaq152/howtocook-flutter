import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../recipe/application/providers/recipe_providers.dart'
    show manifestProvider;
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';
import '../../infrastructure/services/tip_share_service.dart';

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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tips/create'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.4),
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.surface,
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
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
                        onEdit: () => context.push('/tips/${tip.id}/edit'),
                        onShare: () => _showShareSheet(context, ref, tip),
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

  Future<void> _showShareSheet(
    BuildContext context,
    WidgetRef ref,
    Tip tip,
  ) async {
    final shareService = ref.read(tipShareServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('复制纯文本'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final result = await shareService.shareAsText(tip);
                  _showShareResult(
                    messenger,
                    result,
                    successMessage: '教程已复制到剪贴板',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('分享图片'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final result = await shareService.shareAsImage(tip, context);
                  _showShareResult(
                    messenger,
                    result,
                    successMessage: '教程图片已分享',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('保存图片到相册'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final result = await shareService.shareAsImage(
                    tip,
                    context,
                    saveOnly: true,
                  );
                  _showShareResult(
                    messenger,
                    result,
                    successMessage: '图片已保存到相册',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShareResult(
    ScaffoldMessengerState messenger,
    TipShareResult result, {
    required String successMessage,
  }) {
    switch (result) {
      case TipShareResult.success:
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
        break;
      case TipShareResult.failed:
        messenger.showSnackBar(const SnackBar(content: Text('分享失败，请稍后重试')));
        break;
      case TipShareResult.cancelled:
        break;
    }
  }
}

class _TipListTile extends StatelessWidget {
  const _TipListTile({
    required this.tip,
    required this.onTap,
    required this.onEdit,
    required this.onShare,
  });

  final Tip tip;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
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
          '${tip.categoryName} · ${tip.category}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'share':
                onShare();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'share', child: Text('分享')),
          ],
        ),
        onTap: onTap,
      ),
    );
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
          const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('暂无教程', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('点击右下角按钮创建你的第一个教程'),
        ],
      ),
    );
  }
}
