import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../recipe/application/providers/recipe_providers.dart';
import '../../../recipe/domain/entities/recipe.dart';
import '../../../recipe/infrastructure/services/recipe_share_service.dart';
import '../../../tips/application/providers/tip_providers.dart';
import '../../../tips/domain/entities/tip.dart';
import '../../../tips/infrastructure/services/tip_share_service.dart';

class MyCreationsScreen extends ConsumerStatefulWidget {
  const MyCreationsScreen({super.key});

  @override
  ConsumerState<MyCreationsScreen> createState() => _MyCreationsScreenState();
}

class _MyCreationsScreenState extends ConsumerState<MyCreationsScreen> {
  final Set<String> _deletingRecipeIds = {};
  final Set<String> _deletingTipIds = {};

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(allRecipesProvider);
    final tipsAsync = ref.watch(allTipsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的自创'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '我的菜谱'),
              Tab(text: '我的教程'),
            ],
          ),
        ),
        body: recipesAsync.when(
          data: (recipes) => tipsAsync.when(
            data: (tips) => TabBarView(
              children: [
                _buildRecipeTab(context, recipes),
                _buildTipTab(context, tips),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorPlaceholder(error),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorPlaceholder(error),
        ),
      ),
    );
  }

  Widget _buildRecipeTab(BuildContext context, List<Recipe> allRecipes) {
    final recipes = allRecipes.where(_isMyRecipe).toList();
    if (recipes.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.restaurant_menu,
        title: '还没有自创菜谱',
        description: '创建菜谱后会显示在这里',
        actionLabel: '创建菜谱',
        onCreate: () => context.push('/create-recipe'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildRecipeQuickCard(context),
        const SizedBox(height: 16),
        for (final recipe in recipes) _buildRecipeCard(recipe),
      ],
    );
  }

  Widget _buildTipTab(BuildContext context, List<Tip> allTips) {
    final tips = allTips.where(_isMyTip).toList();
    if (tips.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.menu_book_outlined,
        title: '还没有自创教程',
        description: '新增教程后会显示在这里',
        actionLabel: '新增教程',
        onCreate: () => context.push('/tips/create'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildTipQuickCard(context),
        const SizedBox(height: 16),
        for (final tip in tips) _buildTipCard(tip),
      ],
    );
  }

  Widget _buildRecipeQuickCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速创建菜谱',
              style: AppTextStyles.h4.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/create-recipe'),
              icon: const Icon(Icons.add),
              label: const Text('创建菜谱'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipQuickCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速创建教程',
              style: AppTextStyles.h4.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/tips/create'),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('新增教程'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final isDeleting = _deletingRecipeIds.contains(recipe.id);

    final trailing = isDeleting
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : PopupMenuButton<_RecipeAction>(
            tooltip: '更多操作',
            onSelected: (action) {
              switch (action) {
                case _RecipeAction.edit:
                  context.push('/recipe/${recipe.id}/edit');
                  break;
                case _RecipeAction.share:
                  _showRecipeShareOptions(context, recipe);
                  break;
                case _RecipeAction.delete:
                  _confirmDeleteRecipe(recipe);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _RecipeAction.edit, child: Text('编辑')),
              PopupMenuItem(value: _RecipeAction.share, child: Text('分享')),
              PopupMenuItem(value: _RecipeAction.delete, child: Text('删除')),
            ],
            icon: const Icon(Icons.more_vert),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/recipe/${recipe.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: const Icon(Icons.restaurant_menu, color: AppColors.primary),
        ),
        title: Text(recipe.name, style: AppTextStyles.h4),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              recipe.categoryName,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecipeSourceChip(recipe),
          ],
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildTipCard(Tip tip) {
    final isDeleting = _deletingTipIds.contains(tip.id);
    final preview = tip.content.isNotEmpty
        ? tip.content
              .replaceAll('\n', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
        : (tip.sections.isNotEmpty ? tip.sections.first.content : '');

    final trailing = isDeleting
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : PopupMenuButton<_TipAction>(
            tooltip: '更多操作',
            onSelected: (action) {
              switch (action) {
                case _TipAction.edit:
                  context.push('/tips/${tip.id}/edit');
                  break;
                case _TipAction.share:
                  _showTipShareOptions(context, tip);
                  break;
                case _TipAction.delete:
                  _confirmDeleteTip(tip);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TipAction.edit, child: Text('编辑')),
              PopupMenuItem(value: _TipAction.share, child: Text('分享')),
              PopupMenuItem(value: _TipAction.delete, child: Text('删除')),
            ],
            icon: const Icon(Icons.more_vert),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/tips/${tip.category}/${tip.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
          child: const Icon(
            Icons.menu_book_outlined,
            color: AppColors.secondary,
          ),
        ),
        title: Text(tip.title, style: AppTextStyles.h4),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              tip.categoryName,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                preview.length > 60
                    ? '${preview.substring(0, 57)}...'
                    : preview,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildTipSourceChip(tip),
          ],
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildRecipeSourceChip(Recipe recipe) {
    late final String label;
    late final Color color;

    switch (recipe.source) {
      case RecipeSource.userCreated:
        label = '自创';
        color = AppColors.primary;
        break;
      case RecipeSource.userModified:
        label = '自创';
        color = Colors.orange;
        break;
      case RecipeSource.scanned:
        label = '扫码导入';
        color = Colors.blue;
        break;
      case RecipeSource.aiGenerated:
        label = 'AI 生成';
        color = Colors.green;
        break;
      default:
        label = '系统';
        color = Colors.grey;
    }

    return _buildSourceChip(label, color);
  }

  Widget _buildTipSourceChip(Tip tip) {
    late final String label;
    late final Color color;

    switch (tip.source) {
      case TipSource.userCreated:
        label = '自创';
        color = AppColors.primary;
        break;
      case TipSource.userModified:
        label = '自创';
        color = Colors.orange;
        break;
      case TipSource.scanned:
        label = '扫码导入';
        color = Colors.blue;
        break;
      case TipSource.bundled:
        label = '系统';
        color = Colors.grey;
        break;
    }

    return _buildSourceChip(label, color);
  }

  Widget _buildSourceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onCreate,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 88, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $error'),
        ],
      ),
    );
  }

  bool _isMyRecipe(Recipe recipe) {
    return switch (recipe.source) {
      RecipeSource.userCreated ||
      RecipeSource.userModified ||
      RecipeSource.scanned ||
      RecipeSource.aiGenerated => true,
      _ => false,
    };
  }

  Future<void> _showRecipeShareOptions(
    BuildContext context,
    Recipe recipe,
  ) async {
    final option = await showModalBottomSheet<_ShareOption>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('复制为文本'),
              onTap: () => Navigator.pop(sheetContext, _ShareOption.text),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('分享图片'),
              onTap: () => Navigator.pop(sheetContext, _ShareOption.image),
            ),
          ],
        ),
      ),
    );

    if (option == null || !mounted) {
      return;
    }

    final shareService = RecipeShareService();
    if (option == _ShareOption.text) {
      final result = await shareService.shareAsText(recipe);
      if (!mounted) return;

      String message;
      switch (result) {
        case RecipeShareResult.success:
          message = '已复制菜谱内容，快去粘贴分享吧';
          break;
        case RecipeShareResult.cancelled:
          message = '已取消复制';
          break;
        case RecipeShareResult.failed:
          message = '复制失败，请稍后再试';
          break;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final result = await shareService.shareAsImage(recipe, context);
    if (!mounted) return;

    String message;
    switch (result) {
      case RecipeShareResult.success:
        message = '已生成图片，快去分享吧';
        break;
      case RecipeShareResult.cancelled:
        message = '已取消分享';
        break;
      case RecipeShareResult.failed:
        message = '生成图片失败，请稍后再试';
        break;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showTipShareOptions(BuildContext context, Tip tip) async {
    final option = await showModalBottomSheet<_ShareOption>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('复制为文本'),
              onTap: () => Navigator.pop(sheetContext, _ShareOption.text),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('分享图片'),
              onTap: () => Navigator.pop(sheetContext, _ShareOption.image),
            ),
          ],
        ),
      ),
    );

    if (option == null || !mounted) {
      return;
    }

    final shareService = TipShareService();
    if (option == _ShareOption.text) {
      final result = await shareService.shareAsText(tip);
      if (!mounted) return;

      String message;
      switch (result) {
        case TipShareResult.success:
          message = '已复制教程内容，快去粘贴分享吧';
          break;
        case TipShareResult.cancelled:
          message = '已取消复制';
          break;
        case TipShareResult.failed:
          message = '复制失败，请稍后再试';
          break;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final result = await shareService.shareAsImage(tip, context);
    if (!mounted) return;

    String message;
    switch (result) {
      case TipShareResult.success:
        message = '已生成图片，快去分享吧';
        break;
      case TipShareResult.cancelled:
        message = '已取消分享';
        break;
      case TipShareResult.failed:
        message = '生成图片失败，请稍后再试';
        break;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canDeleteRecipe(Recipe recipe) {
    return recipe.source == RecipeSource.userCreated ||
        recipe.source == RecipeSource.userModified ||
        recipe.source == RecipeSource.scanned ||
        recipe.source == RecipeSource.aiGenerated;
  }

  bool _isMyTip(Tip tip) => tip.source != TipSource.bundled;

  bool _canDeleteTip(Tip tip) => tip.source != TipSource.bundled;

  Future<void> _confirmDeleteRecipe(Recipe recipe) async {
    if (!_canDeleteRecipe(recipe)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('【${recipe.name}】为内置菜谱，无法删除'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除菜谱'),
        content: Text('确定要删除「${recipe.name}」吗？删除后无法恢复。'),
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

    if (confirmed == true) {
      await _deleteRecipe(recipe);
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    setState(() => _deletingRecipeIds.add(recipe.id));

    try {
      final repository = ref.read(recipeRepositoryProvider);
      await repository.deleteRecipe(recipe.id);
      ref.invalidate(allRecipesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除「${recipe.name}」')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingRecipeIds.remove(recipe.id));
      }
    }
  }

  Future<void> _confirmDeleteTip(Tip tip) async {
    if (!_canDeleteTip(tip)) {
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

    if (confirmed == true) {
      await _deleteTip(tip);
    }
  }

  Future<void> _deleteTip(Tip tip) async {
    setState(() => _deletingTipIds.add(tip.id));

    try {
      final repository = ref.read(tipRepositoryProvider);
      await repository.deleteTip(tip.id);
      ref
        ..invalidate(allTipsProvider)
        ..invalidate(tipsByCategoryProvider(tip.category));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除「${tip.title}」')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTipIds.remove(tip.id));
      }
    }
  }
}

enum _RecipeAction { edit, share, delete }

enum _TipAction { edit, share, delete }

enum _ShareOption { text, image }
