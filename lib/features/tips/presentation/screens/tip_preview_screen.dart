import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/linkable_text.dart';
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';

class TipPreviewScreen extends ConsumerWidget {
  const TipPreviewScreen({super.key, required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教程预览'),
        actions: [
          IconButton(
            tooltip: '保存到我的教程',
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _saveTip(context, ref),
          ),
        ],
      ),
      body: _TipPreviewBody(tip: tip),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _saveTip(context, ref),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTip(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(tipRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await repository.saveTip(tip);
      ref.invalidate(allTipsProvider);
      ref.invalidate(tipsByCategoryProvider(tip.category));
      ref.invalidate(tipByIdProvider(tip.id));
      messenger.showSnackBar(const SnackBar(content: Text('教程已保存')));
      router.go('/tips/${tip.category}/${tip.id}');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }
}

class _TipPreviewBody extends StatelessWidget {
  const _TipPreviewBody({required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(tip.categoryName),
                      backgroundColor: AppColors.info.withValues(alpha: 0.15),
                    ),
                    Chip(
                      avatar: const Icon(Icons.tag_outlined, size: 18),
                      label: Text(tip.category),
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(tip.title, style: AppTextStyles.h2),
                const SizedBox(height: 16),
                if (tip.content.isNotEmpty)
                  Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withValues(alpha: 0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LinkableTextRich(
                        tip.content,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (tip.sections.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = tip.sections[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  index == 0 ? 0 : 12,
                  20,
                  index == tip.sections.length - 1 ? 24 : 0,
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        LinkableTextRich(
                          section.content,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: tip.sections.length),
          ),
      ],
    );
  }
}
