import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/services/mcp_service.dart';
import '../../../recipe/domain/entities/recipe.dart';

/// MCP 服务 Provider
final mcpServiceProvider = Provider<MCPService>((ref) {
  return MCPService();
});

/// 搜索菜谱 Provider
final searchRecipesProvider = FutureProvider.family<List<Recipe>, String>((ref, query) async {
  final mcpService = ref.watch(mcpServiceProvider);
  return mcpService.searchRecipes(query);
});

/// 获取菜谱详情 Provider
final mcpRecipeDetailProvider = FutureProvider.family<Recipe, String>((ref, recipeId) async {
  final mcpService = ref.watch(mcpServiceProvider);
  return mcpService.getRecipeDetail(recipeId);
});

/// 获取随机菜谱 Provider
final randomRecipesProvider = FutureProvider.family<List<Recipe>, int>((ref, count) async {
  final mcpService = ref.watch(mcpServiceProvider);
  return mcpService.getRandomRecipes(count: count);
});

/// 按分类获取菜谱 Provider
final mcpRecipesByCategoryProvider = FutureProvider.family<List<Recipe>, String>((ref, category) async {
  final mcpService = ref.watch(mcpServiceProvider);
  return mcpService.getRecipesByCategory(category);
});

/// 获取收藏菜谱 Provider
final mcpFavoriteRecipesProvider = FutureProvider.family<List<Recipe>, List<String>>((ref, favoriteIds) async {
  final mcpService = ref.watch(mcpServiceProvider);
  return mcpService.getFavoriteRecipes(favoriteIds);
});
