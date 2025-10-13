import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../../application/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
import '../../infrastructure/services/recipe_share_service.dart';
import '../../presentation/widgets/recipe_share_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/linkable_text.dart';

/// Provider for RecipeShareService
final recipeShareServiceProvider = Provider<RecipeShareService>((ref) {
  return RecipeShareService();
});

/// 菜谱详情页面
///
/// 显示单个菜谱的完整信息，包括图片、食材、步骤等
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));

    return Scaffold(
      body: recipeAsync.when(
        data: (recipe) => recipe == null
            ? _buildEmptyState(context)
            : _buildContent(context, recipe),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  /// 构建内容
  Widget _buildContent(BuildContext context, Recipe recipe) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, recipe),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaInfo(recipe),
                const SizedBox(height: 24),
                _buildIngredients(recipe),
                const SizedBox(height: 24),
                if (recipe.tools.isNotEmpty) ...[
                  _buildTools(recipe),
                  const SizedBox(height: 24),
                ],
                _buildSteps(recipe),
                const SizedBox(height: 24),
                if (recipe.tips != null && recipe.tips!.isNotEmpty) ...[
                  _buildTips(recipe),
                  const SizedBox(height: 24),
                ],
                if (recipe.warnings.isNotEmpty) ...[
                  _buildWarnings(recipe),
                  const SizedBox(height: 24),
                ],
                _buildUserNote(recipe),
                const SizedBox(height: 80), // 底部留白
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建可展开的应用栏
  Widget _buildSliverAppBar(BuildContext context, Recipe recipe) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(widget.recipeId));

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          recipe.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: _buildHeaderImage(recipe),
      ),
      actions: [
        // 编辑按钮
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          tooltip: '编辑菜谱',
          onPressed: () => context.push('/recipe/${recipe.id}/edit'),
        ),
        // 分享按钮
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          tooltip: '分享菜谱',
          onPressed: () => _showShareDialog(context, recipe),
        ),
      ],
    );
  }

  /// 构建头部图片
  Widget _buildHeaderImage(Recipe recipe) {
    if (recipe.images.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.restaurant_menu,
            size: 120,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    final imagePath = recipe.images.first;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImageWidget(imagePath),
        // 渐变遮罩，确保文字可读
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建图片组件（支持本地、网络、资源、Base64图片）
  Widget _buildImageWidget(String imagePath) {
    // 规范化路径：在Web端将反斜杠转换为正斜杠
    final normalizedPath = kIsWeb
        ? imagePath.replaceAll('\\', '/')
        : imagePath;

    // 错误时显示的占位符
    Widget errorWidget = Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 64,
          color: AppColors.textSecondary,
        ),
      ),
    );

    // 判断图片类型
    if (normalizedPath.startsWith('data:image/')) {
      // Base64图片
      try {
        final base64String = normalizedPath.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorWidget,
        );
      } catch (e) {
        return errorWidget;
      }
    } else if (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://')) {
      // 网络图片
      return CachedNetworkImage(
        imageUrl: normalizedPath,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surface,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => errorWidget,
      );
    } else if (normalizedPath.startsWith('assets/')) {
      // 资源图片
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else if (!kIsWeb) {
      // 本地文件图片（仅非Web端）
      final file = File(normalizedPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorWidget,
        );
      } else {
        return errorWidget;
      }
    } else {
      return errorWidget;
    }
  }

  /// 构建元信息
  Widget _buildMetaInfo(Recipe recipe) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(widget.recipeId));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InfoChip(
          icon: Icons.category,
          label: recipe.categoryName,
          color: AppColors.secondary,
        ),
        // 难度星星
        Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              recipe.difficulty.clamp(1, 5),
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
        // 收藏按钮
        isFavoriteAsync.when(
          data: (isFavorite) => ActionChip(
            avatar: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.error : AppColors.textSecondary,
              size: 18,
            ),
            label: Text(
              isFavorite ? '已收藏' : '收藏',
              style: TextStyle(
                color: isFavorite ? AppColors.error : AppColors.textPrimary,
                fontWeight: isFavorite ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            backgroundColor: isFavorite
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.surface,
            side: BorderSide(
              color: isFavorite
                  ? AppColors.error.withValues(alpha: 0.3)
                  : AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            onPressed: () => _toggleFavorite(recipe.id),
          ),
          loading: () => const SizedBox(
            width: 80,
            height: 32,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => ActionChip(
            avatar: const Icon(Icons.favorite_border, size: 18),
            label: const Text('收藏'),
            onPressed: () => _toggleFavorite(recipe.id),
          ),
        ),
      ],
    );
  }

  /// 构建食材清单
  Widget _buildIngredients(Recipe recipe) {
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
              children: recipe.ingredients.asMap().entries.map((entry) {
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
                          entry.value.text,
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

  /// 构建工具列表
  Widget _buildTools(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.kitchen, color: AppColors.secondary, size: 24),
            const SizedBox(width: 8),
            Text('所需工具', style: AppTextStyles.h2),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recipe.tools.map((tool) {
            return Chip(
              label: Text(tool),
              avatar: const Icon(Icons.check, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建制作步骤
  Widget _buildSteps(Recipe recipe) {
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
        ...recipe.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return _StepCard(
            stepNumber: index + 1,
            description: step.description,
          );
        }),
      ],
    );
  }

  /// 构建小贴士
  Widget _buildTips(Recipe recipe) {
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
            LinkableTextRich(
              recipe.tips!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建警告信息
  Widget _buildWarnings(Recipe recipe) {
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
            ...recipe.warnings.map((warning) {
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
                      child: LinkableTextRich(
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

  /// 构建用户备注
  Widget _buildUserNote(Recipe recipe) {
    final noteAsync = ref.watch(userNoteProvider(widget.recipeId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: AppColors.secondary, size: 24),
                const SizedBox(width: 8),
                Text('我的备注', style: AppTextStyles.h3),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showNoteDialog(recipe),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            noteAsync.when(
              data: (note) => Text(
                note ?? '暂无备注，点击右上角编辑按钮添加备注',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: note == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontStyle: note == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                '加载备注失败',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
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
          Text('正在加载菜谱...'),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorState(BuildContext context, Object error) {
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
                ref.invalidate(recipeByIdProvider(widget.recipeId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              '菜谱不存在',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '该菜谱可能已被删除',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回列表'),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(String recipeId) async {
    try {
      final repository = ref.read(recipeRepositoryProvider);
      await repository.toggleFavorite(recipeId);

      // 刷新相关provider
      ref.invalidate(isFavoriteProvider(recipeId));
      ref.invalidate(favoriteRecipesProvider);
      ref.invalidate(favoriteIdsProvider);
      ref.invalidate(recipeByIdProvider(recipeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('收藏状态已更新'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 显示备注编辑对话框
  void _showNoteDialog(Recipe recipe) async {
    final currentNote = await ref.read(userNoteProvider(widget.recipeId).future);
    _noteController.text = currentNote ?? '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑备注'),
        content: TextField(
          controller: _noteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '在这里记录你的烹饪心得...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => _saveNote(recipe),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 保存备注
  Future<void> _saveNote(Recipe recipe) async {
    try {
      final repository = ref.read(recipeRepositoryProvider);
      final note = _noteController.text.trim();

      await repository.updateUserNote(
        widget.recipeId,
        note.isEmpty ? null : note,
      );

      // 刷新备注
      ref.invalidate(userNoteProvider(widget.recipeId));
      ref.invalidate(recipeByIdProvider(widget.recipeId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('备注已保存'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 处理菜单操作
  void _handleMenuAction(BuildContext context, Recipe recipe, String action) {
    switch (action) {
      case 'edit':
        context.push('/recipe/${recipe.id}/edit');
        break;
      case 'share':
        _showShareDialog(context, recipe);
        break;
    }
  }

  /// 显示分享选项对话框
  void _showShareDialog(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '分享菜谱',
                style: AppTextStyles.h3,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.content_copy, color: AppColors.primary),
              title: const Text('复制文字'),
              subtitle: const Text('将菜谱复制到剪贴板'),
              onTap: () async {
                Navigator.pop(context);
                await _shareAsText(recipe);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.secondary),
              title: const Text('生成图片'),
              subtitle: const Text('带二维码的精美卡片，可保存或分享'),
              onTap: () {
                Navigator.pop(context);
                _showImageShareOptions(recipe); // 不传递context
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 显示图片分享预览（生成图片并显示预览对话框）
  Future<void> _showImageShareOptions(Recipe recipe) async {
    // 不再接受context参数，直接使用widget的context
    if (!mounted) return;

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在生成图片...'),
              ],
            ),
          ),
        ),
      ),
    );

    Uint8List? imageBytes;
    bool hasError = false;
    String? errorMessage;

    try {
      // 生成图片
      final shareService = ref.read(recipeShareServiceProvider);
      final qrData = shareService.generateQRData(recipe);

      final screenshotController = ScreenshotController();
      imageBytes = await screenshotController.captureFromWidget(
        // ✨ 长截图方案：使用UnconstrainedBox移除所有父级约束
        Directionality(
          textDirection: TextDirection.ltr,
          child: UnconstrainedBox(
            child: SizedBox(
              width: 375, // 只约束宽度
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 50000), // 提供超大高度空间
                  devicePixelRatio: 2.0,
                  textScaleFactor: 1.0,
                ),
                child: RecipeShareCard(
                  recipe: recipe,
                  qrData: qrData,
                ),
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 800), // 确保二维码渲染完成
        pixelRatio: 2.0, // 提高图片质量
      );
    } catch (e) {
      debugPrint('生成图片异常: $e');
      hasError = true;
      errorMessage = e.toString();
    }

    // 关闭加载对话框（使用try-catch确保安全）
    if (!mounted) return;

    try {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('关闭对话框失败: $e');
    }

    if (!mounted) return;

    // 处理错误情况
    if (hasError || imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成图片失败: ${errorMessage ?? "未知错误"}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 显示预览对话框（再次检查mounted）
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => _ImageSharePreviewDialog(
        imageBytes: imageBytes!,
        recipe: recipe,
        onSave: () => _saveImageToGallery(imageBytes!, recipe),
        onShare: () => _shareImageBytes(imageBytes!, recipe),
      ),
    );
  }

  /// 保存图片字节到相册
  Future<void> _saveImageToGallery(Uint8List imageBytes, Recipe recipe) async {
    try {
      await Gal.putImageBytes(
        imageBytes,
        name: 'recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 图片已保存到相册'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 分享图片字节
  Future<void> _shareImageBytes(Uint8List imageBytes, Recipe recipe) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/recipe_${recipe.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '分享食谱：${recipe.name}',
      );

      // 清理临时文件
      try {
        await file.delete();
      } catch (e) {
        debugPrint('清理临时文件失败: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 分享为纯文本
  Future<void> _shareAsText(Recipe recipe) async {
    try {
      // 导入分享服务
      final shareService = ref.read(recipeShareServiceProvider);
      final result = await shareService.shareAsText(recipe);

      if (!mounted) return;

      switch (result) {
        case RecipeShareResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 已复制到剪贴板'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.success,
            ),
          );
          break;
        case RecipeShareResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 复制失败，请重试'),
              backgroundColor: AppColors.error,
            ),
          );
          break;
        case RecipeShareResult.cancelled:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分享失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 分享为图片
  Future<void> _shareAsImage(Recipe recipe, {bool saveOnly = false}) async {
    // 显示加载提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(saveOnly ? '正在生成并保存图片...' : '正在生成图片...'),
            ],
          ),
          duration: const Duration(seconds: 10), // 较长的持续时间
        ),
      );
    }

    try {
      // 导入分享服务
      final shareService = ref.read(recipeShareServiceProvider);
      final result = await shareService.shareAsImage(recipe, saveOnly: saveOnly);

      if (!mounted) return;

      // 关闭加载提示
      ScaffoldMessenger.of(context).clearSnackBars();

      switch (result) {
        case RecipeShareResult.success:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saveOnly ? '✅ 图片已保存到相册' : '✅ 分享成功'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.success,
            ),
          );
          break;
        case RecipeShareResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(saveOnly ? '❌ 保存失败，请检查相册权限' : '❌ 分享失败，请重试'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: () => _shareAsImage(recipe, saveOnly: saveOnly),
              ),
            ),
          );
          break;
        case RecipeShareResult.cancelled:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消分享'),
              duration: Duration(seconds: 1),
            ),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// 信息标签组件
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: color),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}

/// 步骤卡片组件
class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String description;

  const _StepCard({
    required this.stepNumber,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                  '$stepNumber',
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
              child: LinkableTextRich(
                description,
                style: AppTextStyles.cookingStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片分享预览对话框
class _ImageSharePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final Recipe recipe;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _ImageSharePreviewDialog({
    required this.imageBytes,
    required this.recipe,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '分享预览',
                  style: AppTextStyles.h3,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 图片预览区域
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 底部操作按钮区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行：保存到相册
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSave();
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('保存到相册'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 第二行：分享图标按钮
                Row(
                  children: [
                    Expanded(
                      child: _ShareButton(
                        icon: Icons.wechat,
                        label: '微信',
                        color: const Color(0xFF07C160),
                        onTap: () {
                          Navigator.pop(context);
                          onShare();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ShareButton(
                        icon: Icons.chat_bubble,
                        label: 'QQ',
                        color: const Color(0xFF12B7F5),
                        onTap: () {
                          Navigator.pop(context);
                          onShare();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ShareButton(
                        icon: Icons.share,
                        label: '更多',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.pop(context);
                          onShare();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 分享按钮组件
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
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
      ),
    );
  }
}
