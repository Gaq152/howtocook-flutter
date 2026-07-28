// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'manifest.freezed.dart';
part 'manifest.g.dart';

/// 菜谱索引清单（用于增量更新检测）
@freezed
class Manifest with _$Manifest {
  const factory Manifest({
    @JsonKey(readValue: _readManifestVersion)
    required String version, // V1 version / V2 dataVersion
    @Default(1) int schemaVersion,
    @Default('') String basePath,
    required String generatedAt, // 生成时间
    required int totalRecipes, // 菜谱总数
    required int totalTips, // 技巧总数
    @Default(0) int totalImages,
    required Map<String, CategoryInfo> categories, // 菜谱分类信息
    required Map<String, CategoryInfo> tipsCategories, // 教程分类信息
    required List<RecipeIndex> recipes, // 菜谱索引
    @Default([]) List<TipIndex> tips, // 技巧索引
  }) = _Manifest;

  factory Manifest.fromJson(Map<String, dynamic> json) =>
      _$ManifestFromJson(json);
}

/// 分类信息
@freezed
class CategoryInfo with _$CategoryInfo {
  const factory CategoryInfo({
    required String name, // 分类名称（如 "水产"）
    required int count, // 该分类下的菜谱数量
  }) = _CategoryInfo;

  factory CategoryInfo.fromJson(Map<String, dynamic> json) =>
      _$CategoryInfoFromJson(json);
}

/// 菜谱索引条目
@freezed
class RecipeIndex with _$RecipeIndex {
  const factory RecipeIndex({
    required String id, // 菜谱 ID
    @Default([]) List<String> legacyIds,
    required String name, // 菜谱名称
    String? description,
    required String category, // 分类 ID
    required String categoryName, // 分类名称
    required int difficulty, // 难度等级 1-5
    int? estimatedCaloriesKcal,
    required String hash, // 文件 hash，用于检测变化
    @Default(0) int imageCount,
    @JsonKey(readValue: _readHasImages)
    @Default(false)
    bool hasImages, // V1 hasImages / V2 imageCount
  }) = _RecipeIndex;

  factory RecipeIndex.fromJson(Map<String, dynamic> json) =>
      _$RecipeIndexFromJson(json);
}

Object? _readManifestVersion(Map<dynamic, dynamic> json, String key) =>
    json['dataVersion'] ?? json['version'] ?? '1';

Object? _readHasImages(Map<dynamic, dynamic> json, String key) =>
    json['hasImages'] ?? ((json['imageCount'] as num?)?.toInt() ?? 0) > 0;

/// 技巧索引条目
@freezed
class TipIndex with _$TipIndex {
  const factory TipIndex({
    required String id, // 技巧 ID
    required String title, // 技巧标题
    required String category, // 分类 ID
    required String categoryName, // 分类名称
    required String hash, // 文件 hash
  }) = _TipIndex;

  factory TipIndex.fromJson(Map<String, dynamic> json) =>
      _$TipIndexFromJson(json);
}
