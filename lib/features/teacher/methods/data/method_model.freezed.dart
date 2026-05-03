// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'method_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MethodModel _$MethodModelFromJson(Map<String, dynamic> json) {
  return _MethodModel.fromJson(json);
}

/// @nodoc
mixin _$MethodModel {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic>? get config => throw _privateConstructorUsedError;

  /// Serializes this MethodModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MethodModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MethodModelCopyWith<MethodModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MethodModelCopyWith<$Res> {
  factory $MethodModelCopyWith(
    MethodModel value,
    $Res Function(MethodModel) then,
  ) = _$MethodModelCopyWithImpl<$Res, MethodModel>;
  @useResult
  $Res call({String id, String type, Map<String, dynamic>? config});
}

/// @nodoc
class _$MethodModelCopyWithImpl<$Res, $Val extends MethodModel>
    implements $MethodModelCopyWith<$Res> {
  _$MethodModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MethodModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? config = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            config: freezed == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MethodModelImplCopyWith<$Res>
    implements $MethodModelCopyWith<$Res> {
  factory _$$MethodModelImplCopyWith(
    _$MethodModelImpl value,
    $Res Function(_$MethodModelImpl) then,
  ) = __$$MethodModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String type, Map<String, dynamic>? config});
}

/// @nodoc
class __$$MethodModelImplCopyWithImpl<$Res>
    extends _$MethodModelCopyWithImpl<$Res, _$MethodModelImpl>
    implements _$$MethodModelImplCopyWith<$Res> {
  __$$MethodModelImplCopyWithImpl(
    _$MethodModelImpl _value,
    $Res Function(_$MethodModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MethodModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? config = freezed,
  }) {
    return _then(
      _$MethodModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        config: freezed == config
            ? _value._config
            : config // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MethodModelImpl implements _MethodModel {
  const _$MethodModelImpl({
    required this.id,
    required this.type,
    final Map<String, dynamic>? config,
  }) : _config = config;

  factory _$MethodModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MethodModelImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  final Map<String, dynamic>? _config;
  @override
  Map<String, dynamic>? get config {
    final value = _config;
    if (value == null) return null;
    if (_config is EqualUnmodifiableMapView) return _config;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'MethodModel(id: $id, type: $type, config: $config)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MethodModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._config, _config));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    const DeepCollectionEquality().hash(_config),
  );

  /// Create a copy of MethodModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MethodModelImplCopyWith<_$MethodModelImpl> get copyWith =>
      __$$MethodModelImplCopyWithImpl<_$MethodModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MethodModelImplToJson(this);
  }
}

abstract class _MethodModel implements MethodModel {
  const factory _MethodModel({
    required final String id,
    required final String type,
    final Map<String, dynamic>? config,
  }) = _$MethodModelImpl;

  factory _MethodModel.fromJson(Map<String, dynamic> json) =
      _$MethodModelImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  Map<String, dynamic>? get config;

  /// Create a copy of MethodModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MethodModelImplCopyWith<_$MethodModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
