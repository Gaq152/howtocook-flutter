import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
import '../widgets/recipe_card.dart';
import '../../../../core/theme/app_colors.dart';

/// 收藏菜谱页面
///
/// 显示用户收藏的所有菜谱
class FavoriteRecipesScreen extends ConsumerWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: favoritesAsync.when(
        data: (recipes) => _buildRecipeList(context, recipes, ref),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, error, ref),
      ),
    );
  }

  /// 构建菜谱列表
  Widget _buildRecipeList(BuildContext context, List<Recipe> recipes, WidgetRef ref) {
    if (recipes.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // 刷新收藏列表
        ref.invalidate(favoriteRecipesProvider);
        // 等待数据重新加载
        await ref.read(favoriteRecipesProvider.future);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.58,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(recipe: recipes[index]);
        },
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载收藏...'),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 重新加载
                ref.invalidate(favoriteRecipesProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空列表状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无收藏',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '浏览菜谱时点击爱心图标即可收藏',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 跳转到菜谱首页
                context.go('/recipes');
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('去浏览菜谱'),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据屏幕宽度计算列数
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 4; // 超大屏
    } else if (width > 800) {
      return 3; // 大屏
    } else if (width > 600) {
      return 2; // 中屏
    } else {
      return 2; // 小屏
    }
  }
}
