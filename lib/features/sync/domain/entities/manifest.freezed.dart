// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Manifest _$ManifestFromJson(Map<String, dynamic> json) {
  return _Manifest.fromJson(json);
}

/// @nodoc
mixin _$Manifest {
  String get version => throw _privateConstructorUsedError; // 版本号
  String get generatedAt => throw _privateConstructorUsedError; // 生成时间
  int get totalRecipes => throw _privateConstructorUsedError; // 菜谱总数
  int get totalTips => throw _privateConstructorUsedError; // 技巧总数
  Map<String, CategoryInfo> get categories =>
      throw _privateConstructorUsedError; // 分类信息
  List<RecipeIndex> get recipes => throw _privateConstructorUsedError; // 菜谱索引
  List<TipIndex> get tips => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ManifestCopyWith<Manifest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ManifestCopyWith<$Res> {
  factory $ManifestCopyWith(Manifest value, $Res Function(Manifest) then) =
      _$ManifestCopyWithImpl<$Res, Manifest>;
  @useResult
  $Res call(
      {String version,
      String generatedAt,
      int totalRecipes,
      int totalTips,
      Map<String, CategoryInfo> categories,
      List<RecipeIndex> recipes,
      List<TipIndex> tips});
}

/// @nodoc
class _$ManifestCopyWithImpl<$Res, $Val extends Manifest>
    implements $ManifestCopyWith<$Res> {
  _$ManifestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? generatedAt = null,
    Object? totalRecipes = null,
    Object? totalTips = null,
    Object? categories = null,
    Object? recipes = null,
    Object? tips = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      totalRecipes: null == totalRecipes
          ? _value.totalRecipes
          : totalRecipes // ignore: cast_nullable_to_non_nullable
              as int,
      totalTips: null == totalTips
          ? _value.totalTips
          : totalTips // ignore: cast_nullable_to_non_nullable
              as int,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as Map<String, CategoryInfo>,
      recipes: null == recipes
          ? _value.recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<RecipeIndex>,
      tips: null == tips
          ? _value.tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<TipIndex>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ManifestImplCopyWith<$Res>
    implements $ManifestCopyWith<$Res> {
  factory _$$ManifestImplCopyWith(
          _$ManifestImpl value, $Res Function(_$ManifestImpl) then) =
      __$$ManifestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      String generatedAt,
      int totalRecipes,
      int totalTips,
      Map<String, CategoryInfo> categories,
      List<RecipeIndex> recipes,
      List<TipIndex> tips});
}

/// @nodoc
class __$$ManifestImplCopyWithImpl<$Res>
    extends _$ManifestCopyWithImpl<$Res, _$ManifestImpl>
    implements _$$ManifestImplCopyWith<$Res> {
  __$$ManifestImplCopyWithImpl(
      _$ManifestImpl _value, $Res Function(_$ManifestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? generatedAt = null,
    Object? totalRecipes = null,
    Object? totalTips = null,
    Object? categories = null,
    Object? recipes = null,
    Object? tips = null,
  }) {
    return _then(_$ManifestImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      totalRecipes: null == totalRecipes
          ? _value.totalRecipes
          : totalRecipes // ignore: cast_nullable_to_non_nullable
              as int,
      totalTips: null == totalTips
          ? _value.totalTips
          : totalTips // ignore: cast_nullable_to_non_nullable
              as int,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as Map<String, CategoryInfo>,
      recipes: null == recipes
          ? _value._recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<RecipeIndex>,
      tips: null == tips
          ? _value._tips
          : tips // ignore: cast_nullable_to_non_nullable
              as List<TipIndex>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ManifestImpl implements _Manifest {
  const _$ManifestImpl(
      {required this.version,
      required this.generatedAt,
      required this.totalRecipes,
      required this.totalTips,
      required final Map<String, CategoryInfo> categories,
      required final List<RecipeIndex> recipes,
      final List<TipIndex> tips = const []})
      : _categories = categories,
        _recipes = recipes,
        _tips = tips;

  factory _$ManifestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ManifestImplFromJson(json);

  @override
  final String version;
// 版本号
  @override
  final String generatedAt;
// 生成时间
  @override
  final int totalRecipes;
// 菜谱总数
  @override
  final int totalTips;
// 技巧总数
  final Map<String, CategoryInfo> _categories;
// 技巧总数
  @override
  Map<String, CategoryInfo> get categories {
    if (_categories is EqualUnmodifiableMapView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categories);
  }

// 分类信息
  final List<RecipeIndex> _recipes;
// 分类信息
  @override
  List<RecipeIndex> get recipes {
    if (_recipes is EqualUnmodifiableListView) return _recipes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipes);
  }

// 菜谱索引
  final List<TipIndex> _tips;
// 菜谱索引
  @override
  @JsonKey()
  List<TipIndex> get tips {
    if (_tips is EqualUnmodifiableListView) return _tips;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tips);
  }

  @override
  String toString() {
    return 'Manifest(version: $version, generatedAt: $generatedAt, totalRecipes: $totalRecipes, totalTips: $totalTips, categories: $categories, recipes: $recipes, tips: $tips)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ManifestImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.totalRecipes, totalRecipes) ||
                other.totalRecipes == totalRecipes) &&
            (identical(other.totalTips, totalTips) ||
                other.totalTips == totalTips) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            const DeepCollectionEquality().equals(other._recipes, _recipes) &&
            const DeepCollectionEquality().equals(other._tips, _tips));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      generatedAt,
      totalRecipes,
      totalTips,
      const DeepCollectionEquality().hash(_categories),
      const DeepCollectionEquality().hash(_recipes),
      const DeepCollectionEquality().hash(_tips));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ManifestImplCopyWith<_$ManifestImpl> get copyWith =>
      __$$ManifestImplCopyWithImpl<_$ManifestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ManifestImplToJson(
      this,
    );
  }
}

abstract class _Manifest implements Manifest {
  const factory _Manifest(
      {required final String version,
      required final String generatedAt,
      required final int totalRecipes,
      required final int totalTips,
      required final Map<String, CategoryInfo> categories,
      required final List<RecipeIndex> recipes,
      final List<TipIndex> tips}) = _$ManifestImpl;

  factory _Manifest.fromJson(Map<String, dynamic> json) =
      _$ManifestImpl.fromJson;

  @override
  String get version;
  @override // 版本号
  String get generatedAt;
  @override // 生成时间
  int get totalRecipes;
  @override // 菜谱总数
  int get totalTips;
  @override // 技巧总数
  Map<String, CategoryInfo> get categories;
  @override // 分类信息
  List<RecipeIndex> get recipes;
  @override // 菜谱索引
  List<TipIndex> get tips;
  @override
  @JsonKey(ignore: true)
  _$$ManifestImplCopyWith<_$ManifestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CategoryInfo _$CategoryInfoFromJson(Map<String, dynamic> json) {
  return _CategoryInfo.fromJson(json);
}

/// @nodoc
mixin _$CategoryInfo {
  String get name => throw _privateConstructorUsedError; // 分类名称（如 "水产"）
  int get count => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CategoryInfoCopyWith<CategoryInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryInfoCopyWith<$Res> {
  factory $CategoryInfoCopyWith(
          CategoryInfo value, $Res Function(CategoryInfo) then) =
      _$CategoryInfoCopyWithImpl<$Res, CategoryInfo>;
  @useResult
  $Res call({String name, int count});
}

/// @nodoc
class _$CategoryInfoCopyWithImpl<$Res, $Val extends CategoryInfo>
    implements $CategoryInfoCopyWith<$Res> {
  _$CategoryInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryInfoImplCopyWith<$Res>
    implements $CategoryInfoCopyWith<$Res> {
  factory _$$CategoryInfoImplCopyWith(
          _$CategoryInfoImpl value, $Res Function(_$CategoryInfoImpl) then) =
      __$$CategoryInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int count});
}

/// @nodoc
class __$$CategoryInfoImplCopyWithImpl<$Res>
    extends _$CategoryInfoCopyWithImpl<$Res, _$CategoryInfoImpl>
    implements _$$CategoryInfoImplCopyWith<$Res> {
  __$$CategoryInfoImplCopyWithImpl(
      _$CategoryInfoImpl _value, $Res Function(_$CategoryInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
  }) {
    return _then(_$CategoryInfoImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryInfoImpl implements _CategoryInfo {
  const _$CategoryInfoImpl({required this.name, required this.count});

  factory _$CategoryInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryInfoImplFromJson(json);

  @override
  final String name;
// 分类名称（如 "水产"）
  @override
  final int count;

  @override
  String toString() {
    return 'CategoryInfo(name: $name, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryInfoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, count);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryInfoImplCopyWith<_$CategoryInfoImpl> get copyWith =>
      __$$CategoryInfoImplCopyWithImpl<_$CategoryInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryInfoImplToJson(
      this,
    );
  }
}

abstract class _CategoryInfo implements CategoryInfo {
  const factory _CategoryInfo(
      {required final String name,
      required final int count}) = _$CategoryInfoImpl;

  factory _CategoryInfo.fromJson(Map<String, dynamic> json) =
      _$CategoryInfoImpl.fromJson;

  @override
  String get name;
  @override // 分类名称（如 "水产"）
  int get count;
  @override
  @JsonKey(ignore: true)
  _$$CategoryInfoImplCopyWith<_$CategoryInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeIndex _$RecipeIndexFromJson(Map<String, dynamic> json) {
  return _RecipeIndex.fromJson(json);
}

/// @nodoc
mixin _$RecipeIndex {
  String get id => throw _privateConstructorUsedError; // 菜谱 ID
  String get name => throw _privateConstructorUsedError; // 菜谱名称
  String get category => throw _privateConstructorUsedError; // 分类 ID
  String get categoryName => throw _privateConstructorUsedError; // 分类名称
  int get difficulty => throw _privateConstructorUsedError; // 难度等级 1-5
  String get hash => throw _privateConstructorUsedError; // 文件 hash，用于检测变化
  bool get hasImages => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeIndexCopyWith<RecipeIndex> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeIndexCopyWith<$Res> {
  factory $RecipeIndexCopyWith(
          RecipeIndex value, $Res Function(RecipeIndex) then) =
      _$RecipeIndexCopyWithImpl<$Res, RecipeIndex>;
  @useResult
  $Res call(
      {String id,
      String name,
      String category,
      String categoryName,
      int difficulty,
      String hash,
      bool hasImages});
}

/// @nodoc
class _$RecipeIndexCopyWithImpl<$Res, $Val extends RecipeIndex>
    implements $RecipeIndexCopyWith<$Res> {
  _$RecipeIndexCopyWithImpl(this._value, this._then);

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
    Object? hash = null,
    Object? hasImages = null,
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
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      hasImages: null == hasImages
          ? _value.hasImages
          : hasImages // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeIndexImplCopyWith<$Res>
    implements $RecipeIndexCopyWith<$Res> {
  factory _$$RecipeIndexImplCopyWith(
          _$RecipeIndexImpl value, $Res Function(_$RecipeIndexImpl) then) =
      __$$RecipeIndexImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String category,
      String categoryName,
      int difficulty,
      String hash,
      bool hasImages});
}

/// @nodoc
class __$$RecipeIndexImplCopyWithImpl<$Res>
    extends _$RecipeIndexCopyWithImpl<$Res, _$RecipeIndexImpl>
    implements _$$RecipeIndexImplCopyWith<$Res> {
  __$$RecipeIndexImplCopyWithImpl(
      _$RecipeIndexImpl _value, $Res Function(_$RecipeIndexImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? categoryName = null,
    Object? difficulty = null,
    Object? hash = null,
    Object? hasImages = null,
  }) {
    return _then(_$RecipeIndexImpl(
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
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      hasImages: null == hasImages
          ? _value.hasImages
          : hasImages // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeIndexImpl implements _RecipeIndex {
  const _$RecipeIndexImpl(
      {required this.id,
      required this.name,
      required this.category,
      required this.categoryName,
      required this.difficulty,
      required this.hash,
      this.hasImages = false});

  factory _$RecipeIndexImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeIndexImplFromJson(json);

  @override
  final String id;
// 菜谱 ID
  @override
  final String name;
// 菜谱名称
  @override
  final String category;
// 分类 ID
  @override
  final String categoryName;
// 分类名称
  @override
  final int difficulty;
// 难度等级 1-5
  @override
  final String hash;
// 文件 hash，用于检测变化
  @override
  @JsonKey()
  final bool hasImages;

  @override
  String toString() {
    return 'RecipeIndex(id: $id, name: $name, category: $category, categoryName: $categoryName, difficulty: $difficulty, hash: $hash, hasImages: $hasImages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeIndexImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.hasImages, hasImages) ||
                other.hasImages == hasImages));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, category, categoryName,
      difficulty, hash, hasImages);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeIndexImplCopyWith<_$RecipeIndexImpl> get copyWith =>
      __$$RecipeIndexImplCopyWithImpl<_$RecipeIndexImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeIndexImplToJson(
      this,
    );
  }
}

abstract class _RecipeIndex implements RecipeIndex {
  const factory _RecipeIndex(
      {required final String id,
      required final String name,
      required final String category,
      required final String categoryName,
      required final int difficulty,
      required final String hash,
      final bool hasImages}) = _$RecipeIndexImpl;

  factory _RecipeIndex.fromJson(Map<String, dynamic> json) =
      _$RecipeIndexImpl.fromJson;

  @override
  String get id;
  @override // 菜谱 ID
  String get name;
  @override // 菜谱名称
  String get category;
  @override // 分类 ID
  String get categoryName;
  @override // 分类名称
  int get difficulty;
  @override // 难度等级 1-5
  String get hash;
  @override // 文件 hash，用于检测变化
  bool get hasImages;
  @override
  @JsonKey(ignore: true)
  _$$RecipeIndexImplCopyWith<_$RecipeIndexImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TipIndex _$TipIndexFromJson(Map<String, dynamic> json) {
  return _TipIndex.fromJson(json);
}

/// @nodoc
mixin _$TipIndex {
  String get id => throw _privateConstructorUsedError; // 技巧 ID
  String get title => throw _privateConstructorUsedError; // 技巧标题
  String get category => throw _privateConstructorUsedError; // 分类 ID
  String get categoryName => throw _privateConstructorUsedError; // 分类名称
  String get hash => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TipIndexCopyWith<TipIndex> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TipIndexCopyWith<$Res> {
  factory $TipIndexCopyWith(TipIndex value, $Res Function(TipIndex) then) =
      _$TipIndexCopyWithImpl<$Res, TipIndex>;
  @useResult
  $Res call(
      {String id,
      String title,
      String category,
      String categoryName,
      String hash});
}

/// @nodoc
class _$TipIndexCopyWithImpl<$Res, $Val extends TipIndex>
    implements $TipIndexCopyWith<$Res> {
  _$TipIndexCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? categoryName = null,
    Object? hash = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      categoryName: null == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TipIndexImplCopyWith<$Res>
    implements $TipIndexCopyWith<$Res> {
  factory _$$TipIndexImplCopyWith(
          _$TipIndexImpl value, $Res Function(_$TipIndexImpl) then) =
      __$$TipIndexImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String category,
      String categoryName,
      String hash});
}

/// @nodoc
class __$$TipIndexImplCopyWithImpl<$Res>
    extends _$TipIndexCopyWithImpl<$Res, _$TipIndexImpl>
    implements _$$TipIndexImplCopyWith<$Res> {
  __$$TipIndexImplCopyWithImpl(
      _$TipIndexImpl _value, $Res Function(_$TipIndexImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? categoryName = null,
    Object? hash = null,
  }) {
    return _then(_$TipIndexImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      categoryName: null == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TipIndexImpl implements _TipIndex {
  const _$TipIndexImpl(
      {required this.id,
      required this.title,
      required this.category,
      required this.categoryName,
      required this.hash});

  factory _$TipIndexImpl.fromJson(Map<String, dynamic> json) =>
      _$$TipIndexImplFromJson(json);

  @override
  final String id;
// 技巧 ID
  @override
  final String title;
// 技巧标题
  @override
  final String category;
// 分类 ID
  @override
  final String categoryName;
// 分类名称
  @override
  final String hash;

  @override
  String toString() {
    return 'TipIndex(id: $id, title: $title, category: $category, categoryName: $categoryName, hash: $hash)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TipIndexImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.hash, hash) || other.hash == hash));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, category, categoryName, hash);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TipIndexImplCopyWith<_$TipIndexImpl> get copyWith =>
      __$$TipIndexImplCopyWithImpl<_$TipIndexImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TipIndexImplToJson(
      this,
    );
  }
}

abstract class _TipIndex implements TipIndex {
  const factory _TipIndex(
      {required final String id,
      required final String title,
      required final String category,
      required final String categoryName,
      required final String hash}) = _$TipIndexImpl;

  factory _TipIndex.fromJson(Map<String, dynamic> json) =
      _$TipIndexImpl.fromJson;

  @override
  String get id;
  @override // 技巧 ID
  String get title;
  @override // 技巧标题
  String get category;
  @override // 分类 ID
  String get categoryName;
  @override // 分类名称
  String get hash;
  @override
  @JsonKey(ignore: true)
  _$$TipIndexImplCopyWith<_$TipIndexImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
