import 'dart:convert';
import 'package:flutter/services.dart';
import '../../recipe/domain/entities/recipe.dart';
import '../../tips/domain/entities/tip.dart';
import '../domain/entities/manifest.dart';

/// 内置资源加载器
///
/// 负责从 assets 目录加载打包的菜谱数据和清单文件
class BundledDataLoader {
  /// 加载清单文件
  ///
  /// 从 manifest.json 加载菜谱索引清单
  Future<Manifest> loadManifest() async {
    try {
      // manifest.json 是单个文件声明，需要完整路径
      final jsonString = await rootBundle.loadString('assets/manifest.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return Manifest.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load manifest: $e');
    }
  }

  /// 加载单个菜谱
  ///
  /// 根据菜谱 ID 加载对应的 JSON 文件
  /// 路径格式: assets/recipes/{category}/{id}.json
  ///
  /// 例如: aquatic_17b4109a → assets/recipes/aquatic/aquatic_17b4109a.json
  Future<Recipe> loadRecipe(String recipeId) async {
    try {
      // 从 ID 提取分类（ID 格式: {category}_{hash}）
      final category = _extractCategory(recipeId);
      // 路径必须与 pubspec.yaml 声明一致，包含 assets/ 前缀
      final path = 'assets/recipes/$category/$recipeId.json';

      final jsonString = await rootBundle.loadString(path);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 规范化图片路径（将反斜杠转换为正斜杠，并添加 assets/ 前缀）
      if (jsonData['images'] is List) {
        final images = jsonData['images'] as List;
        jsonData['images'] = images.map((img) {
          if (img is String) {
            // 转换反斜杠为正斜杠
            var path = img.replaceAll('\\', '/');
            // 添加 assets/ 前缀（如果还没有的话）
            if (!path.startsWith('assets/')) {
              path = 'assets/$path';
            }
            return path;
          }
          return img;
        }).toList();
      }

      return Recipe.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load recipe $recipeId: $e');
    }
  }

  /// 批量加载菜谱
  ///
  /// 加载多个菜谱，返回成功加载的菜谱列表
  /// 失败的菜谱会被跳过并记录错误
  Future<List<Recipe>> loadRecipes(List<String> recipeIds) async {
    final recipes = <Recipe>[];

    for (final id in recipeIds) {
      try {
        final recipe = await loadRecipe(id);
        recipes.add(recipe);
      } catch (e) {
        // 记录错误但继续加载其他菜谱
        print('Warning: Failed to load recipe $id: $e');
      }
    }

    return recipes;
  }

  /// 加载所有菜谱
  ///
  /// 从 manifest 获取所有菜谱 ID，然后批量加载
  Future<List<Recipe>> loadAllRecipes() async {
    final manifest = await loadManifest();
    final recipeIds = manifest.recipes.map((r) => r.id).toList();
    return loadRecipes(recipeIds);
  }

  /// 根据分类加载菜谱
  ///
  /// 从 manifest 筛选指定分类的菜谱，然后批量加载
  Future<List<Recipe>> loadRecipesByCategory(String category) async {
    final manifest = await loadManifest();
    final recipeIds = manifest.recipes
        .where((r) => r.category == category)
        .map((r) => r.id)
        .toList();
    return loadRecipes(recipeIds);
  }

  /// 加载单个教程
  ///
  /// 路径格式: assets/tips/{category}/{tipId}.json
  Future<Tip> loadTip(String category, String tipId) async {
    try {
      final path = getTipPath(category, tipId);
      final jsonString = await rootBundle.loadString(path);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return Tip.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load tip $tipId: $e');
    }
  }

  /// 根据 ID 加载教程（自动匹配分类）
  Future<Tip?> loadTipById(String tipId) async {
    try {
      final manifest = await loadManifest();
      TipIndex? target;
      for (final tipIndex in manifest.tips) {
        if (tipIndex.id == tipId) {
          target = tipIndex;
          break;
        }
      }

      if (target == null) {
        return null;
      }

      return loadTip(target.category, target.id);
    } catch (e) {
      print('Warning: Failed to load tip $tipId: $e');
      return null;
    }
  }

  /// 批量加载教程
  Future<List<Tip>> loadTips(List<TipIndex> indices) async {
    final tips = <Tip>[];
    for (final index in indices) {
      try {
        final tip = await loadTip(index.category, index.id);
        tips.add(tip);
      } catch (e) {
        print('Warning: Failed to load tip ${index.id}: $e');
      }
    }
    return tips;
  }

  /// 加载全部教程
  Future<List<Tip>> loadAllTips() async {
    final manifest = await loadManifest();
    return loadTips(manifest.tips);
  }

  /// 根据分类加载教程
  Future<List<Tip>> loadTipsByCategory(String category) async {
    final manifest = await loadManifest();
    final indices = manifest.tips.where((t) => t.category == category).toList();
    return loadTips(indices);
  }

  /// 从菜谱 ID 提取分类
  ///
  /// ID 格式: {category}_{hash}
  /// 例如: aquatic_17b4109a → aquatic
  ///      meat_dish_bc5b39f0 → meat_dish
  String _extractCategory(String recipeId) {
    final parts = recipeId.split('_');
    if (parts.length < 2) {
      throw ArgumentError('Invalid recipe ID format: $recipeId');
    }
    // 返回除了最后一部分（hash）之外的所有部分
    return parts.sublist(0, parts.length - 1).join('_');
  }

  /// 获取菜谱资源路径
  ///
  /// 根据菜谱 ID 生成完整的资源路径
  String getRecipePath(String recipeId) {
    final category = _extractCategory(recipeId);
    return 'assets/recipes/$category/$recipeId.json';
  }

  /// 获取教程资源路径
  String getTipPath(String category, String tipId) {
    return 'assets/tips/$category/$tipId.json';
  }

  /// 获取图片资源路径
  ///
  /// 将相对路径转换为完整的 assets 路径
  /// 例如: images/aquatic/xxx.webp → assets/images/aquatic/xxx.webp
  String getImagePath(String relativePath) {
    // 如果已经有 assets/ 前缀，直接返回
    if (relativePath.startsWith('assets/')) {
      return relativePath;
    }
    // 否则添加 assets/ 前缀
    return 'assets/$relativePath';
  }
}
