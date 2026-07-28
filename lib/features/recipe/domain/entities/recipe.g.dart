// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipeImpl _$$RecipeImplFromJson(Map<String, dynamic> json) => _$RecipeImpl(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
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
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      externalImages: (json['externalImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      requirements: json['requirements'] == null
          ? const []
          : _requirementsFromJson(json['requirements']),
      requirementsMarkdown: json['requirementsMarkdown'] as String?,
      ingredients: _ingredientsFromJson(json['ingredients']),
      tools:
          (json['tools'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      calculationMarkdown: json['calculationMarkdown'] as String?,
      calculationNotes: (json['calculationNotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      steps: _stepsFromJson(json['steps']),
      operationMarkdown: json['operationMarkdown'] as String?,
      tips: json['tips'] as String?,
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      additionalMarkdown: json['additionalMarkdown'] as String?,
      hash: json['hash'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      userNote: json['userNote'] as String?,
      source: json['source'] == null
          ? RecipeSource.bundled
          : _recipeSourceFromJson(json['source']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$RecipeImplToJson(_$RecipeImpl instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'id': instance.id,
      'legacyIds': instance.legacyIds,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'categoryName': instance.categoryName,
      'difficulty': instance.difficulty,
      'estimatedCaloriesKcal': instance.estimatedCaloriesKcal,
      'images': instance.images,
      'externalImages': instance.externalImages,
      'requirements': instance.requirements,
      'requirementsMarkdown': instance.requirementsMarkdown,
      'ingredients': instance.ingredients,
      'tools': instance.tools,
      'calculationMarkdown': instance.calculationMarkdown,
      'calculationNotes': instance.calculationNotes,
      'steps': instance.steps,
      'operationMarkdown': instance.operationMarkdown,
      'tips': instance.tips,
      'warnings': instance.warnings,
      'additionalMarkdown': instance.additionalMarkdown,
      'hash': instance.hash,
      'isFavorite': instance.isFavorite,
      'userNote': instance.userNote,
      'source': _recipeSourceToJson(instance.source),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$RecipeRequirementImpl _$$RecipeRequirementImplFromJson(
        Map<String, dynamic> json) =>
    _$RecipeRequirementImpl(
      text: json['text'] as String,
      markdown: json['markdown'] as String,
      group: json['group'] as String?,
      kind: json['kind'] as String? ?? 'unknown',
    );

Map<String, dynamic> _$$RecipeRequirementImplToJson(
        _$RecipeRequirementImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'markdown': instance.markdown,
      'group': instance.group,
      'kind': instance.kind,
    };

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      name: json['name'] as String,
      text: json['text'] as String,
      optional: json['optional'] as bool? ?? false,
      source: json['source'] as String?,
      table: (json['table'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'text': instance.text,
      'optional': instance.optional,
      'source': instance.source,
      'table': instance.table,
    };

_$CookingStepImpl _$$CookingStepImplFromJson(Map<String, dynamic> json) =>
    _$CookingStepImpl(
      kind: json['kind'] as String? ?? 'step',
      title: json['title'] as String?,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$CookingStepImplToJson(_$CookingStepImpl instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'title': instance.title,
      'description': instance.description,
    };
