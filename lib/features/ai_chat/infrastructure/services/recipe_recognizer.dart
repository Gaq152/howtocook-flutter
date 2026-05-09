import '../../../../core/storage/hive_service.dart';
import '../../../sync/domain/entities/manifest.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';
import '../../../recipe/domain/entities/recipe.dart';

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

  factory RecipeCardData.fromIndex(RecipeIndex index) {
    return RecipeCardData(
      id: index.id,
      name: index.name,
      category: index.category,
      categoryName: index.categoryName,
      difficulty: index.difficulty,
    );
  }

  factory RecipeCardData.fromRecipe(Recipe recipe) {
    return RecipeCardData(
      id: recipe.id,
      name: recipe.name,
      category: recipe.category,
      categoryName: recipe.categoryName,
      difficulty: recipe.difficulty,
    );
  }
}

/// 菜谱识别服务
///
/// 从 AI 回复文本中识别菜谱名称，与内置索引和本地用户菜谱比对
class RecipeRecognizer {
  final BundledDataLoader _dataLoader;
  Manifest? _cachedManifest;
  List<RecipeCardData>? _cachedLocalRecipes;

  RecipeRecognizer(this._dataLoader);

  /// 从文本中提取菜谱引用
  Future<List<RecipeCardData>> extractRecipesFromText(String text) async {
    _cachedManifest ??= await _dataLoader.loadManifest();
    _cachedLocalRecipes ??= _loadLocalRecipes();

    final matchedRecipes = <RecipeCardData>[];
    final matchedIds = <String>{};

    // 1. 内置/云端菜谱
    for (final recipeIndex in _cachedManifest!.recipes) {
      if (text.contains(recipeIndex.name)) {
        matchedRecipes.add(RecipeCardData.fromIndex(recipeIndex));
        matchedIds.add(recipeIndex.id);
      }
    }

    // 2. 本地用户菜谱（AI 保存的、扫码、手动创建的）
    for (final localRecipe in _cachedLocalRecipes!) {
      if (!matchedIds.contains(localRecipe.id) && text.contains(localRecipe.name)) {
        matchedRecipes.add(localRecipe);
      }
    }

    return matchedRecipes;
  }

  List<RecipeCardData> _loadLocalRecipes() {
    final box = HiveService.getModifiedRecipesBox();
    final recipes = <RecipeCardData>[];
    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data == null) continue;
        final name = data['name']?.toString();
        if (name == null || name.isEmpty) continue;
        recipes.add(RecipeCardData(
          id: data['id']?.toString() ?? key.toString(),
          name: name,
          category: data['category']?.toString() ?? 'unknown',
          categoryName: data['categoryName']?.toString() ?? '其他',
          difficulty: (data['difficulty'] as int?) ?? 3,
        ));
      } catch (_) {
        continue;
      }
    }
    return recipes;
  }

  void clearCache() {
    _cachedManifest = null;
    _cachedLocalRecipes = null;
  }
}

