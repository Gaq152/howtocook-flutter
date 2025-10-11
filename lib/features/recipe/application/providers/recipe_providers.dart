import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../infrastructure/repositories/recipe_repository_impl.dart';
import '../../../sync/infrastructure/bundled_data_loader.dart';
import '../../../sync/domain/entities/manifest.dart';

/// BundledDataLoader Provider
final bundledDataLoaderProvider = Provider<BundledDataLoader>((ref) {
  return BundledDataLoader();
});

/// RecipeRepository Provider
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final bundledLoader = ref.watch(bundledDataLoaderProvider);
  return RecipeRepositoryImpl(bundledLoader);
});

/// 所有菜谱 Provider
final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getAllRecipes();
});

/// 根据 ID 获取菜谱 Provider
final recipeByIdProvider = FutureProvider.family<Recipe?, String>((ref, id) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipeById(id);
});

/// 根据分类获取菜谱 Provider
final recipesByCategoryProvider = FutureProvider.family<List<Recipe>, String>((ref, category) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesByCategory(category);
});

/// 搜索菜谱 Provider
final searchRecipesProvider = FutureProvider.family<List<Recipe>, String>((ref, query) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.searchRecipes(query);
});

/// 收藏菜谱 Provider
final favoriteRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getFavoriteRecipes();
});

/// 收藏 ID 列表 Provider
final favoriteIdsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getFavoriteIds();
});

/// 检查是否收藏 Provider
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, id) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.isFavorite(id);
});

/// 获取用户笔记 Provider
final userNoteProvider = FutureProvider.family<String?, String>((ref, id) async {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getUserNote(id);
});

/// 获取 Manifest Provider（用于分类筛选等）
final manifestProvider = FutureProvider<Manifest>((ref) async {
  final bundledLoader = ref.watch(bundledDataLoaderProvider);
  return bundledLoader.loadManifest();
});
