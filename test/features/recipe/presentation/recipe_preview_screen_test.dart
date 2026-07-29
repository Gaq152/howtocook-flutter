import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howtocook/features/recipe/domain/entities/recipe.dart';
import 'package:howtocook/features/recipe/presentation/screens/recipe_create_screen.dart';
import 'package:howtocook/features/recipe/presentation/screens/recipe_preview_screen.dart';

void main() {
  testWidgets('V2 AI 食谱在窄屏完整展示且不会越界', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const recipe = Recipe(
      schemaVersion: 2,
      id: 'preview-v2',
      name: '番茄炒蛋家庭版',
      description: '酸甜开胃、适合家庭日常制作的快手菜。',
      category: 'meat_dish',
      categoryName: '荤菜',
      difficulty: 2,
      estimatedCaloriesKcal: 480,
      requirements: [
        RecipeRequirement(
          text: '新鲜番茄和鸡蛋',
          markdown: '新鲜番茄和鸡蛋',
          kind: 'ingredient',
        ),
        RecipeRequirement(text: '炒锅', markdown: '炒锅', kind: 'tool'),
      ],
      ingredients: [
        Ingredient(name: '鸡蛋', text: '3 个', optional: true),
        Ingredient(name: '番茄', text: '400 克', table: {'用量': '400 克'}),
      ],
      calculationNotes: ['每增加 1 人，番茄约增加 200 克。'],
      steps: [
        CookingStep(kind: 'heading', title: '准备', description: '准备'),
        CookingStep(description: '番茄切块，鸡蛋打散。'),
        CookingStep(description: '依次炒熟并调味。'),
      ],
      hash: 'preview-v2-hash',
      source: RecipeSource.aiGenerated,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RecipePreviewScreen(recipe: recipe)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('菜谱简介'), findsOneWidget);
    _expectChipContrast(tester, '荤菜');
    _expectChipContrast(tester, 'AI 生成');
    _expectChipContrast(tester, '约 480 千卡');
    expect(tester.takeException(), isNull);

    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 7; i++) {
      await tester.drag(scrollable, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(find.text('操作'), findsOneWidget);
    expect(find.text('鸡蛋 3 个'), findsOneWidget);
    expect(find.text('食材'), findsOneWidget);
    expect(find.text('番茄'), findsOneWidget);
    expect(find.text('400 克'), findsOneWidget);
    _expectChipContrast(tester, '可选');
    expect(find.text('3'), findsNothing);
  });

  testWidgets('创建页窄屏用量卡片的添加按钮可点击', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RecipeCreateScreen())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final title = find.text('用量与计算（食材用量）');
    await tester.scrollUntilVisible(
      title,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));

    final card = find.ancestor(of: title, matching: find.byType(Card));
    final addButton = find.descendant(
      of: card,
      matching: find.byIcon(Icons.add),
    );
    expect(addButton, findsOneWidget);
    expect(tester.getCenter(addButton).dx, lessThan(360));
    expect(tester.takeException(), isNull);

    await tester.tap(addButton);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('添加'), findsOneWidget);
    expect(find.text('新食材'), findsOneWidget);
  });
}

void _expectChipContrast(WidgetTester tester, String label) {
  final labelText = tester.widget<Text>(find.text(label));
  final chip = tester.widget<Chip>(
    find.ancestor(of: find.text(label), matching: find.byType(Chip)),
  );
  expect(labelText.style?.color, isNotNull);
  expect(chip.backgroundColor, isNotNull);
  expect(
    _contrastRatio(labelText.style!.color!, chip.backgroundColor!),
    greaterThanOrEqualTo(4.5),
    reason: '$label 徽章文本对比度不足',
  );
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
