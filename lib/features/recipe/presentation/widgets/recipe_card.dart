import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recipe.dart';
import '../../application/providers/recipe_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 菜谱卡片组件
///
/// 用于在列表中展示菜谱预览信息
class RecipeCard extends ConsumerWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/recipe/${recipe.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片区域 - 使用Expanded让其灵活适应空间
            Expanded(
              child: _buildImage(),
            ),

            // 内容区域 - 固定高度
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 菜谱名称
                  Text(
                    recipe.name,
                    style: AppTextStyles.recipeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 分类和难度
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // 分类标签 - 使用Expanded占据剩余空间
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            recipe.categoryName,
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // 难度星星 - 固定宽度区域，保持对齐
                      SizedBox(
                        width: 70, // 5颗星的固定宽度 (14 * 5)
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            recipe.difficulty.clamp(1, 5),
                            (index) => const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // 收藏图标
                      _buildFavoriteIcon(ref),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImage() {
    if (recipe.images.isEmpty) {
      // 无图片时显示占位图
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                '暂无图片',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 显示第一张图片
    return Image.asset(
      recipe.images.first,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // 图片加载失败时显示占位图
        return Container(
          width: double.infinity,
          color: AppColors.surface,
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  /// 构建收藏图标
  Widget _buildFavoriteIcon(WidgetRef ref) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(recipe.id));

    return isFavoriteAsync.when(
      data: (isFavorite) => IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.error : AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () async {
          // 切换收藏状态
          final repository = ref.read(recipeRepositoryProvider);
          await repository.toggleFavorite(recipe.id);
          // 刷新收藏状态
          ref.invalidate(isFavoriteProvider(recipe.id));
          ref.invalidate(favoriteRecipesProvider);
          ref.invalidate(favoriteIdsProvider);
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => Icon(
        Icons.favorite_border,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
