import '../../../sync/domain/entities/manifest.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';

/// 菜谱卡片数据
class RecipeCardData {
  final String id;
  final String name;
  final String category;
  final String categoryName;
  final int difficulty;

  RecipeCardData({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryName,
    required this.difficulty,
  });

  /// 从 RecipeIndex 创建
  factory RecipeCardData.fromIndex(RecipeIndex index) {
    return RecipeCardData(
      id: index.id,
      name: index.name,
      category: index.category,
      categoryName: index.categoryName,
      difficulty: index.difficulty,
    );
  }
}

/// 菜谱识别服务
///
/// 从 AI 回复文本中识别菜谱名称，并与本地菜谱索引比对
class RecipeRecognizer {
  final BundledDataLoader _dataLoader;
  Manifest? _cachedManifest;

  RecipeRecognizer(this._dataLoader);

  /// 从文本中提取菜谱引用
  ///
  /// 返回匹配到的菜谱卡片数据列表
  Future<List<RecipeCardData>> extractRecipesFromText(String text) async {
    // 加载 manifest 索引（使用缓存）
    _cachedManifest ??= await _dataLoader.loadManifest();

    final matchedRecipes = <RecipeCardData>[];

    // 遍历所有菜谱索引，查找名称匹配
    for (final recipeIndex in _cachedManifest!.recipes) {
      // 如果文本中包含菜谱名称，认为是匹配
      if (text.contains(recipeIndex.name)) {
        matchedRecipes.add(RecipeCardData.fromIndex(recipeIndex));
      }
    }

    return matchedRecipes;
  }

  /// 清除缓存（当需要重新加载数据时调用）
  void clearCache() {
    _cachedManifest = null;
  }
}

