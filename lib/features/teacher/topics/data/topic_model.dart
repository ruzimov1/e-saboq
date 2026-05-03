import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic_model.freezed.dart';

@freezed
class TopicModel with _$TopicModel {
  const factory TopicModel({
    required String id,
    required String name,
  }) = _TopicModel;
}

TopicModel topicModelFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final d = doc.data();
  return TopicModel(
    id: doc.id,
    name: d['name'] as String,
  );
}
