// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_item_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SyncItemState {
  SyncItemType get type => throw _privateConstructorUsedError;
  SyncItemStatus get status => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError; // 0-100
  int get totalItems => throw _privateConstructorUsedError; // 总数
  int get completedItems => throw _privateConstructorUsedError; // 已完成数
  String? get message => throw _privateConstructorUsedError; // 提示信息
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SyncItemStateCopyWith<SyncItemState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncItemStateCopyWith<$Res> {
  factory $SyncItemStateCopyWith(
          SyncItemState value, $Res Function(SyncItemState) then) =
      _$SyncItemStateCopyWithImpl<$Res, SyncItemState>;
  @useResult
  $Res call(
      {SyncItemType type,
      SyncItemStatus status,
      int progress,
      int totalItems,
      int completedItems,
      String? message,
      String? error});
}

/// @nodoc
class _$SyncItemStateCopyWithImpl<$Res, $Val extends SyncItemState>
    implements $SyncItemStateCopyWith<$Res> {
  _$SyncItemStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? status = null,
    Object? progress = null,
    Object? totalItems = null,
    Object? completedItems = null,
    Object? message = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SyncItemType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncItemStatus,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      totalItems: null == totalItems
          ? _value.totalItems
          : totalItems // ignore: cast_nullable_to_non_nullable
              as int,
      completedItems: null == completedItems
          ? _value.completedItems
          : completedItems // ignore: cast_nullable_to_non_nullable
              as int,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SyncItemStateImplCopyWith<$Res>
    implements $SyncItemStateCopyWith<$Res> {
  factory _$$SyncItemStateImplCopyWith(
          _$SyncItemStateImpl value, $Res Function(_$SyncItemStateImpl) then) =
      __$$SyncItemStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SyncItemType type,
      SyncItemStatus status,
      int progress,
      int totalItems,
      int completedItems,
      String? message,
      String? error});
}

/// @nodoc
class __$$SyncItemStateImplCopyWithImpl<$Res>
    extends _$SyncItemStateCopyWithImpl<$Res, _$SyncItemStateImpl>
    implements _$$SyncItemStateImplCopyWith<$Res> {
  __$$SyncItemStateImplCopyWithImpl(
      _$SyncItemStateImpl _value, $Res Function(_$SyncItemStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? status = null,
    Object? progress = null,
    Object? totalItems = null,
    Object? completedItems = null,
    Object? message = freezed,
    Object? error = freezed,
  }) {
    return _then(_$SyncItemStateImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SyncItemType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncItemStatus,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      totalItems: null == totalItems
          ? _value.totalItems
          : totalItems // ignore: cast_nullable_to_non_nullable
              as int,
      completedItems: null == completedItems
          ? _value.completedItems
          : completedItems // ignore: cast_nullable_to_non_nullable
              as int,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SyncItemStateImpl implements _SyncItemState {
  const _$SyncItemStateImpl(
      {required this.type,
      required this.status,
      this.progress = 0,
      this.totalItems = 0,
      this.completedItems = 0,
      this.message,
      this.error});

  @override
  final SyncItemType type;
  @override
  final SyncItemStatus status;
  @override
  @JsonKey()
  final int progress;
// 0-100
  @override
  @JsonKey()
  final int totalItems;
// 总数
  @override
  @JsonKey()
  final int completedItems;
// 已完成数
  @override
  final String? message;
// 提示信息
  @override
  final String? error;

  @override
  String toString() {
    return 'SyncItemState(type: $type, status: $status, progress: $progress, totalItems: $totalItems, completedItems: $completedItems, message: $message, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncItemStateImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.completedItems, completedItems) ||
                other.completedItems == completedItems) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, status, progress,
      totalItems, completedItems, message, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncItemStateImplCopyWith<_$SyncItemStateImpl> get copyWith =>
      __$$SyncItemStateImplCopyWithImpl<_$SyncItemStateImpl>(this, _$identity);
}

abstract class _SyncItemState implements SyncItemState {
  const factory _SyncItemState(
      {required final SyncItemType type,
      required final SyncItemStatus status,
      final int progress,
      final int totalItems,
      final int completedItems,
      final String? message,
      final String? error}) = _$SyncItemStateImpl;

  @override
  SyncItemType get type;
  @override
  SyncItemStatus get status;
  @override
  int get progress;
  @override // 0-100
  int get totalItems;
  @override // 总数
  int get completedItems;
  @override // 已完成数
  String? get message;
  @override // 提示信息
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$SyncItemStateImplCopyWith<_$SyncItemStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
