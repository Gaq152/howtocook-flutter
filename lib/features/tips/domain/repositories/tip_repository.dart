import '../entities/tip.dart';

/// 教程仓储接口
abstract class TipRepository {
  Future<List<Tip>> getAllTips();

  Future<List<Tip>> getTipsByCategory(String category);

  Future<Tip?> getTipById(String tipId);

  Future<void> saveTip(Tip tip);

  Future<void> deleteTip(String tipId);

  Future<void> toggleFavorite(String tipId, bool isFavorite);

  Future<bool> isFavorite(String tipId);

  Future<List<String>> getFavoriteTipIds();

  Future<List<Tip>> getFavoriteTips();
}
