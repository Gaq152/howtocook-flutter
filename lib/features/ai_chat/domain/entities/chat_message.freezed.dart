// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  MessageRole get role => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  List<String>? get imageUrls =>
      throw _privateConstructorUsedError; // 图片 URL 列表
  List<String>? get localImagePaths =>
      throw _privateConstructorUsedError; // 本地图片路径（用于历史记录）
  List<RecipeCard>? get recipeCards =>
      throw _privateConstructorUsedError; // 菜谱卡片
  MessageStatus get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String content,
      MessageRole role,
      DateTime timestamp,
      List<String>? imageUrls,
      List<String>? localImagePaths,
      List<RecipeCard>? recipeCards,
      MessageStatus status});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? role = null,
    Object? timestamp = null,
    Object? imageUrls = freezed,
    Object? localImagePaths = freezed,
    Object? recipeCards = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrls: freezed == imageUrls
          ? _value.imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      localImagePaths: freezed == localImagePaths
          ? _value.localImagePaths
          : localImagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      recipeCards: freezed == recipeCards
          ? _value.recipeCards
          : recipeCards // ignore: cast_nullable_to_non_nullable
              as List<RecipeCard>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String content,
      MessageRole role,
      DateTime timestamp,
      List<String>? imageUrls,
      List<String>? localImagePaths,
      List<RecipeCard>? recipeCards,
      MessageStatus status});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? role = null,
    Object? timestamp = null,
    Object? imageUrls = freezed,
    Object? localImagePaths = freezed,
    Object? recipeCards = freezed,
    Object? status = null,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MessageRole,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrls: freezed == imageUrls
          ? _value._imageUrls
          : imageUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      localImagePaths: freezed == localImagePaths
          ? _value._localImagePaths
          : localImagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      recipeCards: freezed == recipeCards
          ? _value._recipeCards
          : recipeCards // ignore: cast_nullable_to_non_nullable
              as List<RecipeCard>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.content,
      required this.role,
      required this.timestamp,
      final List<String>? imageUrls,
      final List<String>? localImagePaths,
      final List<RecipeCard>? recipeCards,
      this.status = MessageStatus.sent})
      : _imageUrls = imageUrls,
        _localImagePaths = localImagePaths,
        _recipeCards = recipeCards;

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String content;
  @override
  final MessageRole role;
  @override
  final DateTime timestamp;
  final List<String>? _imageUrls;
  @override
  List<String>? get imageUrls {
    final value = _imageUrls;
    if (value == null) return null;
    if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// 图片 URL 列表
  final List<String>? _localImagePaths;
// 图片 URL 列表
  @override
  List<String>? get localImagePaths {
    final value = _localImagePaths;
    if (value == null) return null;
    if (_localImagePaths is EqualUnmodifiableListView) return _localImagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// 本地图片路径（用于历史记录）
  final List<RecipeCard>? _recipeCards;
// 本地图片路径（用于历史记录）
  @override
  List<RecipeCard>? get recipeCards {
    final value = _recipeCards;
    if (value == null) return null;
    if (_recipeCards is EqualUnmodifiableListView) return _recipeCards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// 菜谱卡片
  @override
  @JsonKey()
  final MessageStatus status;

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, role: $role, timestamp: $timestamp, imageUrls: $imageUrls, localImagePaths: $localImagePaths, recipeCards: $recipeCards, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality()
                .equals(other._imageUrls, _imageUrls) &&
            const DeepCollectionEquality()
                .equals(other._localImagePaths, _localImagePaths) &&
            const DeepCollectionEquality()
                .equals(other._recipeCards, _recipeCards) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      content,
      role,
      timestamp,
      const DeepCollectionEquality().hash(_imageUrls),
      const DeepCollectionEquality().hash(_localImagePaths),
      const DeepCollectionEquality().hash(_recipeCards),
      status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String content,
      required final MessageRole role,
      required final DateTime timestamp,
      final List<String>? imageUrls,
      final List<String>? localImagePaths,
      final List<RecipeCard>? recipeCards,
      final MessageStatus status}) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get content;
  @override
  MessageRole get role;
  @override
  DateTime get timestamp;
  @override
  List<String>? get imageUrls;
  @override // 图片 URL 列表
  List<String>? get localImagePaths;
  @override // 本地图片路径（用于历史记录）
  List<RecipeCard>? get recipeCards;
  @override // 菜谱卡片
  MessageStatus get status;
  @override
  @JsonKey(ignore: true)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeCard _$RecipeCardFromJson(Map<String, dynamic> json) {
  return _RecipeCard.fromJson(json);
}

/// @nodoc
mixin _$RecipeCard {
  String get recipeId => throw _privateConstructorUsedError;
  String get recipeName => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeCardCopyWith<RecipeCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeCardCopyWith<$Res> {
  factory $RecipeCardCopyWith(
          RecipeCard value, $Res Function(RecipeCard) then) =
      _$RecipeCardCopyWithImpl<$Res, RecipeCard>;
  @useResult
  $Res call(
      {String recipeId, String recipeName, String? imageUrl, String? category});
}

/// @nodoc
class _$RecipeCardCopyWithImpl<$Res, $Val extends RecipeCard>
    implements $RecipeCardCopyWith<$Res> {
  _$RecipeCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? recipeName = null,
    Object? imageUrl = freezed,
    Object? category = freezed,
  }) {
    return _then(_value.copyWith(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _value.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeCardImplCopyWith<$Res>
    implements $RecipeCardCopyWith<$Res> {
  factory _$$RecipeCardImplCopyWith(
          _$RecipeCardImpl value, $Res Function(_$RecipeCardImpl) then) =
      __$$RecipeCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String recipeId, String recipeName, String? imageUrl, String? category});
}

/// @nodoc
class __$$RecipeCardImplCopyWithImpl<$Res>
    extends _$RecipeCardCopyWithImpl<$Res, _$RecipeCardImpl>
    implements _$$RecipeCardImplCopyWith<$Res> {
  __$$RecipeCardImplCopyWithImpl(
      _$RecipeCardImpl _value, $Res Function(_$RecipeCardImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? recipeName = null,
    Object? imageUrl = freezed,
    Object? category = freezed,
  }) {
    return _then(_$RecipeCardImpl(
      recipeId: null == recipeId
          ? _value.recipeId
          : recipeId // ignore: cast_nullable_to_non_nullable
              as String,
      recipeName: null == recipeName
          ? _value.recipeName
          : recipeName // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeCardImpl implements _RecipeCard {
  const _$RecipeCardImpl(
      {required this.recipeId,
      required this.recipeName,
      this.imageUrl,
      this.category});

  factory _$RecipeCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeCardImplFromJson(json);

  @override
  final String recipeId;
  @override
  final String recipeName;
  @override
  final String? imageUrl;
  @override
  final String? category;

  @override
  String toString() {
    return 'RecipeCard(recipeId: $recipeId, recipeName: $recipeName, imageUrl: $imageUrl, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeCardImpl &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.recipeName, recipeName) ||
                other.recipeName == recipeName) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, recipeId, recipeName, imageUrl, category);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeCardImplCopyWith<_$RecipeCardImpl> get copyWith =>
      __$$RecipeCardImplCopyWithImpl<_$RecipeCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeCardImplToJson(
      this,
    );
  }
}

abstract class _RecipeCard implements RecipeCard {
  const factory _RecipeCard(
      {required final String recipeId,
      required final String recipeName,
      final String? imageUrl,
      final String? category}) = _$RecipeCardImpl;

  factory _RecipeCard.fromJson(Map<String, dynamic> json) =
      _$RecipeCardImpl.fromJson;

  @override
  String get recipeId;
  @override
  String get recipeName;
  @override
  String? get imageUrl;
  @override
  String? get category;
  @override
  @JsonKey(ignore: true)
  _$$RecipeCardImplCopyWith<_$RecipeCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
