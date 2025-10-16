import '../../../sync/infrastructure/bundled_data_loader.dart';
import '../../../../core/storage/hive_service.dart';
import '../../domain/entities/tip.dart';
import '../../domain/repositories/tip_repository.dart';

class TipRepositoryImpl implements TipRepository {
  TipRepositoryImpl(this._bundledLoader);

  final BundledDataLoader _bundledLoader;

  @override
  Future<List<Tip>> getAllTips() async {
    try {
      final tips = <Tip>[];
      final loadedIds = <String>{};

      final modifiedBox = HiveService.getModifiedTipsBox();
      for (final key in modifiedBox.keys) {
        try {
          final raw = modifiedBox.get(key);
          if (raw is! Map) continue;
          final converted = _deepConvertMap(raw as Map<dynamic, dynamic>);
          final tip = Tip.fromJson(converted);
          final isFav = await isFavorite(tip.id);

          tips.add(tip.copyWith(isFavorite: isFav));
          loadedIds.add(tip.id);
        } catch (e) {
          print('Warning: Failed to load modified tip $key: $e');
        }
      }

      final manifest = await _bundledLoader.loadManifest();
      for (final tipIndex in manifest.tips) {
        if (loadedIds.contains(tipIndex.id)) {
          continue;
        }

        try {
          final tip = await _bundledLoader.loadTip(
            tipIndex.category,
            tipIndex.id,
          );
          final isFav = await isFavorite(tip.id);

          tips.add(tip.copyWith(isFavorite: isFav));
        } catch (e) {
          print('Warning: Failed to load tip ${tipIndex.id}: $e');
        }
      }

      return tips;
    } catch (e) {
      throw Exception('Failed to load tips: $e');
    }
  }

  @override
  Future<List<Tip>> getTipsByCategory(String category) async {
    final allTips = await getAllTips();
    return allTips.where((tip) => tip.category == category).toList();
  }

  @override
  Future<Tip?> getTipById(String tipId) async {
    try {
      final modifiedBox = HiveService.getModifiedTipsBox();
      if (modifiedBox.containsKey(tipId)) {
        final raw = modifiedBox.get(tipId);
        if (raw is Map) {
          final converted = _deepConvertMap(raw as Map<dynamic, dynamic>);
          final tip = Tip.fromJson(converted);
          final isFav = await isFavorite(tipId);
          return tip.copyWith(isFavorite: isFav);
        }
      }

      final manifest = await _bundledLoader.loadManifest();
      final tipIndex = manifest.tips.firstWhere(
        (t) => t.id == tipId,
        orElse: () => throw Exception('Tip not found: $tipId'),
      );

      final tip = await _bundledLoader.loadTip(tipIndex.category, tipIndex.id);
      final isFav = await isFavorite(tip.id);
      return tip.copyWith(isFavorite: isFav);
    } catch (e) {
      print('Warning: Failed to load tip $tipId: $e');
      return null;
    }
  }

  @override
  Future<void> saveTip(Tip tip) async {
    try {
      final modifiedBox = HiveService.getModifiedTipsBox();
      final now = DateTime.now();
      final createdAt = tip.createdAt ?? now;
      final tipToSave = tip.copyWith(createdAt: createdAt, updatedAt: now);
      final data = tipToSave.toJson();

      await modifiedBox.put(tip.id, data);
    } catch (e) {
      throw Exception('Failed to save tip ${tip.id}: $e');
    }
  }

  @override
  Future<void> deleteTip(String tipId) async {
    try {
      final modifiedBox = HiveService.getModifiedTipsBox();
      if (!modifiedBox.containsKey(tipId)) {
        throw Exception('Tip not found: $tipId');
      }

      await modifiedBox.delete(tipId);

      final favBox = HiveService.getFavoriteTipsBox();
      if (favBox.containsKey(tipId)) {
        await favBox.delete(tipId);
      }
    } catch (e) {
      throw Exception('Failed to delete tip $tipId: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String tipId, bool shouldFavorite) async {
    try {
      final favBox = HiveService.getFavoriteTipsBox();
      if (shouldFavorite) {
        await favBox.put(tipId, tipId);
      } else {
        await favBox.delete(tipId);
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite for tip $tipId: $e');
    }
  }

  @override
  Future<bool> isFavorite(String tipId) async {
    try {
      final favBox = HiveService.getFavoriteTipsBox();
      return favBox.containsKey(tipId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getFavoriteTipIds() async {
    try {
      final favBox = HiveService.getFavoriteTipsBox();
      return favBox.keys.cast<String>().toList();
    } catch (e) {
      return [];
    }
  }

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
}
