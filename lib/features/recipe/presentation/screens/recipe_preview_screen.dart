// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  void initState() {
    super.initState();
    debugPrint('🎬 RecipePreviewScreen initState');
    debugPrint('  - Recipe ID: ${widget.recipe.id}');
    debugPrint('  - Recipe Name: ${widget.recipe.name}');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 RecipePreviewScreen build');
    debugPrint('  - Recipe ID: ${widget.recipe.id}');
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
                  color: AppColors.surface,
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
                  avatar: Icon(Icons.category, size: 16, color: AppColors.secondary),
                  label: Text(
                    widget.recipe.categoryName,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                        color: AppColors.warning,
                        size: 16,
                      ),
                    ),
                  ),
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3)),
                ),

                // 来源标记（根据食谱来源显示不同的徽章）
                _buildSourceChip(),
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
                        child: MarkdownBody(
                          data: ingredient.text,
                          shrinkWrap: true,
                          fitContent: true,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTextStyles.ingredient,
                          ),
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
        ..._buildStepWidgets(),
      ],
    );
  }

  static final _headingPattern = RegExp(r'^#{1,4}\s+(.+)$');

  List<Widget> _buildStepWidgets() {
    final widgets = <Widget>[];
    int stepNumber = 0;
    for (final step in widget.recipe.steps) {
      final match = _headingPattern.firstMatch(step.description);
      if (match != null) {
        widgets.add(Padding(
          padding: EdgeInsets.only(
            top: widgets.isEmpty ? 0 : 12,
            bottom: 4,
          ),
          child: Text(
            match.group(1)!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ));
      } else {
        stepNumber++;
        widgets.add(Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MarkdownBody(
                    data: step.description,
                    shrinkWrap: true,
                    fitContent: true,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTextStyles.cookingStep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      }
    }
    return widgets;
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
            MarkdownBody(
              data: widget.recipe.tips!,
              shrinkWrap: true,
              styleSheet: MarkdownStyleSheet(
                p: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              onTapLink: (text, href, title) {
                if (href == null) return;
                final uri = Uri.tryParse(href);
                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
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
                      child: MarkdownBody(
                        data: warning,
                        shrinkWrap: true,
                        fitContent: true,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
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

  /// 构建来源标记徽章
  Widget _buildSourceChip() {
    IconData icon;
    String label;
    Color color;

    switch (widget.recipe.source) {
      case RecipeSource.userModified:
        icon = Icons.edit;
        label = '修改版';
        color = AppColors.plum;
        break;
      case RecipeSource.userCreated:
        icon = Icons.person;
        label = '用户创建';
        color = AppColors.primary;
        break;
      case RecipeSource.aiGenerated:
        icon = Icons.auto_awesome;
        label = 'AI 生成';
        color = AppColors.success;
        break;
      case RecipeSource.scanned:
        icon = Icons.qr_code_scanner;
        label = '扫码导入';
        color = AppColors.primary;
        break;
      default:
        icon = Icons.qr_code_scanner;
        label = '扫码导入';
        color = AppColors.primary;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                          color: AppColors.surface,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving
                    ? '保存中...'
                    : widget.recipe.source == RecipeSource.userModified
                        ? '更新到我的食谱'
                        : '保存到我的食谱'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
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
    debugPrint('💾 开始保存食谱...');
    debugPrint('  - Recipe ID: ${widget.recipe.id}');
    debugPrint('  - Recipe Name: ${widget.recipe.name}');

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(recipeRepositoryProvider);

      // 检查是否已存在相同的食谱（通过 hash 或 baseId）
      // 注意：跳过临时 ID（preview_ 开头）的查询
      Recipe? existingRecipe;
      debugPrint('🔍 检查食谱是否已存在...');
      debugPrint('  - ID 非空: ${widget.recipe.id.isNotEmpty}');
      debugPrint('  - 是否临时 ID: ${widget.recipe.id.startsWith('preview_')}');

      if (widget.recipe.id.isNotEmpty && !widget.recipe.id.startsWith('preview_')) {
        try {
          debugPrint('📡 查询现有食谱: ${widget.recipe.id}');
          final recipeAsync = await ref.read(recipeByIdProvider(widget.recipe.id).future);
          existingRecipe = recipeAsync;
          debugPrint('✅ 找到现有食谱: ${existingRecipe?.name}');
        } catch (e) {
          // 如果查询失败（如 ID 格式不合法），忽略错误，当作新食谱处理
          debugPrint('⚠️  查询现有食谱失败: $e');
        }
      } else {
        debugPrint('⏭️  跳过现有食谱查询（临时 ID 或空 ID）');
      }

      if (existingRecipe != null) {
        // 检查现有食谱的来源
        if (existingRecipe.source == RecipeSource.bundled) {
          // 内置食谱不能更新，需要保存为副本
          debugPrint('📦 现有食谱是内置食谱，将保存为新副本');

          // 生成新的 ID
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newId = 'scanned_${widget.recipe.category}_${timestamp.toRadixString(16)}';

          // 创建副本（保留扫码来源标记）
          final copiedRecipe = widget.recipe.copyWith(
            id: newId,
            source: RecipeSource.scanned,
          );

          await repository.saveRecipe(copiedRecipe);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 已保存为我的食谱（内置食谱已复制）'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          // 用户创建或之前扫码的食谱，可以更新
          debugPrint('👤 现有食谱是用户食谱，询问是否更新');

          if (mounted) {
            final shouldUpdate = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  '食谱已存在',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                content: Text(
                  '「${widget.recipe.name}」已在您的食谱库中，是否更新为最新版本？',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
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

            // 更新食谱（保留原 ID 和 source）
            final updatedRecipe = widget.recipe.copyWith(
              source: existingRecipe.source, // 保留原有的 source
            );
            await repository.saveRecipe(updatedRecipe);
          }
        }
      } else {
        // 新食谱，确保有正确的 source 标记
        final recipeToSave = widget.recipe.source == RecipeSource.bundled ||
                widget.recipe.source == RecipeSource.cloud
            ? widget.recipe.copyWith(source: RecipeSource.scanned)
            : widget.recipe;
        await repository.saveRecipe(recipeToSave);
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
