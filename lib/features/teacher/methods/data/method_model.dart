import 'package:freezed_annotation/freezed_annotation.dart';

part 'method_model.freezed.dart';
part 'method_model.g.dart';

@freezed
class MethodModel with _$MethodModel {
  const factory MethodModel({
    required String id,
    required String type,
    Map<String, dynamic>? config,
  }) = _MethodModel;

  factory MethodModel.fromJson(Map<String, dynamic> json) =>
      _$MethodModelFromJson(json);
}
