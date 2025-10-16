// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ManifestImpl _$$ManifestImplFromJson(Map<String, dynamic> json) =>
    _$ManifestImpl(
      version: json['version'] as String,
      generatedAt: json['generatedAt'] as String,
      totalRecipes: (json['totalRecipes'] as num).toInt(),
      totalTips: (json['totalTips'] as num).toInt(),
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
      'generatedAt': instance.generatedAt,
      'totalRecipes': instance.totalRecipes,
      'totalTips': instance.totalTips,
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
      name: json['name'] as String,
      category: json['category'] as String,
      categoryName: json['categoryName'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      hash: json['hash'] as String,
      hasImages: json['hasImages'] as bool? ?? false,
    );

Map<String, dynamic> _$$RecipeIndexImplToJson(_$RecipeIndexImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'categoryName': instance.categoryName,
      'difficulty': instance.difficulty,
      'hash': instance.hash,
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
