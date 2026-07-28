import 'package:flutter/foundation.dart';

import '../storage/hive_service.dart';

/// 将 V1 路径型菜谱 ID 迁移为 V2 稳定 UUID。
///
/// 迁移是幂等的：新键总是先写入，旧键最后删除，成功后才记录版本标记。
class RecipeIdMigrationService {
  static const String activeDataVersionKey = 'active_recipe_data_version';
  static const String activeDataSchemaKey = 'active_recipe_data_schema';
  static const String _markerPrefix = 'recipe_id_migration_completed_';

  Future<RecipeIdMigrationResult> migrate(
    Map<String, dynamic> migrationJson,
  ) async {
    final dataVersion = migrationJson['dataVersion'] as String? ?? 'unknown';
    final markerKey = '$_markerPrefix$dataVersion';
    final settings = HiveService.getSettingsBox();
    if (settings.get(markerKey) == true) {
      await _recordActiveVersion(settings, dataVersion);
      return RecipeIdMigrationResult(dataVersion: dataVersion, skipped: true);
    }

    final mappings = _parseMappings(migrationJson);
    var favorites = 0;
    var notes = 0;
    var modifiedRecipes = 0;
    var chatRecords = 0;
    var settingsRecords = 0;

    final favoritesBox = HiveService.getFavoritesBox();
    for (final entry in mappings.entries) {
      if (!favoritesBox.containsKey(entry.key)) continue;
      await favoritesBox.put(entry.value, entry.value);
      await favoritesBox.delete(entry.key);
      favorites++;
    }

    final notesBox = HiveService.getUserNotesBox();
    for (final entry in mappings.entries) {
      if (!notesBox.containsKey(entry.key)) continue;
      final note = notesBox.get(entry.key);
      if (note != null && !notesBox.containsKey(entry.value)) {
        await notesBox.put(entry.value, note);
      }
      await notesBox.delete(entry.key);
      notes++;
    }

    final modifiedBox = HiveService.getModifiedRecipesBox();
    for (final entry in mappings.entries) {
      if (!modifiedBox.containsKey(entry.key)) continue;
      final original = modifiedBox.get(entry.key);
      if (original != null && !modifiedBox.containsKey(entry.value)) {
        final recipe = HiveService.deepConvertMap(original);
        recipe['id'] = entry.value;
        final legacyIds = <String>{
          entry.key,
          ...((recipe['legacyIds'] as List?)?.map((id) => id.toString()) ??
              const <String>[]),
        };
        recipe['legacyIds'] = legacyIds.toList();
        await modifiedBox.put(entry.value, recipe);
      }
      await modifiedBox.delete(entry.key);
      modifiedRecipes++;
    }

    final chatBox = HiveService.getChatHistoryBox();
    for (final key in chatBox.keys.toList()) {
      final value = chatBox.get(key);
      if (value == null) continue;
      final replacement = replaceRecipeIds(value, mappings);
      if (replacement.changed && replacement.value is Map) {
        await chatBox.put(
          key,
          Map<dynamic, dynamic>.from(replacement.value as Map),
        );
        chatRecords++;
      }
    }

    for (final key in settings.keys.toList()) {
      if (key == markerKey ||
          key == activeDataVersionKey ||
          key == activeDataSchemaKey) {
        continue;
      }
      final value = settings.get(key);
      final replacement = replaceRecipeIds(value, mappings);
      if (replacement.changed) {
        await settings.put(key, replacement.value);
        settingsRecords++;
      }
    }

    await settings.put(markerKey, true);
    await _recordActiveVersion(settings, dataVersion);

    final result = RecipeIdMigrationResult(
      dataVersion: dataVersion,
      mappings: mappings.length,
      favorites: favorites,
      notes: notes,
      modifiedRecipes: modifiedRecipes,
      chatRecords: chatRecords,
      settingsRecords: settingsRecords,
    );
    debugPrint('✅ 菜谱 ID 迁移完成: $result');
    return result;
  }

  Map<String, String> _parseMappings(Map<String, dynamic> json) {
    final result = <String, String>{};
    for (final item in json['mappings'] as List<dynamic>? ?? const []) {
      if (item is! Map) continue;
      final oldId = item['oldId']?.toString();
      final newId = item['newId']?.toString();
      if (oldId == null || oldId.isEmpty || newId == null || newId.isEmpty) {
        continue;
      }
      result[oldId] = newId;
    }
    return result;
  }

  Future<void> _recordActiveVersion(
    dynamic settings,
    String dataVersion,
  ) async {
    await settings.put(activeDataVersionKey, dataVersion);
    await settings.put(activeDataSchemaKey, 2);
  }
}

/// 递归替换 Hive JSON 中与旧 ID 完全相等的字符串。
RecipeIdReplacement replaceRecipeIds(
  dynamic value,
  Map<String, String> mappings,
) {
  if (value is String) {
    final replacement = mappings[value];
    return RecipeIdReplacement(
      value: replacement ?? value,
      changed: replacement != null,
    );
  }

  if (value is Map) {
    var changed = false;
    final output = <dynamic, dynamic>{};
    value.forEach((key, item) {
      final replaced = replaceRecipeIds(item, mappings);
      output[key] = replaced.value;
      changed = changed || replaced.changed;
    });
    return RecipeIdReplacement(value: output, changed: changed);
  }

  if (value is List) {
    var changed = false;
    final output = value.map((item) {
      final replaced = replaceRecipeIds(item, mappings);
      changed = changed || replaced.changed;
      return replaced.value;
    }).toList();
    return RecipeIdReplacement(value: output, changed: changed);
  }

  return RecipeIdReplacement(value: value, changed: false);
}

class RecipeIdReplacement {
  final dynamic value;
  final bool changed;

  const RecipeIdReplacement({required this.value, required this.changed});
}

class RecipeIdMigrationResult {
  final String dataVersion;
  final bool skipped;
  final int mappings;
  final int favorites;
  final int notes;
  final int modifiedRecipes;
  final int chatRecords;
  final int settingsRecords;

  const RecipeIdMigrationResult({
    required this.dataVersion,
    this.skipped = false,
    this.mappings = 0,
    this.favorites = 0,
    this.notes = 0,
    this.modifiedRecipes = 0,
    this.chatRecords = 0,
    this.settingsRecords = 0,
  });

  @override
  String toString() =>
      'RecipeIdMigrationResult(version: $dataVersion, skipped: $skipped, '
      'mappings: $mappings, favorites: $favorites, notes: $notes, '
      'modifiedRecipes: $modifiedRecipes, chatRecords: $chatRecords, '
      'settingsRecords: $settingsRecords)';
}
