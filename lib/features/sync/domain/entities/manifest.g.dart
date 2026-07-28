// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ManifestImpl _$$ManifestImplFromJson(Map<String, dynamic> json) =>
    _$ManifestImpl(
      version: _readManifestVersion(json, 'version') as String,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      basePath: json['basePath'] as String? ?? '',
      generatedAt: json['generatedAt'] as String,
      totalRecipes: (json['totalRecipes'] as num).toInt(),
      totalTips: (json['totalTips'] as num).toInt(),
      totalImages: (json['totalImages'] as num?)?.toInt() ?? 0,
      categories: (json['categories'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, CategoryInfo.fromJson(e as Map<String, dynamic>)),
      ),
      tipsCategories: (json['tipsCategories'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, CategoryInfo.fromJson(e as Map<String, dynamic>)),
      ),
      recipes: (json['recipes'] as List<dynamic>)
          .map((e) => RecipeIndex.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => TipIndex.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ManifestImplToJson(_$ManifestImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'schemaVersion': instance.schemaVersion,
      'basePath': instance.basePath,
      'generatedAt': instance.generatedAt,
      'totalRecipes': instance.totalRecipes,
      'totalTips': instance.totalTips,
      'totalImages': instance.totalImages,
      'categories': instance.categories,
      'tipsCategories': instance.tipsCategories,
      'recipes': instance.recipes,
      'tips': instance.tips,
    };

_$CategoryInfoImpl _$$CategoryInfoImplFromJson(Map<String, dynamic> json) =>
    _$CategoryInfoImpl(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$$CategoryInfoImplToJson(_$CategoryInfoImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
    };

_$RecipeIndexImpl _$$RecipeIndexImplFromJson(Map<String, dynamic> json) =>
    _$RecipeIndexImpl(
      id: json['id'] as String,
      legacyIds: (json['legacyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      categoryName: json['categoryName'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      estimatedCaloriesKcal: (json['estimatedCaloriesKcal'] as num?)?.toInt(),
      hash: json['hash'] as String,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      hasImages: _readHasImages(json, 'hasImages') as bool? ?? false,
    );

Map<String, dynamic> _$$RecipeIndexImplToJson(_$RecipeIndexImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'legacyIds': instance.legacyIds,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'categoryName': instance.categoryName,
      'difficulty': instance.difficulty,
      'estimatedCaloriesKcal': instance.estimatedCaloriesKcal,
      'hash': instance.hash,
      'imageCount': instance.imageCount,
      'hasImages': instance.hasImages,
    };

_$TipIndexImpl _$$TipIndexImplFromJson(Map<String, dynamic> json) =>
    _$TipIndexImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      categoryName: json['categoryName'] as String,
      hash: json['hash'] as String,
    );

Map<String, dynamic> _$$TipIndexImplToJson(_$TipIndexImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'categoryName': instance.categoryName,
      'hash': instance.hash,
    };
