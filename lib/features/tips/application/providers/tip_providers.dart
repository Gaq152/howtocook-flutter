import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recipe/application/providers/recipe_providers.dart'
    show bundledDataLoaderProvider;
import '../../domain/entities/tip.dart';
import '../../domain/repositories/tip_repository.dart';
import '../../infrastructure/repositories/tip_repository_impl.dart';
import '../../infrastructure/services/tip_share_service.dart';

/// TipShareService Provider
final tipShareServiceProvider = Provider<TipShareService>((ref) {
  return TipShareService();
});

/// TipRepository Provider
final tipRepositoryProvider = Provider<TipRepository>((ref) {
  final loader = ref.watch(bundledDataLoaderProvider);
  return TipRepositoryImpl(loader);
});

/// 所有教程 Provider
final allTipsProvider = FutureProvider<List<Tip>>((ref) async {
  final repository = ref.watch(tipRepositoryProvider);
  return repository.getAllTips();
});

/// 按分类获取教程 Provider
final tipsByCategoryProvider = FutureProvider.family<List<Tip>, String>((
  ref,
  category,
) async {
  final repository = ref.watch(tipRepositoryProvider);
  return repository.getTipsByCategory(category);
});

/// 根据 ID 获取教程 Provider
final tipByIdProvider = FutureProvider.family<Tip?, String>((ref, tipId) async {
  final repository = ref.watch(tipRepositoryProvider);
  return repository.getTipById(tipId);
});

/// 教程收藏 ID 列表 Provider
final favoriteTipIdsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(tipRepositoryProvider);
  return repository.getFavoriteTipIds();
});

/// 教程收藏状态 Provider
final isTipFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  tipId,
) async {
  final repository = ref.watch(tipRepositoryProvider);
  return repository.isFavorite(tipId);
});

/// 收藏的教程列表 Provider
final favoriteTipsProvider = FutureProvider<List<Tip>>((ref) async {
  final repository = ref.watch(tipRepositoryProvider);
  return repository.getFavoriteTips();
});
