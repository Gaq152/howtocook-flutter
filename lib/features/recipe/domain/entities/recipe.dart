// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// 菜谱实体（匹配实际 JSON 格式）
@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,                          // 菜谱ID（如 "meat_dish_003ec59b"）
    required String name,                        // 菜谱名称
    required String category,                    // 分类ID（如 "meat_dish"）
    @JsonKey(name: 'categoryName') required String categoryName,  // 分类名称（如 "荤菜"）
    required int difficulty,                     // 难度等级 1-5
    @Default([]) List<String> images,            // 图片路径列表
    @JsonKey(fromJson: _ingredientsFromJson) required List<Ingredient> ingredients,  // 食材列表
    @Default([]) List<String> tools,             // 工具列表
    @JsonKey(fromJson: _stepsFromJson) required List<CookingStep> steps,  // 烹饪步骤
    String? tips,                                // 小贴士
    @Default([]) List<String> warnings,          // 警告信息
    required String hash,                        // 文件 hash

    // 本地扩展字段（不在 JSON 中）
    @Default(false) bool isFavorite,
    String? userNote,
    @Default(RecipeSource.bundled) RecipeSource source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}

/// 从 JSON 字符串数组转换为 Ingredient 列表
List<Ingredient> _ingredientsFromJson(dynamic json) {
  if (json is! List) return [];

  return json.map((item) {
    if (item is String) {
      // 从字符串提取食材名称（第一个空格前的部分）
      final text = item.toString();
      final firstSpaceIndex = text.indexOf(' ');
      final name = firstSpaceIndex > 0 ? text.substring(0, firstSpaceIndex) : text;

      return Ingredient(name: name, text: text);
    } else if (item is Map<String, dynamic>) {
      // 兼容对象格式
      return Ingredient.fromJson(item);
    }
    return Ingredient(name: '', text: item.toString());
  }).toList();
}

/// 从 JSON 字符串数组转换为 CookingStep 列表
List<CookingStep> _stepsFromJson(dynamic json) {
  if (json is! List) return [];

  return json.map((item) {
    if (item is String) {
      return CookingStep(description: item);
    } else if (item is Map<String, dynamic>) {
      // 兼容对象格式
      return CookingStep.fromJson(item);
    }
    return CookingStep(description: item.toString());
  }).toList();
}

/// 食材实体（简化版本，保留原始文本）
@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String name,           // 食材名称
    required String text,           // 完整原始文本（如 "羊腩 500g" 或 "炸腐竹 30g-50g"）
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) => _$IngredientFromJson(json);
}

/// 烹饪步骤实体（简化版本）
@freezed
class CookingStep with _$CookingStep {
  const factory CookingStep({
    required String description,    // 步骤描述
  }) = _CookingStep;

  factory CookingStep.fromJson(Map<String, dynamic> json) => _$CookingStepFromJson(json);
}

/// 菜谱来源
enum RecipeSource {
  bundled,      // 内置数据
  cloud,        // 云端下载
  userCreated,  // 用户创建
  userModified, // 用户修改
  scanned,      // 扫码导入
  aiGenerated,  // AI生成
}
