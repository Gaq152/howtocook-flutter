import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../recipe/application/providers/recipe_providers.dart';
import '../../../recipe/domain/entities/recipe.dart';
import '../../../tips/application/providers/tip_providers.dart';
import '../../../tips/domain/entities/tip.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的自创'),
      ),
      body: recipesAsync.when(
        data: (recipes) => tipsAsync.when(
          data: (tips) => _buildContent(context, recipes, tips),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorPlaceholder(error),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorPlaceholder(error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Recipe> allRecipes,
    List<Tip> allTips,
  ) {
    final myRecipes = allRecipes.where(_isMyRecipe).toList();
    final myTips = allTips.where(_isMyTip).toList();

    if (myRecipes.isEmpty && myTips.isEmpty) {
      return _buildEmptyPlaceholder(context);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildHeader(context),
        if (myRecipes.isNotEmpty) ...[
          _buildSectionTitle('我的菜谱'),
          const SizedBox(height: 12),
          for (final recipe in myRecipes) _buildRecipeCard(recipe),
        ],
        if (myTips.isNotEmpty) ...[
          if (myRecipes.isNotEmpty) const SizedBox(height: 24),
          _buildSectionTitle('我的教程'),
          const SizedBox(height: 12),
          for (final tip in myTips) _buildTipCard(tip),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            Text('快速创建',
              style: AppTextStyles.h4.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/create-recipe'),
                    icon: const Icon(Icons.add),
                    label: const Text('创建菜谱'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/tips/create'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('新增教程'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final isDeleting = _deletingRecipeIds.contains(recipe.id);
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
        trailing: IconButton(
          tooltip: '删除',
          icon: isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          onPressed: isDeleting ? null : () => _confirmDeleteRecipe(recipe),
        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/tips/${tip.category}/${tip.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
          child: const Icon(Icons.menu_book_outlined, color: AppColors.secondary),
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
                preview.length > 60 ? '${preview.substring(0, 57)}...' : preview,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildTipSourceChip(tip),
          ],
        ),
        trailing: IconButton(
          tooltip: '删除',
          icon: isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          onPressed: isDeleting ? null : () => _confirmDeleteTip(tip),
        ),
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
        label = '我的修改';
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
        label = '我的修改';
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

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_satisfied_alt,
                size: 88, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
          Text('还没有自创内容', style: AppTextStyles.h2.copyWith(color: Colors.grey.shade500)),
              style: AppTextStyles.h2.copyWith(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              '创建菜谱或新增教程后会显示在这里',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/create-recipe'),
              icon: const Icon(Icons.add),
              label: const Text('立即创建'),
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
      RecipeSource.aiGenerated =>
        true,
      _ => false,
    };
  }

  bool _isMyTip(Tip tip) {
    return tip.source != TipSource.bundled;
  }

  Future<void> _confirmDeleteRecipe(Recipe recipe) async {
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
    if (recipe.source == RecipeSource.bundled ||
        recipe.source == RecipeSource.cloud) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${recipe.name}」为内置菜谱，无法删除'), backgroundColor: Colors.orange),
        ),
      );
      return;
    }

    setState(() => _deletingRecipeIds.add(recipe.id));

    try {
      final repository = ref.read(recipeRepositoryProvider);
      await repository.deleteRecipe(recipe.id);
      ref.invalidate(allRecipesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除「${recipe.name}」')),
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingRecipeIds.remove(recipe.id));
      }
    }
  }

  Future<void> _confirmDeleteTip(Tip tip) async {
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
    if (tip.source == TipSource.bundled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${tip.title}」为内置教程，无法删除'), backgroundColor: Colors.orange),
        ),
      );
      return;
    }

    setState(() => _deletingTipIds.add(tip.id));

    try {
      final repository = ref.read(tipRepositoryProvider);
      await repository.deleteTip(tip.id);
      ref.invalidate(allTipsProvider);
      ref.invalidate(tipsByCategoryProvider(tip.category));

      ScaffoldMessenger.of(context).showSnackBar(
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除「${tip.title}」')),
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTipIds.remove(tip.id));
      }
    }
  }
}

