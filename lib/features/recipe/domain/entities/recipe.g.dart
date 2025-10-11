// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipeImpl _$$RecipeImplFromJson(Map<String, dynamic> json) => _$RecipeImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      categoryName: json['categoryName'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ingredients: _ingredientsFromJson(json['ingredients']),
      tools:
          (json['tools'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      steps: _stepsFromJson(json['steps']),
      tips: json['tips'] as String?,
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hash: json['hash'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      userNote: json['userNote'] as String?,
      source: $enumDecodeNullable(_$RecipeSourceEnumMap, json['source']) ??
          RecipeSource.bundled,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$RecipeImplToJson(_$RecipeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'categoryName': instance.categoryName,
      'difficulty': instance.difficulty,
      'images': instance.images,
      'ingredients': instance.ingredients,
      'tools': instance.tools,
      'steps': instance.steps,
      'tips': instance.tips,
      'warnings': instance.warnings,
      'hash': instance.hash,
      'isFavorite': instance.isFavorite,
      'userNote': instance.userNote,
      'source': _$RecipeSourceEnumMap[instance.source]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$RecipeSourceEnumMap = {
  RecipeSource.bundled: 'bundled',
  RecipeSource.cloud: 'cloud',
  RecipeSource.userCreated: 'userCreated',
  RecipeSource.userModified: 'userModified',
};

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      name: json['name'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'text': instance.text,
    };

_$CookingStepImpl _$$CookingStepImplFromJson(Map<String, dynamic> json) =>
    _$CookingStepImpl(
      description: json['description'] as String,
    );

Map<String, dynamic> _$$CookingStepImplToJson(_$CookingStepImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
    };
