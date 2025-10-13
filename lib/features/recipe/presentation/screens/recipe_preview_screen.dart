import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recipe.dart';
import '../../application/providers/recipe_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 食谱预览页面
///
/// 展示扫码导入的食谱，用户可以选择保存或取消
class RecipePreviewScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipePreviewScreen({
    super.key,
    required this.recipe,
  });

  @override
  ConsumerState<RecipePreviewScreen> createState() => _RecipePreviewScreenState();
}

class _RecipePreviewScreenState extends ConsumerState<RecipePreviewScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食谱预览'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 提示卡片
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '预览扫码导入的食谱，确认无误后可保存到我的食谱',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 食谱内容
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和元信息
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // 食材列表
                  _buildIngredientsSection(),
                  const SizedBox(height: 24),

                  // 步骤列表
                  _buildStepsSection(),
                  const SizedBox(height: 24),

                  // 小贴士（如果有）
                  if (widget.recipe.tips != null && widget.recipe.tips!.isNotEmpty) ...[
                    _buildTipsSection(),
                    const SizedBox(height: 24),
                  ],

                  // 警告（如果有）
                  if (widget.recipe.warnings.isNotEmpty) ...[
                    _buildWarningsSection(),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 80), // 底部留白
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 构建标题和元信息
  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              widget.recipe.name,
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 12),

            // 元信息
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // 分类
                Chip(
                  avatar: const Icon(Icons.category, size: 16),
                  label: Text(widget.recipe.categoryName),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),

                // 难度
                Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.recipe.difficulty.clamp(1, 5),
                      (index) => const Icon(
                        Icons.star,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ),
                  ),
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
                ),

                // 来源标记
                Chip(
                  avatar: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('扫码导入'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建食材部分
  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('食材清单', style: AppTextStyles.h2),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.recipe.ingredients.map((ingredient) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ingredient.text,
                          style: AppTextStyles.ingredient,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建步骤部分
  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text('制作步骤', style: AppTextStyles.h2),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.recipe.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 步骤编号
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 步骤描述
                  Expanded(
                    child: Text(
                      step.description,
                      style: AppTextStyles.cookingStep,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 构建小贴士部分
  Widget _buildTipsSection() {
    return Card(
      color: AppColors.info.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.info, size: 24),
                const SizedBox(width: 8),
                Text('小贴士', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.recipe.tips!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建警告部分
  Widget _buildWarningsSection() {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
                const SizedBox(width: 8),
                Text('注意事项', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.recipe.warnings.map((warning) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 取消按钮
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 16),
            // 保存按钮
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRecipe,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? '保存中...' : '保存到我的食谱'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存食谱到本地
  Future<void> _saveRecipe() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(recipeRepositoryProvider);

      // 检查是否已存在相同的食谱（通过 hash 或 baseId）
      Recipe? existingRecipe;
      if (widget.recipe.id.isNotEmpty) {
        final recipeAsync = await ref.read(recipeByIdProvider(widget.recipe.id).future);
        existingRecipe = recipeAsync;
      }

      if (existingRecipe != null) {
        // 食谱已存在，询问是否更新
        if (mounted) {
          final shouldUpdate = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('食谱已存在'),
              content: Text('「${widget.recipe.name}」已在您的食谱库中，是否更新为最新版本？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('更新'),
                ),
              ],
            ),
          );

          if (shouldUpdate != true) {
            setState(() {
              _isSaving = false;
            });
            return;
          }

          // 更新食谱（保留原 ID）
          await repository.saveRecipe(widget.recipe);
        }
      } else {
        // 新食谱，保存到数据库
        await repository.saveRecipe(widget.recipe);
      }

      // 刷新食谱列表
      ref.invalidate(allRecipesProvider);
      ref.invalidate(recipeByIdProvider(widget.recipe.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 食谱已保存'),
            backgroundColor: AppColors.success,
          ),
        );

        // 延迟一下再返回，让用户看到成功提示
        await Future.delayed(const Duration(milliseconds: 500));

        // 返回到食谱列表或详情页
        context.go('/recipes');
      }
    } catch (e) {
      debugPrint('保存食谱失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
