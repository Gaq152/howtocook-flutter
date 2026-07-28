import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howtocook/features/recipe/domain/entities/recipe.dart';
import 'package:howtocook/features/recipe/infrastructure/services/recipe_share_service.dart';

void main() {
  final service = RecipeShareService();

  Recipe recipe({
    RecipeSource source = RecipeSource.userCreated,
    String description = '一道清爽的家常菜。',
    List<CookingStep>? steps,
  }) {
    return Recipe(
      schemaVersion: 2,
      id: '05a523a7-48b0-44ed-975a-77d45f17cf64',
      name: '测试菜',
      description: description,
      category: 'vegetable_dish',
      categoryName: '素菜',
      difficulty: 2,
      estimatedCaloriesKcal: 320,
      requirements: const [
        RecipeRequirement(text: '鸡蛋', markdown: '鸡蛋', kind: 'ingredient'),
      ],
      ingredients: const [
        Ingredient(
          name: '鸡蛋',
          text: '鸡蛋 2 个',
          source: 'calculation-table',
          table: {'原料': '鸡蛋', '用量': '2 个'},
        ),
        Ingredient(name: '水', text: '水 100 ml'),
      ],
      calculationNotes: const ['每份'],
      steps: steps ?? const [CookingStep(description: '混合后蒸熟')],
      tools: const ['蒸锅'],
      warnings: const [],
      images: const [],
      hash: '',
      source: source,
    );
  }

  test('云端菜谱使用短 UUID 引用码', () {
    final payload = service.generateQRPayload(
      recipe(source: RecipeSource.cloud),
    );

    expect(payload.isComplete, isTrue);
    expect(payload.data, contains('v=2&ref='));
    expect(payload.data.length, lessThan(200));
  });

  test('普通自建菜谱完整保留 V2 字段', () {
    final payload = service.generateQRPayload(recipe());
    final json = _decodePayload(payload.data);

    expect(payload.isComplete, isTrue);
    expect(
      payload.data.length,
      lessThanOrEqualTo(RecipeShareService.maxReliableQrCharacters),
    );
    expect(json['v'], 2);
    expect(json['ds'], isNotEmpty);
    expect(json['k'], 320);
    expect(json['r'], isNotEmpty);
    expect(json['cl'], ['每份']);
    expect((json['i'] as List).first, isA<Map>());
  });

  test('超长菜谱生成明确标记的摘要码', () {
    final longSteps = List.generate(
      160,
      (index) => CookingStep(
        description:
            '第 $index 段 ${List.generate(220, (offset) => String.fromCharCode(0x4e00 + ((index * 211 + offset * 97) % 18000))).join()}',
      ),
    );
    final payload = service.generateQRPayload(
      recipe(
        description: List.generate(
          1000,
          (index) => String.fromCharCode(0x4e00 + ((index * 131) % 18000)),
        ).join(),
        steps: longSteps,
      ),
    );
    final json = _decodePayload(payload.data);

    expect(payload.isComplete, isFalse);
    expect(
      payload.data.length,
      lessThanOrEqualTo(RecipeShareService.maxReliableQrCharacters),
    );
    expect(json['p'], isTrue);
    expect((json['s'] as List).length, lessThanOrEqualTo(4));
    expect(payload.note, contains('仅含摘要'));
  });
}

Map<String, dynamic> _decodePayload(String value) {
  final uri = Uri.parse(value);
  if (uri.queryParameters['raw'] case final String raw) {
    return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(raw))))
        as Map<String, dynamic>;
  }
  final compressed = base64Url.decode(
    base64Url.normalize(uri.queryParameters['data']!),
  );
  return jsonDecode(utf8.decode(GZipDecoder().decodeBytes(compressed)))
      as Map<String, dynamic>;
}
