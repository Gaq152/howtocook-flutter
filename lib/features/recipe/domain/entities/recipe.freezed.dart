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
  String get id =>
      throw _privateConstructorUsedError; // 菜谱ID（如 "meat_dish_003ec59b"）
  String get name => throw _privateConstructorUsedError; // 菜谱名称
  String get category =>
      throw _privateConstructorUsedError; // 分类ID（如 "meat_dish"）
  @JsonKey(name: 'categoryName')
  String get categoryName => throw _privateConstructorUsedError; // 分类名称（如 "荤菜"）
  int get difficulty => throw _privateConstructorUsedError; // 难度等级 1-5
  List<String> get images => throw _privateConstructorUsedError; // 图片路径列表
  @JsonKey(fromJson: _ingredientsFromJson)
  List<Ingredient> get ingredients =>
      throw _privateConstructorUsedError; // 食材列表
  List<String> get tools => throw _privateConstructorUsedError; // 工具列表
  @JsonKey(fromJson: _stepsFromJson)
  List<CookingStep> get steps => throw _privateConstructorUsedError; // 烹饪步骤
  String? get tips => throw _privateConstructorUsedError; // 小贴士
  List<String> get warnings => throw _privateConstructorUsedError; // 警告信息
  String get hash => throw _privateConstructorUsedError; // 文件 hash
// 本地扩展字段（不在 JSON 中）
  bool get isFavorite => throw _privateConstructorUsedError;
  String? get userNote => throw _privateConstructorUsedError;
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
      {String id,
      String name,
      String category,
      @JsonKey(name: 'categoryName') String categoryName,
      int difficulty,
      List<String> images,
      @JsonKey(fromJson: _ingredientsFromJson) List<Ingredient> ingredients,
      List<String> tools,
      @JsonKey(fromJson: _stepsFromJson) List<CookingStep> steps,
      String? tips,
      List<String> warnings,
      String hash,
      bool isFavorite,
      String? userNote,
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
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? categoryName = null,
    Object? difficulty = null,
    Object? images = null,
    Object? ingredients = null,
    Object? tools = null,
    Object? steps = null,
    Object? tips = freezed,
    Object? warnings = null,
    Object? hash = null,
    Object? isFavorite = null,
    Object? userNote = freezed,
    Object? source = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
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
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      tools: null == tools
          ? _value.tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<CookingStep>,
      tips: freezed == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as String?,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      {String id,
      String name,
      String category,
      @JsonKey(name: 'categoryName') String categoryName,
      int difficulty,
      List<String> images,
      @JsonKey(fromJson: _ingredientsFromJson) List<Ingredient> ingredients,
      List<String> tools,
      @JsonKey(fromJson: _stepsFromJson) List<CookingStep> steps,
      String? tips,
      List<String> warnings,
      String hash,
      bool isFavorite,
      String? userNote,
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
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? categoryName = null,
    Object? difficulty = null,
    Object? images = null,
    Object? ingredients = null,
    Object? tools = null,
    Object? steps = null,
    Object? tips = freezed,
    Object? warnings = null,
    Object? hash = null,
    Object? isFavorite = null,
    Object? userNote = freezed,
    Object? source = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$RecipeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
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
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      tools: null == tools
          ? _value._tools
          : tools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      steps: null == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<CookingStep>,
      tips: freezed == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as String?,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      {required this.id,
      required this.name,
      required this.category,
      @JsonKey(name: 'categoryName') required this.categoryName,
      required this.difficulty,
      final List<String> images = const [],
      @JsonKey(fromJson: _ingredientsFromJson)
      required final List<Ingredient> ingredients,
      final List<String> tools = const [],
      @JsonKey(fromJson: _stepsFromJson) required final List<CookingStep> steps,
      this.tips,
      final List<String> warnings = const [],
      required this.hash,
      this.isFavorite = false,
      this.userNote,
      this.source = RecipeSource.bundled,
      this.createdAt,
      this.updatedAt})
      : _images = images,
        _ingredients = ingredients,
        _tools = tools,
        _steps = steps,
        _warnings = warnings;

  factory _$RecipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeImplFromJson(json);

  @override
  final String id;
// 菜谱ID（如 "meat_dish_003ec59b"）
  @override
  final String name;
// 菜谱名称
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
  final List<String> _images;
// 难度等级 1-5
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

// 图片路径列表
  final List<Ingredient> _ingredients;
// 图片路径列表
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
  final List<CookingStep> _steps;
// 工具列表
  @override
  @JsonKey(fromJson: _stepsFromJson)
  List<CookingStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

// 烹饪步骤
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
  final String hash;
// 文件 hash
// 本地扩展字段（不在 JSON 中）
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  final String? userNote;
  @override
  @JsonKey()
  final RecipeSource source;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, category: $category, categoryName: $categoryName, difficulty: $difficulty, images: $images, ingredients: $ingredients, tools: $tools, steps: $steps, tips: $tips, warnings: $warnings, hash: $hash, isFavorite: $isFavorite, userNote: $userNote, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality().equals(other._tools, _tools) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.tips, tips) || other.tips == tips) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
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
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      category,
      categoryName,
      difficulty,
      const DeepCollectionEquality().hash(_images),
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_tools),
      const DeepCollectionEquality().hash(_steps),
      tips,
      const DeepCollectionEquality().hash(_warnings),
      hash,
      isFavorite,
      userNote,
      source,
      createdAt,
      updatedAt);

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
      {required final String id,
      required final String name,
      required final String category,
      @JsonKey(name: 'categoryName') required final String categoryName,
      required final int difficulty,
      final List<String> images,
      @JsonKey(fromJson: _ingredientsFromJson)
      required final List<Ingredient> ingredients,
      final List<String> tools,
      @JsonKey(fromJson: _stepsFromJson) required final List<CookingStep> steps,
      final String? tips,
      final List<String> warnings,
      required final String hash,
      final bool isFavorite,
      final String? userNote,
      final RecipeSource source,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$RecipeImpl;

  factory _Recipe.fromJson(Map<String, dynamic> json) = _$RecipeImpl.fromJson;

  @override
  String get id;
  @override // 菜谱ID（如 "meat_dish_003ec59b"）
  String get name;
  @override // 菜谱名称
  String get category;
  @override // 分类ID（如 "meat_dish"）
  @JsonKey(name: 'categoryName')
  String get categoryName;
  @override // 分类名称（如 "荤菜"）
  int get difficulty;
  @override // 难度等级 1-5
  List<String> get images;
  @override // 图片路径列表
  @JsonKey(fromJson: _ingredientsFromJson)
  List<Ingredient> get ingredients;
  @override // 食材列表
  List<String> get tools;
  @override // 工具列表
  @JsonKey(fromJson: _stepsFromJson)
  List<CookingStep> get steps;
  @override // 烹饪步骤
  String? get tips;
  @override // 小贴士
  List<String> get warnings;
  @override // 警告信息
  String get hash;
  @override // 文件 hash
// 本地扩展字段（不在 JSON 中）
  bool get isFavorite;
  @override
  String? get userNote;
  @override
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

Ingredient _$IngredientFromJson(Map<String, dynamic> json) {
  return _Ingredient.fromJson(json);
}

/// @nodoc
mixin _$Ingredient {
  String get name => throw _privateConstructorUsedError; // 食材名称
  String get text => throw _privateConstructorUsedError;

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
  $Res call({String name, String text});
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
  $Res call({String name, String text});
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientImpl implements _Ingredient {
  const _$IngredientImpl({required this.name, required this.text});

  factory _$IngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientImplFromJson(json);

  @override
  final String name;
// 食材名称
  @override
  final String text;

  @override
  String toString() {
    return 'Ingredient(name: $name, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, text);

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
      required final String text}) = _$IngredientImpl;

  factory _Ingredient.fromJson(Map<String, dynamic> json) =
      _$IngredientImpl.fromJson;

  @override
  String get name;
  @override // 食材名称
  String get text;
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
  $Res call({String description});
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
    Object? description = null,
  }) {
    return _then(_value.copyWith(
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
  $Res call({String description});
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
    Object? description = null,
  }) {
    return _then(_$CookingStepImpl(
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
  const _$CookingStepImpl({required this.description});

  factory _$CookingStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$CookingStepImplFromJson(json);

  @override
  final String description;

  @override
  String toString() {
    return 'CookingStep(description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CookingStepImpl &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, description);

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
  const factory _CookingStep({required final String description}) =
      _$CookingStepImpl;

  factory _CookingStep.fromJson(Map<String, dynamic> json) =
      _$CookingStepImpl.fromJson;

  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$CookingStepImplCopyWith<_$CookingStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
