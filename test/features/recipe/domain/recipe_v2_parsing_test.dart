import 'package:flutter_test/flutter_test.dart';
import 'package:howtocook/features/recipe/domain/entities/recipe.dart';
import 'package:howtocook/features/sync/domain/entities/manifest.dart';

void main() {
  group('V2 recipe parsing', () {
    test('preserves raw sections and parses structured fields', () {
      final recipe = Recipe.fromJson({
        'schemaVersion': 2,
        'id': '05a523a7-48b0-44ed-975a-77d45f17cf64',
        'legacyIds': ['aquatic_28c3c7c3'],
        'name': '白灼虾',
        'description': '鲜甜弹嫩的粤式快手菜。',
        'category': 'aquatic',
        'categoryName': '水产',
        'difficulty': 2,
        'estimatedCaloriesKcal': 519,
        'requirements': [
          {
            'text': '活虾',
            'markdown': '**活虾**',
            'group': null,
            'kind': 'ingredient',
          },
        ],
        'requirementsMarkdown': '- 活虾',
        'ingredients': [
          {
            'name': '水',
            'text': '水 500 ml',
            'optional': false,
            'source': 'calculation-table',
            'table': {'原料': '水', '用量': '500 ml'},
          },
        ],
        'tools': ['汤锅'],
        'calculationMarkdown': '| 原料 | 用量 |',
        'calculationNotes': ['按 2 人份计算'],
        'steps': [
          {'kind': 'step', 'description': '烧开水。'},
        ],
        'operationMarkdown': '1. 烧开水。',
        'tips': '',
        'warnings': <String>[],
        'additionalMarkdown': '',
        'images': ['images/aquatic/example_0.webp'],
        'externalImages': <String>[],
        'source': {
          'repository': 'https://github.com/Gaq152/HowToCook',
          'commit': 'c05758fa661ac4efa0361a987b700a351a22159b',
          'path': 'dishes/aquatic/example.md',
        },
        'hash': 'hash',
      });

      expect(recipe.schemaVersion, 2);
      expect(recipe.legacyIds, ['aquatic_28c3c7c3']);
      expect(recipe.description, contains('粤式'));
      expect(recipe.estimatedCaloriesKcal, 519);
      expect(recipe.requirements.single.kind, 'ingredient');
      expect(recipe.ingredients.single.name, '水');
      expect(recipe.ingredients.single.table['用量'], '500 ml');
      expect(recipe.calculationMarkdown, contains('用量'));
      expect(recipe.steps.single.description, '烧开水。');
      expect(recipe.operationMarkdown, startsWith('1.'));
      expect(recipe.source, RecipeSource.cloud);
    });

    test('still parses bundled V1 recipe strings', () {
      final recipe = Recipe.fromJson({
        'id': 'soup_12345678',
        'name': '测试汤',
        'category': 'soup',
        'categoryName': '汤粥',
        'difficulty': 1,
        'images': <String>[],
        'ingredients': ['水 500ml'],
        'tools': <String>[],
        'steps': ['1. 烧水'],
        'tips': null,
        'warnings': <String>[],
        'hash': 'legacy-hash',
      });

      expect(recipe.schemaVersion, 1);
      expect(recipe.ingredients.single.name, '水');
      expect(recipe.steps.single.kind, 'step');
      expect(recipe.source, RecipeSource.bundled);
    });

    test('AI ingredients keep names when text only contains quantities', () {
      final recipe = Recipe.fromJson({
        'id': 'ai-recipe',
        'name': 'AI 测试菜',
        'category': 'meat_dish',
        'categoryName': '荤菜',
        'difficulty': 2,
        'ingredients': [
          {'name': '鸡蛋', 'text': '3 颗'},
          {
            'name': '食用油',
            'text': '30 克',
            'table': {'用量': '30 克'},
          },
        ],
        'steps': ['搅拌均匀'],
        'hash': 'ai-hash',
      });

      expect(recipe.ingredients.first.text, '鸡蛋 3 颗');
      expect(recipe.ingredients.last.displayText, '食用油 30 克');
      expect(ingredientTableColumns([recipe.ingredients.last]), ['食材', '用量']);
      expect(ingredientTableCell(recipe.ingredients.last, '食材'), '食用油');
    });
  });

  test('V2 manifest derives version and image availability', () {
    final manifest = Manifest.fromJson({
      'schemaVersion': 2,
      'dataVersion': '2026.07.28.1',
      'basePath': 'versions/2/2026.07.28.1',
      'generatedAt': '2026-07-24T07:09:54Z',
      'totalRecipes': 1,
      'totalTips': 0,
      'totalImages': 1,
      'categories': {
        'aquatic': {'name': '水产', 'count': 1},
      },
      'tipsCategories': <String, dynamic>{},
      'recipes': [
        {
          'id': '05a523a7-48b0-44ed-975a-77d45f17cf64',
          'legacyIds': ['aquatic_28c3c7c3'],
          'name': '白灼虾',
          'description': '简介',
          'category': 'aquatic',
          'categoryName': '水产',
          'difficulty': 2,
          'estimatedCaloriesKcal': 519,
          'imageCount': 1,
          'hash': 'hash',
        },
      ],
      'tips': <dynamic>[],
    });

    expect(manifest.version, '2026.07.28.1');
    expect(manifest.schemaVersion, 2);
    expect(manifest.recipes.single.hasImages, isTrue);
    expect(manifest.recipes.single.legacyIds, ['aquatic_28c3c7c3']);
  });
}
