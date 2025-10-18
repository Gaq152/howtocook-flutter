import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recipe.dart';
import '../../application/providers/recipe_providers.dart';
import '../../infrastructure/services/recipe_share_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cached_recipe_image.dart';

/// Provider for RecipeShareService
final recipeShareServiceProvider = Provider<RecipeShareService>((ref) {
  return RecipeShareService();
});

enum _RecipeMenuAction { edit, share, delete }

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
                    children: [
                      // 分类标签 - 使用Expanded并限制宽度
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            recipe.categoryName,
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.secondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // 难度星星 - 限制最多3个
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          recipe.difficulty.clamp(1, 3),
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 10,
                          ),
                        ),
                      ),

                      // 收藏图标和菜单
                      _buildActions(context, ref),
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

  /// 构建操作按钮（收藏 + 菜单）
  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 收藏图标
        _buildFavoriteIcon(ref),
        // 三点菜单（移除间距）
        _buildMenuButton(context, ref),
      ],
    );
  }

  /// 构建三点菜单按钮
  Widget _buildMenuButton(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_RecipeMenuAction>(
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 16,
      ),
      padding: EdgeInsets.zero,
      iconSize: 16,
      tooltip: '更多操作',
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      onSelected: (action) {
        switch (action) {
          case _RecipeMenuAction.edit:
            context.push('/recipe/${recipe.id}/edit');
            break;
          case _RecipeMenuAction.share:
            _showShareOptions(context, ref);
            break;
          case _RecipeMenuAction.delete:
            _confirmDeleteRecipe(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _RecipeMenuAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('编辑'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _RecipeMenuAction.share,
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 20),
              SizedBox(width: 12),
              Text('分享'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: _RecipeMenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建图片区域 - 使用缓存图片加载
  Widget _buildImage() {
    // 使用CachedRecipeImage.cover加载封面图
    return CachedRecipeImage.cover(
      category: recipe.category,
      recipeName: recipe.name,
      width: double.infinity,
      fit: BoxFit.cover,
      errorWidget: RecipePlaceholderImage(
        icon: Icons.cloud_download_outlined,
        text: '图片未下载\n请前往数据同步页面下载',
      ),
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
          size: 16,
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
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
      ),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => Icon(
        Icons.favorite_border,
        color: AppColors.textSecondary,
        size: 16,
      ),
    );
  }

  /// 显示分享选项
  void _showShareOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields_outlined),
              title: const Text('复制为文本'),
              subtitle: const Text('纯文本格式，可粘贴到任意位置'),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareAsText(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('分享图片'),
              subtitle: const Text('带二维码的精美卡片'),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareAsImage(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 分享为文本
  Future<void> _shareAsText(BuildContext context, WidgetRef ref) async {
    try {
      final shareService = ref.read(recipeShareServiceProvider);
      final result = await shareService.shareAsText(recipe);

      if (!context.mounted) return;

      String message;
      switch (result) {
        case RecipeShareResult.success:
          message = '✅ 已复制菜谱内容到剪贴板';
          break;
        case RecipeShareResult.cancelled:
          message = '已取消复制';
          break;
        case RecipeShareResult.failed:
          message = '复制失败，请稍后再试';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  /// 分享为图片
  Future<void> _shareAsImage(BuildContext context, WidgetRef ref) async {
    try {
      final shareService = ref.read(recipeShareServiceProvider);
      final result = await shareService.shareAsImage(recipe, context);

      if (!context.mounted) return;

      String message;
      switch (result) {
        case RecipeShareResult.success:
          message = '✅ 已生成图片，快去分享吧';
          break;
        case RecipeShareResult.cancelled:
          message = '已取消分享';
          break;
        case RecipeShareResult.failed:
          message = '生成图片失败，请稍后再试';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  /// 检查是否可以删除
  bool _canDeleteRecipe(Recipe recipe) {
    return switch (recipe.source) {
      RecipeSource.userCreated ||
      RecipeSource.userModified ||
      RecipeSource.scanned ||
      RecipeSource.aiGenerated => true,
      _ => false,
    };
  }

  /// 确认删除菜谱
  Future<void> _confirmDeleteRecipe(BuildContext context, WidgetRef ref) async {
    if (!_canDeleteRecipe(recipe)) {
      final message = recipe.source == RecipeSource.bundled
          ? '【${recipe.name}】为内置菜谱，无法删除'
          : '【${recipe.name}】暂不支持删除';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除菜谱'),
        content: Text('确定要删除「${recipe.name}」吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteRecipe(context, ref);
    }
  }

  /// 删除菜谱
  Future<void> _deleteRecipe(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(recipeRepositoryProvider);
      await repository.deleteRecipe(recipe.id);

      // 刷新相关数据
      ref.invalidate(allRecipesProvider);
      ref.invalidate(favoriteRecipesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除「${recipe.name}」')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
