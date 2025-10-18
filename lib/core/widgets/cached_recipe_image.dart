import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:howtocook/core/services/image_cache_service.dart';

/// 缓存食谱图片组件
/// 优先从本地缓存加载，缓存不存在则从 assets 加载，都不存在则显示占位图
class CachedRecipeImage extends ConsumerWidget {
  final String category;
  final String? recipeName;    // 封面图使用
  final String? recipeId;      // 详情图使用
  final int? imageIndex;       // 详情图索引
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedRecipeImage.cover({
    super.key,
    required this.category,
    required this.recipeName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  })  : recipeId = null,
        imageIndex = null;

  const CachedRecipeImage.detail({
    super.key,
    required this.category,
    required this.recipeId,
    required this.imageIndex,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : recipeName = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageCacheService = ref.read(imageCacheServiceProvider.notifier);

    return FutureBuilder<String?>(
      future: _getCachePath(imageCacheService),
      builder: (context, snapshot) {
        // 如果有缓存路径，使用缓存
        if (snapshot.hasData && snapshot.data != null) {
          return _buildFileImage(context, snapshot.data!);
        }

        // 没有缓存，直接尝试从 assets 加载（不显示 loading）
        final assetPath = _getAssetPath();
        if (assetPath != null) {
          return _buildAssetImage(context, assetPath);
        }

        // 都没有，显示错误占位图
        return _buildError(context);
      },
    );
  }

  /// 获取缓存路径（仅检查缓存，不检查 assets）
  Future<String?> _getCachePath(ImageCacheService service) async {
    if (recipeName != null) {
      // 封面图缓存
      return await service.getCoverImagePath(category, recipeName!);
    } else if (recipeId != null && imageIndex != null) {
      // 详情图缓存
      return await service.getDetailImagePath(category, recipeId!, imageIndex!);
    }
    return null;
  }

  /// 获取 asset 路径（同步，直接构建路径）
  String? _getAssetPath() {
    if (recipeName != null) {
      // 封面图 asset 路径
      return 'assets/covers/$category/$recipeName.webp';
    } else if (recipeId != null && imageIndex != null) {
      // 详情图 asset 路径
      return 'assets/images/$category/${recipeId}_$imageIndex.webp';
    }
    return null;
  }

  /// 构建文件图片（缓存）
  Widget _buildFileImage(BuildContext context, String filePath) {
    Widget image = Image.file(
      File(filePath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // 文件加载失败，尝试从 assets 加载
        final assetPath = _getAssetPath();
        if (assetPath != null) {
          return _buildAssetImage(context, assetPath);
        }
        return _buildError(context);
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  /// 构建 asset 图片
  Widget _buildAssetImage(BuildContext context, String assetPath) {
    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildError(context);
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildError(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// 占位图Widget - 用于显示默认占位图
class RecipePlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData icon;
  final String? text;

  const RecipePlaceholderImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.icon = Icons.restaurant_menu,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
