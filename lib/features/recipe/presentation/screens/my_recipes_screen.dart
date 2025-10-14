import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recipe.dart';
import '../../application/providers/recipe_providers.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';

/// 我的食谱页面
///
/// 显示用户创建、保存的食谱，支持删除操作
class MyRecipesScreen extends ConsumerStatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  ConsumerState<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends ConsumerState<MyRecipesScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final allRecipesAsync = ref.watch(allRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的食谱'),
        elevation: 0,
      ),
      body: allRecipesAsync.when(
        data: (allRecipes) {
          // 过滤出用户相关的食谱
          final myRecipes = allRecipes.where((recipe) {
            return recipe.source == RecipeSource.userCreated ||
                   recipe.source == RecipeSource.scanned ||
                   recipe.source == RecipeSource.aiGenerated ||
                   recipe.source == RecipeSource.userModified;
          }).toList();

          if (myRecipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有我的食谱',
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '创建或保存食谱后会显示在这里',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/recipe-create');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('创建食谱'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myRecipes.length,
            itemBuilder: (context, index) {
              final recipe = myRecipes[index];
              return _buildRecipeCard(recipe);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建食谱卡片
  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/recipe/${recipe.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 食谱图片或占位图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: recipe.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recipe.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 12),

              // 食谱信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 食谱名称
                    Text(
                      recipe.name,
                      style: AppTextStyles.h3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 来源标记
                    _buildSourceBadge(recipe.source),
                    const SizedBox(height: 6),

                    // 分类和难度
                    Row(
                      children: [
                        Icon(Icons.category,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          recipe.categoryName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.star,
                            size: 14, color: Colors.orange.shade300),
                        const SizedBox(width: 4),
                        Text(
                          '难度 ${recipe.difficulty}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 删除按钮
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                ),
                onPressed: _isDeleting ? null : () => _confirmDelete(recipe),
                tooltip: '删除食谱',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建来源标记
  Widget _buildSourceBadge(RecipeSource source) {
    IconData icon;
    String label;
    Color color;

    switch (source) {
      case RecipeSource.userCreated:
        icon = Icons.person;
        label = '我创建的';
        color = Colors.blue;
        break;
      case RecipeSource.scanned:
        icon = Icons.qr_code_scanner;
        label = '扫码导入';
        color = Colors.purple;
        break;
      case RecipeSource.aiGenerated:
        icon = Icons.auto_awesome;
        label = 'AI 生成';
        color = Colors.green;
        break;
      case RecipeSource.userModified:
        icon = Icons.edit;
        label = '我的修改版';
        color = Colors.orange;
        break;
      default:
        icon = Icons.bookmark;
        label = '我的食谱';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 确认删除对话框
  Future<void> _confirmDelete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '删除食谱',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '确定要删除「${recipe.name}」吗？\n删除后无法恢复。',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteRecipe(recipe);
    }
  }

  /// 删除食谱
  Future<void> _deleteRecipe(Recipe recipe) async {
    setState(() => _isDeleting = true);

    try {
      // 检查是否是内置食谱（不应出现在"我的食谱"中，但做保护性检查）
      if (recipe.source == RecipeSource.bundled || recipe.source == RecipeSource.cloud) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('内置食谱「${recipe.name}」无法删除'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final repository = ref.read(recipeRepositoryProvider);
      await repository.deleteRecipe(recipe.id);

      // 刷新列表
      ref.invalidate(allRecipesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除「${recipe.name}」'),
            action: SnackBarAction(
              label: '知道了',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
