import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:html_unescape/html_unescape.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/linkable_text.dart';
import '../../application/providers/tip_providers.dart';
import '../../domain/entities/tip.dart';
import '../../infrastructure/services/tip_share_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('教程详情'),
        actions: [
          tipAsync.maybeWhen(
            data: (tip) => IconButton(
              tooltip: tip?.isFavorite == true ? '取消收藏' : '收藏',
              icon: Icon(
                tip?.isFavorite == true
                    ? Icons.bookmark
                    : Icons.bookmark_outline,
              ),
              onPressed: tip == null
                  ? null
                  : () => _toggleFavorite(ref, tipId, tip.isFavorite),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          tipAsync.maybeWhen(
            data: (tip) => IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: tip == null
                  ? null
                  : () => context.push('/tips/${tip.id}/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          tipAsync.maybeWhen(
            data: (tip) => IconButton(
              tooltip: '分享',
              icon: const Icon(Icons.share_outlined),
              onPressed: tip == null
                  ? null
                  : () => _showShareOptions(context, ref, tip),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: tipAsync.when(
        data: (tip) {
          if (tip == null) {
            return _buildNotFound(context);
          }
          return _TipDetailView(tip: tip);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildError(context, error),
      ),
    );
  }

  void _toggleFavorite(WidgetRef ref, String tipId, bool isFavorite) {
    ref.read(tipRepositoryProvider).toggleFavorite(tipId, !isFavorite).then((
      _,
    ) {
      ref.invalidate(tipByIdProvider(tipId));
      ref.invalidate(favoriteTipIdsProvider);
    });
  }

  Future<void> _showShareOptions(
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

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
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
        // 交由外部 Provider 负责刷新，这里仅触发刷新动画
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
                          Text(
                            section.title,
                            style: AppTextStyles.h4.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
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
  final withoutDefinitions =
      decoded.replaceAll(_footnoteDefinitionPattern, '').trimRight();

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
