// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Tip _$TipFromJson(Map<String, dynamic> json) {
  return _Tip.fromJson(json);
}

/// @nodoc
mixin _$Tip {
  String get id => throw _privateConstructorUsedError; // 教程 ID
  String get title => throw _privateConstructorUsedError; // 教程标题
  String get category => throw _privateConstructorUsedError; // 分类 ID
  String get categoryName => throw _privateConstructorUsedError; // 分类名称
  String get content => throw _privateConstructorUsedError; // 正文内容
  List<TipSection> get sections => throw _privateConstructorUsedError; // 分节内容
  String get hash => throw _privateConstructorUsedError; // 数据哈希
  bool get isFavorite => throw _privateConstructorUsedError; // 是否收藏
  TipSource get source => throw _privateConstructorUsedError; // 数据来源
  DateTime? get createdAt => throw _privateConstructorUsedError; // 创建时间
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TipCopyWith<Tip> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TipCopyWith<$Res> {
  factory $TipCopyWith(Tip value, $Res Function(Tip) then) =
      _$TipCopyWithImpl<$Res, Tip>;
  @useResult
  $Res call(
      {String id,
      String title,
      String category,
      String categoryName,
      String content,
      List<TipSection> sections,
      String hash,
      bool isFavorite,
      TipSource source,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$TipCopyWithImpl<$Res, $Val extends Tip> implements $TipCopyWith<$Res> {
  _$TipCopyWithImpl(this._value, this._then);

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
    Object? content = null,
    Object? sections = null,
    Object? hash = null,
    Object? isFavorite = null,
    Object? source = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      sections: null == sections
          ? _value.sections
          : sections // ignore: cast_nullable_to_non_nullable
              as List<TipSection>,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TipSource,
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
abstract class _$$TipImplCopyWith<$Res> implements $TipCopyWith<$Res> {
  factory _$$TipImplCopyWith(_$TipImpl value, $Res Function(_$TipImpl) then) =
      __$$TipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String category,
      String categoryName,
      String content,
      List<TipSection> sections,
      String hash,
      bool isFavorite,
      TipSource source,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$TipImplCopyWithImpl<$Res> extends _$TipCopyWithImpl<$Res, _$TipImpl>
    implements _$$TipImplCopyWith<$Res> {
  __$$TipImplCopyWithImpl(_$TipImpl _value, $Res Function(_$TipImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? categoryName = null,
    Object? content = null,
    Object? sections = null,
    Object? hash = null,
    Object? isFavorite = null,
    Object? source = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$TipImpl(
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      sections: null == sections
          ? _value._sections
          : sections // ignore: cast_nullable_to_non_nullable
              as List<TipSection>,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TipSource,
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
class _$TipImpl implements _Tip {
  const _$TipImpl(
      {required this.id,
      required this.title,
      required this.category,
      required this.categoryName,
      this.content = '',
      final List<TipSection> sections = const <TipSection>[],
      required this.hash,
      this.isFavorite = false,
      this.source = TipSource.bundled,
      this.createdAt,
      this.updatedAt})
      : _sections = sections;

  factory _$TipImpl.fromJson(Map<String, dynamic> json) =>
      _$$TipImplFromJson(json);

  @override
  final String id;
// 教程 ID
  @override
  final String title;
// 教程标题
  @override
  final String category;
// 分类 ID
  @override
  final String categoryName;
// 分类名称
  @override
  @JsonKey()
  final String content;
// 正文内容
  final List<TipSection> _sections;
// 正文内容
  @override
  @JsonKey()
  List<TipSection> get sections {
    if (_sections is EqualUnmodifiableListView) return _sections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sections);
  }

// 分节内容
  @override
  final String hash;
// 数据哈希
  @override
  @JsonKey()
  final bool isFavorite;
// 是否收藏
  @override
  @JsonKey()
  final TipSource source;
// 数据来源
  @override
  final DateTime? createdAt;
// 创建时间
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Tip(id: $id, title: $title, category: $category, categoryName: $categoryName, content: $content, sections: $sections, hash: $hash, isFavorite: $isFavorite, source: $source, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TipImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._sections, _sections) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
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
      title,
      category,
      categoryName,
      content,
      const DeepCollectionEquality().hash(_sections),
      hash,
      isFavorite,
      source,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TipImplCopyWith<_$TipImpl> get copyWith =>
      __$$TipImplCopyWithImpl<_$TipImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TipImplToJson(
      this,
    );
  }
}

abstract class _Tip implements Tip {
  const factory _Tip(
      {required final String id,
      required final String title,
      required final String category,
      required final String categoryName,
      final String content,
      final List<TipSection> sections,
      required final String hash,
      final bool isFavorite,
      final TipSource source,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$TipImpl;

  factory _Tip.fromJson(Map<String, dynamic> json) = _$TipImpl.fromJson;

  @override
  String get id;
  @override // 教程 ID
  String get title;
  @override // 教程标题
  String get category;
  @override // 分类 ID
  String get categoryName;
  @override // 分类名称
  String get content;
  @override // 正文内容
  List<TipSection> get sections;
  @override // 分节内容
  String get hash;
  @override // 数据哈希
  bool get isFavorite;
  @override // 是否收藏
  TipSource get source;
  @override // 数据来源
  DateTime? get createdAt;
  @override // 创建时间
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$TipImplCopyWith<_$TipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TipSection _$TipSectionFromJson(Map<String, dynamic> json) {
  return _TipSection.fromJson(json);
}

/// @nodoc
mixin _$TipSection {
  String get title => throw _privateConstructorUsedError; // 分节标题
  String get content => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TipSectionCopyWith<TipSection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TipSectionCopyWith<$Res> {
  factory $TipSectionCopyWith(
          TipSection value, $Res Function(TipSection) then) =
      _$TipSectionCopyWithImpl<$Res, TipSection>;
  @useResult
  $Res call({String title, String content});
}

/// @nodoc
class _$TipSectionCopyWithImpl<$Res, $Val extends TipSection>
    implements $TipSectionCopyWith<$Res> {
  _$TipSectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TipSectionImplCopyWith<$Res>
    implements $TipSectionCopyWith<$Res> {
  factory _$$TipSectionImplCopyWith(
          _$TipSectionImpl value, $Res Function(_$TipSectionImpl) then) =
      __$$TipSectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String content});
}

/// @nodoc
class __$$TipSectionImplCopyWithImpl<$Res>
    extends _$TipSectionCopyWithImpl<$Res, _$TipSectionImpl>
    implements _$$TipSectionImplCopyWith<$Res> {
  __$$TipSectionImplCopyWithImpl(
      _$TipSectionImpl _value, $Res Function(_$TipSectionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = null,
  }) {
    return _then(_$TipSectionImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TipSectionImpl implements _TipSection {
  const _$TipSectionImpl({required this.title, required this.content});

  factory _$TipSectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TipSectionImplFromJson(json);

  @override
  final String title;
// 分节标题
  @override
  final String content;

  @override
  String toString() {
    return 'TipSection(title: $title, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TipSectionImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, title, content);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TipSectionImplCopyWith<_$TipSectionImpl> get copyWith =>
      __$$TipSectionImplCopyWithImpl<_$TipSectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TipSectionImplToJson(
      this,
    );
  }
}

abstract class _TipSection implements TipSection {
  const factory _TipSection(
      {required final String title,
      required final String content}) = _$TipSectionImpl;

  factory _TipSection.fromJson(Map<String, dynamic> json) =
      _$TipSectionImpl.fromJson;

  @override
  String get title;
  @override // 分节标题
  String get content;
  @override
  @JsonKey(ignore: true)
  _$$TipSectionImplCopyWith<_$TipSectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
