import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/firestore/firestore_subtree_delete.dart';
import '../../methods/data/method_repository.dart';
import 'topic_model.dart';

class TopicsRepository {
  TopicsRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> _topics({
    required String subjectId,
    required String classId,
  }) {
    return _db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics');
  }

  Stream<List<TopicModel>> watchTopics({
    required String subjectId,
    required String classId,
  }) {
    if (subjectId.isEmpty || classId.isEmpty) {
      return Stream.value([]);
    }
    final builtIn = CurriculumCatalog.topicsFor(subjectId, classId);
    if (!_ready) {
      return Stream.value(builtIn);
    }
    return _topics(subjectId: subjectId, classId: classId).snapshots().map(
      (snap) {
        final custom = snap.docs.map(topicModelFromDoc).toList();
        return [...builtIn, ...custom];
      },
    );
  }

  Future<String> createTopic({
    required String subjectId,
    required String classId,
    required String name,
  }) async {
    final trimmed = name.trim();
    final doc = await _topics(subjectId: subjectId, classId: classId).add({
      'name': trimmed,
      'custom': true,
    });
    final topicId = doc.id;
    if (_ready && !CurriculumCatalog.isCurriculumSubject(subjectId)) {
      final displayName = '$classId-sinf: $trimmed';
      try {
        await MethodRepository(firestore: _db).seedPresetMethodsForCustomTopic(
          subjectId: subjectId,
          classId: classId,
          topicId: topicId,
          topicDisplayName: displayName,
        );
      } catch (_) {
        await doc.delete();
        rethrow;
      }
    }
    return topicId;
  }

  /// Faqat qo'shimcha mavzular (katalog `cur_*` mavzulari yo'q).
  Future<void> deleteTopic({
    required String subjectId,
    required String classId,
    required String topicId,
  }) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    if (topicId.startsWith('cur_')) {
      throw StateError('O\'quv dasturi mavzusini o\'chirib bo\'lmaydi');
    }
    await FirestoreSubtreeDelete.deleteTopicDocument(
      _db,
      subjectId,
      classId,
      topicId,
    );
  }
}
