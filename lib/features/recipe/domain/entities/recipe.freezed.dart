// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Recipe _$RecipeFromJson(Map<String, dynamic> json) {
  return _Recipe.fromJson(json);
}

/// @nodoc
mixin _$Recipe {
  int get schemaVersion => throw _privateConstructorUsedError;
  String get id => throw _privateConstructorUsedError; // V1 路径 ID 或 V2 稳定 UUID
  List<String> get legacyIds =>
      throw _privateConstructorUsedError; // V2 对应的旧版 ID
  String get name => throw _privateConstructorUsedError; // 菜谱名称
  String? get description => throw _privateConstructorUsedError; // 菜谱简介（V2）
  String get category =>
      throw _privateConstructorUsedError; // 分类ID（如 "meat_dish"）
  @JsonKey(name: 'categoryName')
  String get categoryName => throw _privateConstructorUsedError; // 分类名称（如 "荤菜"）
  int get difficulty => throw _privateConstructorUsedError; // 难度等级 1-5
  int? get estimatedCaloriesKcal =>
      throw _privateConstructorUsedError; // 估算总热量（V2）
  List<String> get images => throw _privateConstructorUsedError; // 图片路径列表
  List<String> get externalImages => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _requirementsFromJson)
  List<RecipeRequirement> get requirements =>
      throw _privateConstructorUsedError; // 必备原料和工具（V2）
  String? get requirementsMarkdown =>
      throw _privateConstructorUsedError; // 原始必备原料和工具 Markdown
  @JsonKey(fromJson: _ingredientsFromJson)
  List<Ingredient> get ingredients =>
      throw _privateConstructorUsedError; // 食材列表
  List<String> get tools => throw _privateConstructorUsedError; // 工具列表
  String? get calculationMarkdown =>
      throw _privateConstructorUsedError; // 原始计算板块 Markdown
  List<String> get calculationNotes => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stepsFromJson)
  List<CookingStep> get steps => throw _privateConstructorUsedError; // 烹饪步骤
  String? get operationMarkdown =>
      throw _privateConstructorUsedError; // 原始操作板块 Markdown
  String? get tips => throw _privateConstructorUsedError; // 小贴士
  List<String> get warnings => throw _privateConstructorUsedError; // 警告信息
  String? get additionalMarkdown =>
      throw _privateConstructorUsedError; // 未结构化附加内容
  String get hash => throw _privateConstructorUsedError; // 文件 hash
// 本地扩展字段（不在 JSON 中）
  bool get isFavorite => throw _privateConstructorUsedError;
  String? get userNote => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
  RecipeSource get source => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeCopyWith<Recipe> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeCopyWith<$Res> {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) then) =
      _$RecipeCopyWithImpl<$Res, Recipe>;
  @useResult
  $Res call(
      {int schemaVersion,
      String id,
      List<String> legacyIds,
      String name,
      String? description,
      String category,
      @JsonKey(name: 'categoryName') String categoryName,
      int difficulty,
      int? estimatedCaloriesKcal,
      List<String> images,
      List<String> externalImages,
      @JsonKey(fromJson: _requirementsFromJson)
      List<RecipeRequirement> requirements,
      String? requirementsMarkdown,
      @JsonKey(fromJson: _ingredientsFromJson) List<Ingredient> ingredients,
      List<String> tools,
      String? calculationMarkdown,
      List<String> calculationNotes,
      @JsonKey(fromJson: _stepsFromJson) List<CookingStep> steps,
      String? operationMarkdown,
      String? tips,
      List<String> warnings,
      String? additionalMarkdown,
      String hash,
      bool isFavorite,
      String? userNote,
      @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
      RecipeSource source,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$RecipeCopyWithImpl<$Res, $Val extends Recipe>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? id = null,
    Object? legacyIds = null,
    Object? name = null,
    Object? description = freezed,
    Object? category = null,
    Object? categoryName = null,
    Object? difficulty = null,
    Object? estimatedCaloriesKcal = freezed,
    Object? images = null,
    Object? externalImages = null,
    Object? requirements = null,
    Object? requirementsMarkdown = freezed,
    Object? ingredients = null,
    Object? tools = null,
    Object? calculationMarkdown = freezed,
    Object? calculationNotes = null,
    Object? steps = null,
    Object? operationMarkdown = freezed,
    Object? tips = freezed,
    Object? warnings = null,
    Object? additionalMarkdown = freezed,
    Object? hash = null,
    Object? isFavorite = null,
    Object? userNote = freezed,
    Object? source = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      legacyIds: null == legacyIds
          ? _value.legacyIds
          : legacyIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      categoryName: null == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedCaloriesKcal: freezed == estimatedCaloriesKcal
          ? _value.estimatedCaloriesKcal
          : estimatedCaloriesKcal // ignore: cast_nullable_to_non_nullable
              as int?,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      externalImages: null == externalImages
          ? _value.externalImages
          : externalImages // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requirements: null == requirements
          ? _value.requirements
          : requirements // ignore: cast_nullable_to_non_nullable
              as List<RecipeRequirement>,
      requirementsMarkdown: freezed == requirementsMarkdown
          ? _value.requirementsMarkdown
          : requirementsMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      tools: null == tools
          ? _value.tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      calculationMarkdown: freezed == calculationMarkdown
          ? _value.calculationMarkdown
          : calculationMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      calculationNotes: null == calculationNotes
          ? _value.calculationNotes
          : calculationNotes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<CookingStep>,
      operationMarkdown: freezed == operationMarkdown
          ? _value.operationMarkdown
          : operationMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      tips: freezed == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as String?,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      additionalMarkdown: freezed == additionalMarkdown
          ? _value.additionalMarkdown
          : additionalMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      userNote: freezed == userNote
          ? _value.userNote
          : userNote // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as RecipeSource,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeImplCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$$RecipeImplCopyWith(
          _$RecipeImpl value, $Res Function(_$RecipeImpl) then) =
      __$$RecipeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int schemaVersion,
      String id,
      List<String> legacyIds,
      String name,
      String? description,
      String category,
      @JsonKey(name: 'categoryName') String categoryName,
      int difficulty,
      int? estimatedCaloriesKcal,
      List<String> images,
      List<String> externalImages,
      @JsonKey(fromJson: _requirementsFromJson)
      List<RecipeRequirement> requirements,
      String? requirementsMarkdown,
      @JsonKey(fromJson: _ingredientsFromJson) List<Ingredient> ingredients,
      List<String> tools,
      String? calculationMarkdown,
      List<String> calculationNotes,
      @JsonKey(fromJson: _stepsFromJson) List<CookingStep> steps,
      String? operationMarkdown,
      String? tips,
      List<String> warnings,
      String? additionalMarkdown,
      String hash,
      bool isFavorite,
      String? userNote,
      @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
      RecipeSource source,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$RecipeImplCopyWithImpl<$Res>
    extends _$RecipeCopyWithImpl<$Res, _$RecipeImpl>
    implements _$$RecipeImplCopyWith<$Res> {
  __$$RecipeImplCopyWithImpl(
      _$RecipeImpl _value, $Res Function(_$RecipeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? id = null,
    Object? legacyIds = null,
    Object? name = null,
    Object? description = freezed,
    Object? category = null,
    Object? categoryName = null,
    Object? difficulty = null,
    Object? estimatedCaloriesKcal = freezed,
    Object? images = null,
    Object? externalImages = null,
    Object? requirements = null,
    Object? requirementsMarkdown = freezed,
    Object? ingredients = null,
    Object? tools = null,
    Object? calculationMarkdown = freezed,
    Object? calculationNotes = null,
    Object? steps = null,
    Object? operationMarkdown = freezed,
    Object? tips = freezed,
    Object? warnings = null,
    Object? additionalMarkdown = freezed,
    Object? hash = null,
    Object? isFavorite = null,
    Object? userNote = freezed,
    Object? source = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$RecipeImpl(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      legacyIds: null == legacyIds
          ? _value._legacyIds
          : legacyIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      categoryName: null == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedCaloriesKcal: freezed == estimatedCaloriesKcal
          ? _value.estimatedCaloriesKcal
          : estimatedCaloriesKcal // ignore: cast_nullable_to_non_nullable
              as int?,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      externalImages: null == externalImages
          ? _value._externalImages
          : externalImages // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requirements: null == requirements
          ? _value._requirements
          : requirements // ignore: cast_nullable_to_non_nullable
              as List<RecipeRequirement>,
      requirementsMarkdown: freezed == requirementsMarkdown
          ? _value.requirementsMarkdown
          : requirementsMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      tools: null == tools
          ? _value._tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      calculationMarkdown: freezed == calculationMarkdown
          ? _value.calculationMarkdown
          : calculationMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      calculationNotes: null == calculationNotes
          ? _value._calculationNotes
          : calculationNotes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      steps: null == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<CookingStep>,
      operationMarkdown: freezed == operationMarkdown
          ? _value.operationMarkdown
          : operationMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      tips: freezed == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as String?,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      additionalMarkdown: freezed == additionalMarkdown
          ? _value.additionalMarkdown
          : additionalMarkdown // ignore: cast_nullable_to_non_nullable
              as String?,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      userNote: freezed == userNote
          ? _value.userNote
          : userNote // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as RecipeSource,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeImpl implements _Recipe {
  const _$RecipeImpl(
      {this.schemaVersion = 1,
      required this.id,
      final List<String> legacyIds = const [],
      required this.name,
      this.description,
      required this.category,
      @JsonKey(name: 'categoryName') required this.categoryName,
      required this.difficulty,
      this.estimatedCaloriesKcal,
      final List<String> images = const [],
      final List<String> externalImages = const [],
      @JsonKey(fromJson: _requirementsFromJson)
      final List<RecipeRequirement> requirements = const [],
      this.requirementsMarkdown,
      @JsonKey(fromJson: _ingredientsFromJson)
      required final List<Ingredient> ingredients,
      final List<String> tools = const [],
      this.calculationMarkdown,
      final List<String> calculationNotes = const [],
      @JsonKey(fromJson: _stepsFromJson) required final List<CookingStep> steps,
      this.operationMarkdown,
      this.tips,
      final List<String> warnings = const [],
      this.additionalMarkdown,
      required this.hash,
      this.isFavorite = false,
      this.userNote,
      @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
      this.source = RecipeSource.bundled,
      this.createdAt,
      this.updatedAt})
      : _legacyIds = legacyIds,
        _images = images,
        _externalImages = externalImages,
        _requirements = requirements,
        _ingredients = ingredients,
        _tools = tools,
        _calculationNotes = calculationNotes,
        _steps = steps,
        _warnings = warnings;

  factory _$RecipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeImplFromJson(json);

  @override
  @JsonKey()
  final int schemaVersion;
  @override
  final String id;
// V1 路径 ID 或 V2 稳定 UUID
  final List<String> _legacyIds;
// V1 路径 ID 或 V2 稳定 UUID
  @override
  @JsonKey()
  List<String> get legacyIds {
    if (_legacyIds is EqualUnmodifiableListView) return _legacyIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_legacyIds);
  }

// V2 对应的旧版 ID
  @override
  final String name;
// 菜谱名称
  @override
  final String? description;
// 菜谱简介（V2）
  @override
  final String category;
// 分类ID（如 "meat_dish"）
  @override
  @JsonKey(name: 'categoryName')
  final String categoryName;
// 分类名称（如 "荤菜"）
  @override
  final int difficulty;
// 难度等级 1-5
  @override
  final int? estimatedCaloriesKcal;
// 估算总热量（V2）
  final List<String> _images;
// 估算总热量（V2）
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

// 图片路径列表
  final List<String> _externalImages;
// 图片路径列表
  @override
  @JsonKey()
  List<String> get externalImages {
    if (_externalImages is EqualUnmodifiableListView) return _externalImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_externalImages);
  }

  final List<RecipeRequirement> _requirements;
  @override
  @JsonKey(fromJson: _requirementsFromJson)
  List<RecipeRequirement> get requirements {
    if (_requirements is EqualUnmodifiableListView) return _requirements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requirements);
  }

// 必备原料和工具（V2）
  @override
  final String? requirementsMarkdown;
// 原始必备原料和工具 Markdown
  final List<Ingredient> _ingredients;
// 原始必备原料和工具 Markdown
  @override
  @JsonKey(fromJson: _ingredientsFromJson)
  List<Ingredient> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

// 食材列表
  final List<String> _tools;
// 食材列表
  @override
  @JsonKey()
  List<String> get tools {
    if (_tools is EqualUnmodifiableListView) return _tools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tools);
  }

// 工具列表
  @override
  final String? calculationMarkdown;
// 原始计算板块 Markdown
  final List<String> _calculationNotes;
// 原始计算板块 Markdown
  @override
  @JsonKey()
  List<String> get calculationNotes {
    if (_calculationNotes is EqualUnmodifiableListView)
      return _calculationNotes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_calculationNotes);
  }

  final List<CookingStep> _steps;
  @override
  @JsonKey(fromJson: _stepsFromJson)
  List<CookingStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

// 烹饪步骤
  @override
  final String? operationMarkdown;
// 原始操作板块 Markdown
  @override
  final String? tips;
// 小贴士
  final List<String> _warnings;
// 小贴士
  @override
  @JsonKey()
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

// 警告信息
  @override
  final String? additionalMarkdown;
// 未结构化附加内容
  @override
  final String hash;
// 文件 hash
// 本地扩展字段（不在 JSON 中）
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  final String? userNote;
  @override
  @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
  final RecipeSource source;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Recipe(schemaVersion: $schemaVersion, id: $id, legacyIds: $legacyIds, name: $name, description: $description, category: $category, categoryName: $categoryName, difficulty: $difficulty, estimatedCaloriesKcal: $estimatedCaloriesKcal, images: $images, externalImages: $externalImages, requirements: $requirements, requirementsMarkdown: $requirementsMarkdown, ingredients: $ingredients, tools: $tools, calculationMarkdown: $calculationMarkdown, calculationNotes: $calculationNotes, steps: $steps, operationMarkdown: $operationMarkdown, tips: $tips, warnings: $warnings, additionalMarkdown: $additionalMarkdown, hash: $hash, isFavorite: $isFavorite, userNote: $userNote, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeImpl &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._legacyIds, _legacyIds) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.estimatedCaloriesKcal, estimatedCaloriesKcal) ||
                other.estimatedCaloriesKcal == estimatedCaloriesKcal) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality()
                .equals(other._externalImages, _externalImages) &&
            const DeepCollectionEquality()
                .equals(other._requirements, _requirements) &&
            (identical(other.requirementsMarkdown, requirementsMarkdown) ||
                other.requirementsMarkdown == requirementsMarkdown) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality().equals(other._tools, _tools) &&
            (identical(other.calculationMarkdown, calculationMarkdown) ||
                other.calculationMarkdown == calculationMarkdown) &&
            const DeepCollectionEquality()
                .equals(other._calculationNotes, _calculationNotes) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.operationMarkdown, operationMarkdown) ||
                other.operationMarkdown == operationMarkdown) &&
            (identical(other.tips, tips) || other.tips == tips) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
            (identical(other.additionalMarkdown, additionalMarkdown) ||
                other.additionalMarkdown == additionalMarkdown) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.userNote, userNote) ||
                other.userNote == userNote) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        schemaVersion,
        id,
        const DeepCollectionEquality().hash(_legacyIds),
        name,
        description,
        category,
        categoryName,
        difficulty,
        estimatedCaloriesKcal,
        const DeepCollectionEquality().hash(_images),
        const DeepCollectionEquality().hash(_externalImages),
        const DeepCollectionEquality().hash(_requirements),
        requirementsMarkdown,
        const DeepCollectionEquality().hash(_ingredients),
        const DeepCollectionEquality().hash(_tools),
        calculationMarkdown,
        const DeepCollectionEquality().hash(_calculationNotes),
        const DeepCollectionEquality().hash(_steps),
        operationMarkdown,
        tips,
        const DeepCollectionEquality().hash(_warnings),
        additionalMarkdown,
        hash,
        isFavorite,
        userNote,
        source,
        createdAt,
        updatedAt
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      __$$RecipeImplCopyWithImpl<_$RecipeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeImplToJson(
      this,
    );
  }
}

abstract class _Recipe implements Recipe {
  const factory _Recipe(
      {final int schemaVersion,
      required final String id,
      final List<String> legacyIds,
      required final String name,
      final String? description,
      required final String category,
      @JsonKey(name: 'categoryName') required final String categoryName,
      required final int difficulty,
      final int? estimatedCaloriesKcal,
      final List<String> images,
      final List<String> externalImages,
      @JsonKey(fromJson: _requirementsFromJson)
      final List<RecipeRequirement> requirements,
      final String? requirementsMarkdown,
      @JsonKey(fromJson: _ingredientsFromJson)
      required final List<Ingredient> ingredients,
      final List<String> tools,
      final String? calculationMarkdown,
      final List<String> calculationNotes,
      @JsonKey(fromJson: _stepsFromJson) required final List<CookingStep> steps,
      final String? operationMarkdown,
      final String? tips,
      final List<String> warnings,
      final String? additionalMarkdown,
      required final String hash,
      final bool isFavorite,
      final String? userNote,
      @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
      final RecipeSource source,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$RecipeImpl;

  factory _Recipe.fromJson(Map<String, dynamic> json) = _$RecipeImpl.fromJson;

  @override
  int get schemaVersion;
  @override
  String get id;
  @override // V1 路径 ID 或 V2 稳定 UUID
  List<String> get legacyIds;
  @override // V2 对应的旧版 ID
  String get name;
  @override // 菜谱名称
  String? get description;
  @override // 菜谱简介（V2）
  String get category;
  @override // 分类ID（如 "meat_dish"）
  @JsonKey(name: 'categoryName')
  String get categoryName;
  @override // 分类名称（如 "荤菜"）
  int get difficulty;
  @override // 难度等级 1-5
  int? get estimatedCaloriesKcal;
  @override // 估算总热量（V2）
  List<String> get images;
  @override // 图片路径列表
  List<String> get externalImages;
  @override
  @JsonKey(fromJson: _requirementsFromJson)
  List<RecipeRequirement> get requirements;
  @override // 必备原料和工具（V2）
  String? get requirementsMarkdown;
  @override // 原始必备原料和工具 Markdown
  @JsonKey(fromJson: _ingredientsFromJson)
  List<Ingredient> get ingredients;
  @override // 食材列表
  List<String> get tools;
  @override // 工具列表
  String? get calculationMarkdown;
  @override // 原始计算板块 Markdown
  List<String> get calculationNotes;
  @override
  @JsonKey(fromJson: _stepsFromJson)
  List<CookingStep> get steps;
  @override // 烹饪步骤
  String? get operationMarkdown;
  @override // 原始操作板块 Markdown
  String? get tips;
  @override // 小贴士
  List<String> get warnings;
  @override // 警告信息
  String? get additionalMarkdown;
  @override // 未结构化附加内容
  String get hash;
  @override // 文件 hash
// 本地扩展字段（不在 JSON 中）
  bool get isFavorite;
  @override
  String? get userNote;
  @override
  @JsonKey(fromJson: _recipeSourceFromJson, toJson: _recipeSourceToJson)
  RecipeSource get source;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeRequirement _$RecipeRequirementFromJson(Map<String, dynamic> json) {
  return _RecipeRequirement.fromJson(json);
}

/// @nodoc
mixin _$RecipeRequirement {
  String get text => throw _privateConstructorUsedError;
  String get markdown => throw _privateConstructorUsedError;
  String? get group => throw _privateConstructorUsedError;
  String get kind => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeRequirementCopyWith<RecipeRequirement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeRequirementCopyWith<$Res> {
  factory $RecipeRequirementCopyWith(
          RecipeRequirement value, $Res Function(RecipeRequirement) then) =
      _$RecipeRequirementCopyWithImpl<$Res, RecipeRequirement>;
  @useResult
  $Res call({String text, String markdown, String? group, String kind});
}

/// @nodoc
class _$RecipeRequirementCopyWithImpl<$Res, $Val extends RecipeRequirement>
    implements $RecipeRequirementCopyWith<$Res> {
  _$RecipeRequirementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? markdown = null,
    Object? group = freezed,
    Object? kind = null,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      markdown: null == markdown
          ? _value.markdown
          : markdown // ignore: cast_nullable_to_non_nullable
              as String,
      group: freezed == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as String?,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeRequirementImplCopyWith<$Res>
    implements $RecipeRequirementCopyWith<$Res> {
  factory _$$RecipeRequirementImplCopyWith(_$RecipeRequirementImpl value,
          $Res Function(_$RecipeRequirementImpl) then) =
      __$$RecipeRequirementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, String markdown, String? group, String kind});
}

/// @nodoc
class __$$RecipeRequirementImplCopyWithImpl<$Res>
    extends _$RecipeRequirementCopyWithImpl<$Res, _$RecipeRequirementImpl>
    implements _$$RecipeRequirementImplCopyWith<$Res> {
  __$$RecipeRequirementImplCopyWithImpl(_$RecipeRequirementImpl _value,
      $Res Function(_$RecipeRequirementImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? markdown = null,
    Object? group = freezed,
    Object? kind = null,
  }) {
    return _then(_$RecipeRequirementImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      markdown: null == markdown
          ? _value.markdown
          : markdown // ignore: cast_nullable_to_non_nullable
              as String,
      group: freezed == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as String?,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeRequirementImpl implements _RecipeRequirement {
  const _$RecipeRequirementImpl(
      {required this.text,
      required this.markdown,
      this.group,
      this.kind = 'unknown'});

  factory _$RecipeRequirementImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeRequirementImplFromJson(json);

  @override
  final String text;
  @override
  final String markdown;
  @override
  final String? group;
  @override
  @JsonKey()
  final String kind;

  @override
  String toString() {
    return 'RecipeRequirement(text: $text, markdown: $markdown, group: $group, kind: $kind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeRequirementImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.markdown, markdown) ||
                other.markdown == markdown) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, text, markdown, group, kind);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeRequirementImplCopyWith<_$RecipeRequirementImpl> get copyWith =>
      __$$RecipeRequirementImplCopyWithImpl<_$RecipeRequirementImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeRequirementImplToJson(
      this,
    );
  }
}

abstract class _RecipeRequirement implements RecipeRequirement {
  const factory _RecipeRequirement(
      {required final String text,
      required final String markdown,
      final String? group,
      final String kind}) = _$RecipeRequirementImpl;

  factory _RecipeRequirement.fromJson(Map<String, dynamic> json) =
      _$RecipeRequirementImpl.fromJson;

  @override
  String get text;
  @override
  String get markdown;
  @override
  String? get group;
  @override
  String get kind;
  @override
  @JsonKey(ignore: true)
  _$$RecipeRequirementImplCopyWith<_$RecipeRequirementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Ingredient _$IngredientFromJson(Map<String, dynamic> json) {
  return _Ingredient.fromJson(json);
}

/// @nodoc
mixin _$Ingredient {
  String get name => throw _privateConstructorUsedError; // 食材名称
  String get text =>
      throw _privateConstructorUsedError; // 完整原始文本（如 "羊腩 500g" 或 "炸腐竹 30g-50g"）
  bool get optional => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  Map<String, String> get table => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IngredientCopyWith<Ingredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientCopyWith<$Res> {
  factory $IngredientCopyWith(
          Ingredient value, $Res Function(Ingredient) then) =
      _$IngredientCopyWithImpl<$Res, Ingredient>;
  @useResult
  $Res call(
      {String name,
      String text,
      bool optional,
      String? source,
      Map<String, String> table});
}

/// @nodoc
class _$IngredientCopyWithImpl<$Res, $Val extends Ingredient>
    implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? text = null,
    Object? optional = null,
    Object? source = freezed,
    Object? table = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      optional: null == optional
          ? _value.optional
          : optional // ignore: cast_nullable_to_non_nullable
              as bool,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      table: null == table
          ? _value.table
          : table // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IngredientImplCopyWith<$Res>
    implements $IngredientCopyWith<$Res> {
  factory _$$IngredientImplCopyWith(
          _$IngredientImpl value, $Res Function(_$IngredientImpl) then) =
      __$$IngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String text,
      bool optional,
      String? source,
      Map<String, String> table});
}

/// @nodoc
class __$$IngredientImplCopyWithImpl<$Res>
    extends _$IngredientCopyWithImpl<$Res, _$IngredientImpl>
    implements _$$IngredientImplCopyWith<$Res> {
  __$$IngredientImplCopyWithImpl(
      _$IngredientImpl _value, $Res Function(_$IngredientImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? text = null,
    Object? optional = null,
    Object? source = freezed,
    Object? table = null,
  }) {
    return _then(_$IngredientImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      optional: null == optional
          ? _value.optional
          : optional // ignore: cast_nullable_to_non_nullable
              as bool,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      table: null == table
          ? _value._table
          : table // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientImpl implements _Ingredient {
  const _$IngredientImpl(
      {required this.name,
      required this.text,
      this.optional = false,
      this.source,
      final Map<String, String> table = const {}})
      : _table = table;

  factory _$IngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientImplFromJson(json);

  @override
  final String name;
// 食材名称
  @override
  final String text;
// 完整原始文本（如 "羊腩 500g" 或 "炸腐竹 30g-50g"）
  @override
  @JsonKey()
  final bool optional;
  @override
  final String? source;
  final Map<String, String> _table;
  @override
  @JsonKey()
  Map<String, String> get table {
    if (_table is EqualUnmodifiableMapView) return _table;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_table);
  }

  @override
  String toString() {
    return 'Ingredient(name: $name, text: $text, optional: $optional, source: $source, table: $table)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.optional, optional) ||
                other.optional == optional) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._table, _table));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, text, optional, source,
      const DeepCollectionEquality().hash(_table));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      __$$IngredientImplCopyWithImpl<_$IngredientImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientImplToJson(
      this,
    );
  }
}

abstract class _Ingredient implements Ingredient {
  const factory _Ingredient(
      {required final String name,
      required final String text,
      final bool optional,
      final String? source,
      final Map<String, String> table}) = _$IngredientImpl;

  factory _Ingredient.fromJson(Map<String, dynamic> json) =
      _$IngredientImpl.fromJson;

  @override
  String get name;
  @override // 食材名称
  String get text;
  @override // 完整原始文本（如 "羊腩 500g" 或 "炸腐竹 30g-50g"）
  bool get optional;
  @override
  String? get source;
  @override
  Map<String, String> get table;
  @override
  @JsonKey(ignore: true)
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CookingStep _$CookingStepFromJson(Map<String, dynamic> json) {
  return _CookingStep.fromJson(json);
}

/// @nodoc
mixin _$CookingStep {
  String get kind => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CookingStepCopyWith<CookingStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CookingStepCopyWith<$Res> {
  factory $CookingStepCopyWith(
          CookingStep value, $Res Function(CookingStep) then) =
      _$CookingStepCopyWithImpl<$Res, CookingStep>;
  @useResult
  $Res call({String kind, String? title, String description});
}

/// @nodoc
class _$CookingStepCopyWithImpl<$Res, $Val extends CookingStep>
    implements $CookingStepCopyWith<$Res> {
  _$CookingStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? title = freezed,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CookingStepImplCopyWith<$Res>
    implements $CookingStepCopyWith<$Res> {
  factory _$$CookingStepImplCopyWith(
          _$CookingStepImpl value, $Res Function(_$CookingStepImpl) then) =
      __$$CookingStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String? title, String description});
}

/// @nodoc
class __$$CookingStepImplCopyWithImpl<$Res>
    extends _$CookingStepCopyWithImpl<$Res, _$CookingStepImpl>
    implements _$$CookingStepImplCopyWith<$Res> {
  __$$CookingStepImplCopyWithImpl(
      _$CookingStepImpl _value, $Res Function(_$CookingStepImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? title = freezed,
    Object? description = null,
  }) {
    return _then(_$CookingStepImpl(
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CookingStepImpl implements _CookingStep {
  const _$CookingStepImpl(
      {this.kind = 'step', this.title, required this.description});

  factory _$CookingStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$CookingStepImplFromJson(json);

  @override
  @JsonKey()
  final String kind;
  @override
  final String? title;
  @override
  final String description;

  @override
  String toString() {
    return 'CookingStep(kind: $kind, title: $title, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CookingStepImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, kind, title, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CookingStepImplCopyWith<_$CookingStepImpl> get copyWith =>
      __$$CookingStepImplCopyWithImpl<_$CookingStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CookingStepImplToJson(
      this,
    );
  }
}

abstract class _CookingStep implements CookingStep {
  const factory _CookingStep(
      {final String kind,
      final String? title,
      required final String description}) = _$CookingStepImpl;

  factory _CookingStep.fromJson(Map<String, dynamic> json) =
      _$CookingStepImpl.fromJson;

  @override
  String get kind;
  @override
  String? get title;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$CookingStepImplCopyWith<_$CookingStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
