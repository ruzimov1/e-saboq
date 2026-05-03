import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject_model.freezed.dart';

@freezed
class SubjectModel with _$SubjectModel {
  const factory SubjectModel({
    required String id,
    required String teacherId,
    required String name,
  }) = _SubjectModel;
}

SubjectModel subjectModelFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data();
  return SubjectModel(
    id: doc.id,
    teacherId: d['teacherId'] as String,
    name: d['name'] as String,
  );
}
