// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// 菜谱实体（匹配实际 JSON 格式）
@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    @Default(1) int schemaVersion,
    required String id, // V1 路径 ID 或 V2 稳定 UUID
    @Default([]) List<String> legacyIds, // V2 对应的旧版 ID
    required String name, // 菜谱名称
    String? description, // 菜谱简介（V2）
    required String category, // 分类ID（如 "meat_dish"）
    @JsonKey(name: 'categoryName') required String categoryName, // 分类名称（如 "荤菜"）
    required int difficulty, // 难度等级 1-5
    int? estimatedCaloriesKcal, // 估算总热量（V2）
    @Default([]) List<String> images, // 图片路径列表
    @Default([]) List<String> externalImages,
    @JsonKey(fromJson: _requirementsFromJson)
    @Default([])
    List<RecipeRequirement> requirements, // 必备原料和工具（V2）
    String? requirementsMarkdown, // 原始必备原料和工具 Markdown
    @JsonKey(fromJson: _ingredientsFromJson)
    required List<Ingredient> ingredients, // 食材列表
    @Default([]) List<String> tools, // 工具列表
    String? calculationMarkdown, // 原始计算板块 Markdown
    @Default([]) List<String> calculationNotes,
    @JsonKey(fromJson: _stepsFromJson) required List<CookingStep> steps, // 烹饪步骤
    String? operationMarkdown, // 原始操作板块 Markdown
    String? tips, // 小贴士
    @Default([]) List<String> warnings, // 警告信息
    String? additionalMarkdown, // 未结构化附加内容
    required String hash, // 文件 hash
    // 本地扩展字段（不在 JSON 中）
    @Default(false) bool isFavorite,
    String? userNote,
    @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
    @Default(RecipeSource.bundled)
    RecipeSource source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}

/// 从 JSON 兼容读取 V2 的“必备原料和工具”。
List<RecipeRequirement> _requirementsFromJson(dynamic json) {
  if (json is! List) return [];
  return json.map((item) {
    if (item is String) {
      return RecipeRequirement(text: item, markdown: item);
    }
    if (item is Map) {
      return RecipeRequirement.fromJson(Map<String, dynamic>.from(item));
    }
    final text = item.toString();
    return RecipeRequirement(text: text, markdown: text);
  }).toList();
}

/// 从 JSON 字符串数组转换为 Ingredient 列表
List<Ingredient> _ingredientsFromJson(dynamic json) {
  if (json is! List) return [];

  return json.map((item) {
    if (item is String) {
      // 从字符串提取食材名称（第一个空格前的部分）
      final text = item.toString();
      final firstSpaceIndex = text.indexOf(' ');
      final name = firstSpaceIndex > 0
          ? text.substring(0, firstSpaceIndex)
          : text;

      return Ingredient(name: name, text: text);
    } else if (item is Map) {
      // 兼容对象格式
      return Ingredient.fromJson(Map<String, dynamic>.from(item));
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
    } else if (item is Map) {
      // 兼容对象格式
      return CookingStep.fromJson(Map<String, dynamic>.from(item));
    }
    return CookingStep(description: item.toString());
  }).toList();
}

/// “必备原料和工具”中的原始条目。
@freezed
class RecipeRequirement with _$RecipeRequirement {
  const factory RecipeRequirement({
    required String text,
    required String markdown,
    String? group,
    @Default('unknown') String kind,
  }) = _RecipeRequirement;

  factory RecipeRequirement.fromJson(Map<String, dynamic> json) =>
      _$RecipeRequirementFromJson(json);
}

/// 食材实体（简化版本，保留原始文本）
@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String name, // 食材名称
    required String text, // 完整原始文本（如 "羊腩 500g" 或 "炸腐竹 30g-50g"）
    @Default(false) bool optional,
    String? source,
    @Default({}) Map<String, String> table,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

/// 烹饪步骤实体（简化版本）
@freezed
class CookingStep with _$CookingStep {
  const factory CookingStep({
    @Default('step') String kind,
    String? title,
    required String description, // 步骤描述
  }) = _CookingStep;

  factory CookingStep.fromJson(Map<String, dynamic> json) =>
      _$CookingStepFromJson(json);
}

/// 菜谱来源
enum RecipeSource {
  bundled, // 内置数据
  cloud, // 云端下载
  userCreated, // 用户创建
  userModified, // 用户修改
  scanned, // 扫码导入
  aiGenerated, // AI生成
}

RecipeSource _recipeSourceFromJson(dynamic json) {
  if (json is Map) return RecipeSource.cloud;
  if (json is String) {
    return RecipeSource.values.firstWhere(
      (value) => value.name == json,
      orElse: () => RecipeSource.bundled,
    );
  }
  return RecipeSource.bundled;
}

String _recipeSourceToJson(RecipeSource source) => source.name;
