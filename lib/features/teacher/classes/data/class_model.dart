import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_model.freezed.dart';

@freezed
class ClassModel with _$ClassModel {
  const factory ClassModel({
    required String id,
    required String name,
  }) = _ClassModel;
}

ClassModel classModelFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data();
  return ClassModel(
    id: doc.id,
    name: d['name'] as String,
  );
}
