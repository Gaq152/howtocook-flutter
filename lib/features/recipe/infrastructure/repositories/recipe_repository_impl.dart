import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';
import '../../../../core/storage/hive_service.dart';

/// 菜谱仓储实现类
///
/// 整合内置数据（BundledDataLoader）和本地数据（Hive）
class RecipeRepositoryImpl implements RecipeRepository {
  final BundledDataLoader _bundledLoader;

  RecipeRepositoryImpl(this._bundledLoader);

  @override
  Future<List<Recipe>> getAllRecipes() async {
    try {
      // 1. 加载所有内置菜谱
      final manifest = await _bundledLoader.loadManifest();
      final List<Recipe> recipes = [];

      // 2. 从 manifest 批量加载菜谱
      for (final recipeIndex in manifest.recipes) {
        try {
          final recipe = await _bundledLoader.loadRecipe(recipeIndex.id);

          // 3. 合并收藏和笔记信息
          final isFav = await isFavorite(recipe.id);
          final note = await getUserNote(recipe.id);

          recipes.add(recipe.copyWith(
            isFavorite: isFav,
            userNote: note,
          ));
        } catch (e) {
          // 跳过加载失败的菜谱
          print('Warning: Failed to load recipe ${recipeIndex.id}: $e');
        }
      }

      return recipes;
    } catch (e) {
      throw Exception('Failed to get all recipes: $e');
    }
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    try {
      // 1. 优先从Hive读取修改后的菜谱
      final modifiedBox = HiveService.getModifiedRecipesBox();
      if (modifiedBox.containsKey(id)) {
        final recipeJson = modifiedBox.get(id) as Map<dynamic, dynamic>;
        // 深度转换Map<dynamic, dynamic>为Map<String, dynamic>
        final convertedJson = _deepConvertMap(recipeJson);
        final recipe = Recipe.fromJson(convertedJson);

        // 2. 合并收藏和笔记信息
        final isFav = await isFavorite(id);
        final note = await getUserNote(id);

        return recipe.copyWith(
          isFavorite: isFav,
          userNote: note,
        );
      }

      // 3. 否则从内置数据加载
      final recipe = await _bundledLoader.loadRecipe(id);

      // 4. 合并收藏和笔记信息
      final isFav = await isFavorite(id);
      final note = await getUserNote(id);

      return recipe.copyWith(
        isFavorite: isFav,
        userNote: note,
      );
    } catch (e) {
      throw Exception('Failed to get recipe $id: $e');
    }
  }

  /// 深度转换Map<dynamic, dynamic>为Map<String, dynamic>
  Map<String, dynamic> _deepConvertMap(Map<dynamic, dynamic> source) {
    final result = <String, dynamic>{};
    source.forEach((key, value) {
      final stringKey = key.toString();
      if (value is Map) {
        result[stringKey] = _deepConvertMap(value as Map<dynamic, dynamic>);
      } else if (value is List) {
        result[stringKey] = _deepConvertList(value);
      } else {
        result[stringKey] = value;
      }
    });
    return result;
  }

  /// 深度转换List中的Map
  List<dynamic> _deepConvertList(List<dynamic> source) {
    return source.map((item) {
      if (item is Map) {
        return _deepConvertMap(item as Map<dynamic, dynamic>);
      } else if (item is List) {
        return _deepConvertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  @override
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      // 1. 从内置数据加载该分类的菜谱
      final recipes = await _bundledLoader.loadRecipesByCategory(category);

      // 2. 合并收藏和笔记信息
      final List<Recipe> result = [];
      for (final recipe in recipes) {
        final isFav = await isFavorite(recipe.id);
        final note = await getUserNote(recipe.id);

        result.add(recipe.copyWith(
          isFavorite: isFav,
          userNote: note,
        ));
      }

      return result;
    } catch (e) {
      throw Exception('Failed to get recipes by category $category: $e');
    }
  }

  @override
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAllRecipes();
      }

      // 1. 获取所有菜谱
      final allRecipes = await getAllRecipes();

      // 2. 过滤：名称、分类名称、食材包含关键词
      final lowerQuery = query.toLowerCase();
      return allRecipes.where((recipe) {
        // 搜索菜谱名称
        if (recipe.name.toLowerCase().contains(lowerQuery)) {
          return true;
        }

        // 搜索分类名称
        if (recipe.categoryName.toLowerCase().contains(lowerQuery)) {
          return true;
        }

        // 搜索食材
        for (final ingredient in recipe.ingredients) {
          if (ingredient.text.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }

        return false;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }

  @override
  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      // 1. 获取收藏 ID 列表
      final favoriteIds = await getFavoriteIds();

      // 2. 加载对应的菜谱
      final List<Recipe> favorites = [];
      for (final id in favoriteIds) {
        try {
          final recipe = await getRecipeById(id);
          if (recipe != null) {
            favorites.add(recipe);
          }
        } catch (e) {
          print('Warning: Failed to load favorite recipe $id: $e');
        }
      }

      return favorites;
    } catch (e) {
      throw Exception('Failed to get favorite recipes: $e');
    }
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    try {
      // 将Recipe转换为纯Map（Hive可以序列化的基本类型）
      final modifiedBox = HiveService.getModifiedRecipesBox();

      // 手动构建Map，确保所有值都是基本类型
      final recipeMap = <String, dynamic>{
        'id': recipe.id,
        'name': recipe.name,
        'category': recipe.category,
        'categoryName': recipe.categoryName,
        'difficulty': recipe.difficulty,
        'images': recipe.images,
        'ingredients': recipe.ingredients.map((i) => {
          'name': i.name,
          'text': i.text,
        }).toList(),
        'tools': recipe.tools,
        'steps': recipe.steps.map((s) => {
          'description': s.description,
        }).toList(),
        'tips': recipe.tips,
        'warnings': recipe.warnings,
        'hash': recipe.hash,
        'source': recipe.source.name,
        'isFavorite': recipe.isFavorite,
        'userNote': recipe.userNote,
        'createdAt': recipe.createdAt?.toIso8601String(),
        'updatedAt': recipe.updatedAt?.toIso8601String(),
      };

      await modifiedBox.put(recipe.id, recipeMap);
    } catch (e) {
      throw Exception('Failed to save recipe: $e');
    }
  }

  @override
  Future<void> deleteRecipe(String id) async {
    // T102 不实现删除功能
    // 这将在后续任务中实现
    throw UnimplementedError('Delete recipe will be implemented later');
  }

  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final favBox = HiveService.getFavoritesBox();

      if (favBox.containsKey(id)) {
        // 已收藏 → 取消收藏
        await favBox.delete(id);
      } else {
        // 未收藏 → 添加收藏
        await favBox.put(id, id);
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite for $id: $e');
    }
  }

  @override
  Future<bool> isFavorite(String id) async {
    try {
      final favBox = HiveService.getFavoritesBox();
      return favBox.containsKey(id);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateUserNote(String id, String? note) async {
    try {
      final noteBox = HiveService.getUserNotesBox();
      if (note == null || note.isEmpty) {
        // 删除笔记
        await noteBox.delete(id);
      } else {
        // 更新笔记
        await noteBox.put(id, note);
      }
    } catch (e) {
      throw Exception('Failed to update user note for $id: $e');
    }
  }

  @override
  Future<String?> getUserNote(String id) async {
    try {
      final noteBox = HiveService.getUserNotesBox();
      return noteBox.get(id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getFavoriteIds() async {
    try {
      final favBox = HiveService.getFavoritesBox();
      return favBox.keys.cast<String>().toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveRecipes(List<Recipe> recipes) async {
    // T102 不实现批量保存功能
    // 内置菜谱无需导入数据库，直接从 assets 加载即可
    throw UnimplementedError('Batch save is not needed for bundled recipes');
  }
}
