import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:html_unescape/html_unescape.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/linkable_text.dart';
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';
import '../utils/tip_share_helpers.dart';

class TipDetailScreen extends ConsumerWidget {
  const TipDetailScreen({
    super.key,
    required this.category,
    required this.tipId,
  });

  final String category;
  final String tipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(tipByIdProvider(tipId));
    final tip = tipAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('教程详情'),
        actions: [
          if (tip != null) ...[
            IconButton(
              tooltip: tip.isFavorite ? '取消收藏' : '收藏',
              icon: Icon(
                tip.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
              ),
              onPressed: () => _toggleFavorite(context, ref, tip),
            ),
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/tips/${tip.id}/edit'),
            ),
            IconButton(
              tooltip: '分享',
              icon: const Icon(Icons.share_outlined),
              onPressed: () =>
                  showTipShareSheet(context: context, ref: ref, tip: tip),
            ),
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteTip(context, ref, tip),
            ),
          ],
        ],
      ),
      body: tipAsync.when(
        data: (data) {
          if (data == null) {
            return _buildNotFound(context);
          }
          return _TipDetailView(tip: data);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildError(context, error),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    Tip tip,
  ) async {
    try {
      await ref
          .read(tipRepositoryProvider)
          .toggleFavorite(tip.id, !tip.isFavorite);
      ref.invalidate(tipByIdProvider(tip.id));
      ref.invalidate(favoriteTipIdsProvider);

      if (!context.mounted) {
        return;
      }

      final message = tip.isFavorite ? '已取消收藏' : '已收藏';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$message「${tip.title}」')));
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  Future<void> _confirmDeleteTip(
    BuildContext context,
    WidgetRef ref,
    Tip tip,
  ) async {
    if (tip.source == TipSource.bundled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('【${tip.title}】为内置教程，无法删除'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除教程'),
        content: Text('确定要删除「${tip.title}」吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(tipRepositoryProvider).deleteTip(tip.id);
      ref
        ..invalidate(allTipsProvider)
        ..invalidate(tipsByCategoryProvider(category))
        ..invalidate(tipByIdProvider(tip.id));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除「${tip.title}」')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('未找到教程', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            '加载失败: $error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _TipDetailView extends StatelessWidget {
  const _TipDetailView({required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyTextStyle = AppTextStyles.bodyMedium.copyWith(
      color: colorScheme.onSurface,
      height: 1.6,
    );
    final titleTextStyle = AppTextStyles.h2.copyWith(
      color: colorScheme.onSurface,
    );
    final summaryText = _normalizeTipText(tip.content);

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
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
                      _MetaChip(
                        icon: Icons.menu_book_outlined,
                        label: tip.categoryName,
                        accentColor: colorScheme.primary,
                      ),
                      _MetaChip(
                        icon: Icons.tag_outlined,
                        label: tip.category,
                        accentColor: colorScheme.secondary,
                      ),
                      _MetaChip(
                        icon: Icons.numbers_outlined,
                        label: tip.id,
                        accentColor: colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(tip.title, style: titleTextStyle),
                  const SizedBox(height: 16),
                  if (summaryText.isNotEmpty)
                    Card(
                      elevation: 0,
                      color: _tintedSurface(colorScheme, colorScheme.primary),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LinkableTextRich(
                          summaryText,
                          style: bodyTextStyle,
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
                    color: _tintedSurface(colorScheme, colorScheme.secondary),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (section.title.isNotEmpty)
                            Text(
                              section.title,
                              style: AppTextStyles.h4.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          if (section.title.isNotEmpty)
                            const SizedBox(height: 12),
                          LinkableTextRich(
                            _normalizeTipText(section.content),
                            style: bodyTextStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: tip.sections.length),
            ),
        ],
      ),
    );
  }
}

final HtmlUnescape _htmlUnescape = HtmlUnescape();
final RegExp _footnoteDefinitionPattern = RegExp(
  r'^\[\^\d+\]:.*$',
  multiLine: true,
);
final RegExp _footnoteReferencePattern = RegExp(r'\[\^(\d+)\]');

Color _tintedSurface(ColorScheme colorScheme, Color accentColor) {
  return Color.alphaBlend(
    accentColor.withValues(alpha: 0.06),
    colorScheme.surface,
  );
}

String _normalizeTipText(String value) {
  if (value.isEmpty) {
    return value;
  }

  final decoded = _htmlUnescape.convert(value).replaceAll('\r\n', '\n');
  final withoutDefinitions = decoded
      .replaceAll(_footnoteDefinitionPattern, '')
      .trimRight();

  final cleaned = withoutDefinitions.replaceAllMapped(
    _footnoteReferencePattern,
    (match) => '（注${match.group(1)}）',
  );

  return cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = _tintedSurface(colorScheme, accentColor);
    final borderColor = accentColor.withValues(alpha: 0.24);

    return Chip(
      avatar: Icon(icon, size: 18, color: accentColor),
      label: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      side: BorderSide(color: borderColor),
      backgroundColor: background,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
