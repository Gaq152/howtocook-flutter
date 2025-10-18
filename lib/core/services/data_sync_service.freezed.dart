// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_sync_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DataSyncState {
  SyncStatus get status => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError;
  int get downloadedRecipes => throw _privateConstructorUsedError;
  int get totalRecipes => throw _privateConstructorUsedError;
  int get downloadedTips => throw _privateConstructorUsedError;
  int get totalTips => throw _privateConstructorUsedError;
  int get downloadedImages => throw _privateConstructorUsedError;
  int get totalImages => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DataSyncStateCopyWith<DataSyncState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataSyncStateCopyWith<$Res> {
  factory $DataSyncStateCopyWith(
          DataSyncState value, $Res Function(DataSyncState) then) =
      _$DataSyncStateCopyWithImpl<$Res, DataSyncState>;
  @useResult
  $Res call(
      {SyncStatus status,
      int progress,
      int downloadedRecipes,
      int totalRecipes,
      int downloadedTips,
      int totalTips,
      int downloadedImages,
      int totalImages,
      String? error});
}

/// @nodoc
class _$DataSyncStateCopyWithImpl<$Res, $Val extends DataSyncState>
    implements $DataSyncStateCopyWith<$Res> {
  _$DataSyncStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? progress = null,
    Object? downloadedRecipes = null,
    Object? totalRecipes = null,
    Object? downloadedTips = null,
    Object? totalTips = null,
    Object? downloadedImages = null,
    Object? totalImages = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      downloadedRecipes: null == downloadedRecipes
          ? _value.downloadedRecipes
          : downloadedRecipes // ignore: cast_nullable_to_non_nullable
              as int,
      totalRecipes: null == totalRecipes
          ? _value.totalRecipes
          : totalRecipes // ignore: cast_nullable_to_non_nullable
              as int,
      downloadedTips: null == downloadedTips
          ? _value.downloadedTips
          : downloadedTips // ignore: cast_nullable_to_non_nullable
              as int,
      totalTips: null == totalTips
          ? _value.totalTips
          : totalTips // ignore: cast_nullable_to_non_nullable
              as int,
      downloadedImages: null == downloadedImages
          ? _value.downloadedImages
          : downloadedImages // ignore: cast_nullable_to_non_nullable
              as int,
      totalImages: null == totalImages
          ? _value.totalImages
          : totalImages // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DataSyncStateImplCopyWith<$Res>
    implements $DataSyncStateCopyWith<$Res> {
  factory _$$DataSyncStateImplCopyWith(
          _$DataSyncStateImpl value, $Res Function(_$DataSyncStateImpl) then) =
      __$$DataSyncStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SyncStatus status,
      int progress,
      int downloadedRecipes,
      int totalRecipes,
      int downloadedTips,
      int totalTips,
      int downloadedImages,
      int totalImages,
      String? error});
}

/// @nodoc
class __$$DataSyncStateImplCopyWithImpl<$Res>
    extends _$DataSyncStateCopyWithImpl<$Res, _$DataSyncStateImpl>
    implements _$$DataSyncStateImplCopyWith<$Res> {
  __$$DataSyncStateImplCopyWithImpl(
      _$DataSyncStateImpl _value, $Res Function(_$DataSyncStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? progress = null,
    Object? downloadedRecipes = null,
    Object? totalRecipes = null,
    Object? downloadedTips = null,
    Object? totalTips = null,
    Object? downloadedImages = null,
    Object? totalImages = null,
    Object? error = freezed,
  }) {
    return _then(_$DataSyncStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      downloadedRecipes: null == downloadedRecipes
          ? _value.downloadedRecipes
          : downloadedRecipes // ignore: cast_nullable_to_non_nullable
              as int,
      totalRecipes: null == totalRecipes
          ? _value.totalRecipes
          : totalRecipes // ignore: cast_nullable_to_non_nullable
              as int,
      downloadedTips: null == downloadedTips
          ? _value.downloadedTips
          : downloadedTips // ignore: cast_nullable_to_non_nullable
              as int,
      totalTips: null == totalTips
          ? _value.totalTips
          : totalTips // ignore: cast_nullable_to_non_nullable
              as int,
      downloadedImages: null == downloadedImages
          ? _value.downloadedImages
          : downloadedImages // ignore: cast_nullable_to_non_nullable
              as int,
      totalImages: null == totalImages
          ? _value.totalImages
          : totalImages // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DataSyncStateImpl implements _DataSyncState {
  const _$DataSyncStateImpl(
      {required this.status,
      required this.progress,
      required this.downloadedRecipes,
      required this.totalRecipes,
      required this.downloadedTips,
      required this.totalTips,
      required this.downloadedImages,
      required this.totalImages,
      this.error});

  @override
  final SyncStatus status;
  @override
  final int progress;
  @override
  final int downloadedRecipes;
  @override
  final int totalRecipes;
  @override
  final int downloadedTips;
  @override
  final int totalTips;
  @override
  final int downloadedImages;
  @override
  final int totalImages;
  @override
  final String? error;

  @override
  String toString() {
    return 'DataSyncState(status: $status, progress: $progress, downloadedRecipes: $downloadedRecipes, totalRecipes: $totalRecipes, downloadedTips: $downloadedTips, totalTips: $totalTips, downloadedImages: $downloadedImages, totalImages: $totalImages, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataSyncStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.downloadedRecipes, downloadedRecipes) ||
                other.downloadedRecipes == downloadedRecipes) &&
            (identical(other.totalRecipes, totalRecipes) ||
                other.totalRecipes == totalRecipes) &&
            (identical(other.downloadedTips, downloadedTips) ||
                other.downloadedTips == downloadedTips) &&
            (identical(other.totalTips, totalTips) ||
                other.totalTips == totalTips) &&
            (identical(other.downloadedImages, downloadedImages) ||
                other.downloadedImages == downloadedImages) &&
            (identical(other.totalImages, totalImages) ||
                other.totalImages == totalImages) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      progress,
      downloadedRecipes,
      totalRecipes,
      downloadedTips,
      totalTips,
      downloadedImages,
      totalImages,
      error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DataSyncStateImplCopyWith<_$DataSyncStateImpl> get copyWith =>
      __$$DataSyncStateImplCopyWithImpl<_$DataSyncStateImpl>(this, _$identity);
}

abstract class _DataSyncState implements DataSyncState {
  const factory _DataSyncState(
      {required final SyncStatus status,
      required final int progress,
      required final int downloadedRecipes,
      required final int totalRecipes,
      required final int downloadedTips,
      required final int totalTips,
      required final int downloadedImages,
      required final int totalImages,
      final String? error}) = _$DataSyncStateImpl;

  @override
  SyncStatus get status;
  @override
  int get progress;
  @override
  int get downloadedRecipes;
  @override
  int get totalRecipes;
  @override
  int get downloadedTips;
  @override
  int get totalTips;
  @override
  int get downloadedImages;
  @override
  int get totalImages;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$DataSyncStateImplCopyWith<_$DataSyncStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
