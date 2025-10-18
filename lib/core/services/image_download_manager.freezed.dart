// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_download_manager.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ImageDownloadState {
  DownloadStatus get status => throw _privateConstructorUsedError;
  int get totalTasks => throw _privateConstructorUsedError;
  int get completedTasks => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ImageDownloadStateCopyWith<ImageDownloadState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageDownloadStateCopyWith<$Res> {
  factory $ImageDownloadStateCopyWith(
          ImageDownloadState value, $Res Function(ImageDownloadState) then) =
      _$ImageDownloadStateCopyWithImpl<$Res, ImageDownloadState>;
  @useResult
  $Res call(
      {DownloadStatus status,
      int totalTasks,
      int completedTasks,
      int progress,
      String? error});
}

/// @nodoc
class _$ImageDownloadStateCopyWithImpl<$Res, $Val extends ImageDownloadState>
    implements $ImageDownloadStateCopyWith<$Res> {
  _$ImageDownloadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? totalTasks = null,
    Object? completedTasks = null,
    Object? progress = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadStatus,
      totalTasks: null == totalTasks
          ? _value.totalTasks
          : totalTasks // ignore: cast_nullable_to_non_nullable
              as int,
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as int,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImageDownloadStateImplCopyWith<$Res>
    implements $ImageDownloadStateCopyWith<$Res> {
  factory _$$ImageDownloadStateImplCopyWith(_$ImageDownloadStateImpl value,
          $Res Function(_$ImageDownloadStateImpl) then) =
      __$$ImageDownloadStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DownloadStatus status,
      int totalTasks,
      int completedTasks,
      int progress,
      String? error});
}

/// @nodoc
class __$$ImageDownloadStateImplCopyWithImpl<$Res>
    extends _$ImageDownloadStateCopyWithImpl<$Res, _$ImageDownloadStateImpl>
    implements _$$ImageDownloadStateImplCopyWith<$Res> {
  __$$ImageDownloadStateImplCopyWithImpl(_$ImageDownloadStateImpl _value,
      $Res Function(_$ImageDownloadStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? totalTasks = null,
    Object? completedTasks = null,
    Object? progress = null,
    Object? error = freezed,
  }) {
    return _then(_$ImageDownloadStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadStatus,
      totalTasks: null == totalTasks
          ? _value.totalTasks
          : totalTasks // ignore: cast_nullable_to_non_nullable
              as int,
      completedTasks: null == completedTasks
          ? _value.completedTasks
          : completedTasks // ignore: cast_nullable_to_non_nullable
              as int,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ImageDownloadStateImpl implements _ImageDownloadState {
  const _$ImageDownloadStateImpl(
      {required this.status,
      required this.totalTasks,
      required this.completedTasks,
      required this.progress,
      this.error});

  @override
  final DownloadStatus status;
  @override
  final int totalTasks;
  @override
  final int completedTasks;
  @override
  final int progress;
  @override
  final String? error;

  @override
  String toString() {
    return 'ImageDownloadState(status: $status, totalTasks: $totalTasks, completedTasks: $completedTasks, progress: $progress, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageDownloadStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalTasks, totalTasks) ||
                other.totalTasks == totalTasks) &&
            (identical(other.completedTasks, completedTasks) ||
                other.completedTasks == completedTasks) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, status, totalTasks, completedTasks, progress, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageDownloadStateImplCopyWith<_$ImageDownloadStateImpl> get copyWith =>
      __$$ImageDownloadStateImplCopyWithImpl<_$ImageDownloadStateImpl>(
          this, _$identity);
}

abstract class _ImageDownloadState implements ImageDownloadState {
  const factory _ImageDownloadState(
      {required final DownloadStatus status,
      required final int totalTasks,
      required final int completedTasks,
      required final int progress,
      final String? error}) = _$ImageDownloadStateImpl;

  @override
  DownloadStatus get status;
  @override
  int get totalTasks;
  @override
  int get completedTasks;
  @override
  int get progress;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$ImageDownloadStateImplCopyWith<_$ImageDownloadStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
