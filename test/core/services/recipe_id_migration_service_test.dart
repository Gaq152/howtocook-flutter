import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:howtocook/core/services/recipe_id_migration_service.dart';
import 'package:howtocook/core/storage/hive_service.dart';

void main() {
  test('recursively replaces only exact legacy recipe IDs', () {
    const oldId = 'soup_b942dbb7';
    const newId = '0032e10b-1f73-456f-b118-aeeb1749a312';
    final original = {
      'recipeId': oldId,
      'createdRecipeIds': [oldId, 'user_recipe_1'],
      'recipe': {'id': oldId, 'description': '文本中提到 $oldId 但不应部分替换'},
    };

    final result = replaceRecipeIds(original, const {oldId: newId});
    final migrated = result.value as Map<dynamic, dynamic>;

    expect(result.changed, isTrue);
    expect(migrated['recipeId'], newId);
    expect(migrated['createdRecipeIds'], [newId, 'user_recipe_1']);
    expect((migrated['recipe'] as Map)['id'], newId);
    expect((migrated['recipe'] as Map)['description'], '文本中提到 $oldId 但不应部分替换');
  });

  test('reports unchanged values without rebuilding semantics', () {
    final result = replaceRecipeIds(
      {'recipeId': 'user_recipe_1'},
      const {'soup_b942dbb7': 'uuid'},
    );

    expect(result.changed, isFalse);
    expect(result.value, {'recipeId': 'user_recipe_1'});
  });

  test('migrates persisted Hive keys and nested JSON idempotently', () async {
    const oldId = 'soup_b942dbb7';
    const newId = '0032e10b-1f73-456f-b118-aeeb1749a312';
    final tempDirectory = await Directory.systemTemp.createTemp(
      'howtocook-id-migration-',
    );
    Hive.init(tempDirectory.path);

    try {
      final favorites = await Hive.openBox<String>(HiveService.favoritesBox);
      final notes = await Hive.openBox<String>(HiveService.userNotesBox);
      final modified = await Hive.openBox<Map>(HiveService.modifiedRecipesBox);
      final chat = await Hive.openBox<Map>(HiveService.chatHistoryBox);
      final settings = await Hive.openBox(HiveService.settingsBox);

      await favorites.put(oldId, oldId);
      await notes.put(oldId, '少放盐');
      await modified.put(oldId, {
        'id': oldId,
        'name': '我的陈皮排骨汤',
        'legacyIds': <String>[],
      });
      await chat.put('conversation', {
        'items': [
          {'recipeId': oldId},
        ],
      });
      await settings.put('recent_recipe_ids', [oldId, 'user_recipe_1']);

      final migration = {
        'dataVersion': '2026.07.28.1',
        'mappings': [
          {'oldId': oldId, 'newId': newId},
        ],
      };
      final first = await RecipeIdMigrationService().migrate(migration);
      final second = await RecipeIdMigrationService().migrate(migration);

      expect(first.skipped, isFalse);
      expect(first.favorites, 1);
      expect(first.notes, 1);
      expect(first.modifiedRecipes, 1);
      expect(second.skipped, isTrue);
      expect(favorites.containsKey(oldId), isFalse);
      expect(favorites.get(newId), newId);
      expect(notes.get(newId), '少放盐');
      expect(modified.containsKey(oldId), isFalse);
      expect(modified.get(newId)?['id'], newId);
      expect(modified.get(newId)?['legacyIds'], contains(oldId));
      expect(
        ((chat.get('conversation')?['items'] as List).single
            as Map)['recipeId'],
        newId,
      );
      expect(settings.get('recent_recipe_ids'), [newId, 'user_recipe_1']);
      expect(
        settings.get(RecipeIdMigrationService.activeDataVersionKey),
        '2026.07.28.1',
      );
    } finally {
      await Hive.close();
      await tempDirectory.delete(recursive: true);
    }
  });
}
