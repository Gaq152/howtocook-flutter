import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
import '../widgets/recipe_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tips/application/providers/tip_providers.dart';
import '../../../tips/domain/entities/tip.dart';

/// 收藏页面（菜谱 + 教程）
///
/// 显示用户收藏的所有菜谱和教程
class FavoriteRecipesScreen extends ConsumerWidget {
  const FavoriteRecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的收藏'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '菜谱收藏'),
              Tab(text: '教程收藏'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RecipeTab(ref: ref),
            _TipTab(ref: ref),
          ],
        ),
      ),
    );
  }
}

/// 菜谱收藏 Tab
class _RecipeTab extends StatelessWidget {
  const _RecipeTab({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoriteRecipesProvider);

    return favoritesAsync.when(
      data: (recipes) => _buildRecipeList(context, recipes),
      loading: () => _buildLoadingState('正在加载菜谱收藏...'),
      error: (error, stack) => _buildErrorState(context, error, ref, true),
    );
  }

  /// 构建菜谱列表
  Widget _buildRecipeList(BuildContext context, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.favorite_border,
        title: '暂无菜谱收藏',
        description: '浏览菜谱时点击爱心图标即可收藏',
        actionLabel: '去浏览菜谱',
        onAction: () => context.go('/recipes'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(favoriteRecipesProvider);
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

  /// 构建加载状态
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(
    BuildContext context,
    Object error,
    WidgetRef ref,
    bool isRecipe,
  ) {
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
                if (isRecipe) {
                  ref.invalidate(favoriteRecipesProvider);
                } else {
                  ref.invalidate(favoriteTipsProvider);
                }
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
  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.restaurant_menu),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// 教程收藏 Tab
class _TipTab extends StatelessWidget {
  const _TipTab({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoriteTipsProvider);

    return favoritesAsync.when(
      data: (tips) => _buildTipList(context, tips),
      loading: () => _buildLoadingState('正在加载教程收藏...'),
      error: (error, stack) => _buildErrorState(context, error, ref, false),
    );
  }

  /// 构建教程列表
  Widget _buildTipList(BuildContext context, List<Tip> tips) {
    if (tips.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.favorite_border,
        title: '暂无教程收藏',
        description: '浏览教程时点击爱心图标即可收藏',
        actionLabel: '去浏览教程',
        onAction: () => context.go('/tips'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(favoriteTipsProvider);
        await ref.read(favoriteTipsProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return _buildTipCard(context, tips[index]);
        },
      ),
    );
  }

  /// 构建教程卡片
  Widget _buildTipCard(BuildContext context, Tip tip) {
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
                preview.length > 60 ? '${preview.substring(0, 57)}...' : preview,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(
    BuildContext context,
    Object error,
    WidgetRef ref,
    bool isRecipe,
  ) {
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
                if (isRecipe) {
                  ref.invalidate(favoriteRecipesProvider);
                } else {
                  ref.invalidate(favoriteTipsProvider);
                }
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
  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
