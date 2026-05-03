import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/firestore/firestore_subtree_delete.dart';
import 'class_model.dart';

class ClassesRepository {
  ClassesRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> _classes(String subjectId) {
    return _db.collection('subjects').doc(subjectId).collection('classes');
  }

  Stream<List<ClassModel>> watchClasses(String subjectId) {
    if (subjectId.isEmpty) {
      return Stream.value([]);
    }
    if (CurriculumCatalog.isCurriculumSubject(subjectId)) {
      return Stream.value(CurriculumCatalog.defaultGrades);
    }
    if (!_ready) {
      return Stream.value([]);
    }
    return _classes(subjectId).snapshots().map(
          (snap) => snap.docs.map(classModelFromDoc).toList(),
        );
  }

  Future<String> createClass({
    required String subjectId,
    required String name,
  }) async {
    final doc = await _classes(subjectId).add({'name': name.trim()});
    return doc.id;
  }

  /// Faqat qo'shimcha fan uchun Firestore sinfi (katalog sinflari yo'q).
  Future<void> deleteClass({
    required String subjectId,
    required String classId,
  }) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    if (CurriculumCatalog.isCurriculumSubject(subjectId)) {
      throw StateError('Tizim fanidagi sinfni o\'chirib bo\'lmaydi');
    }
    await FirestoreSubtreeDelete.deleteClassDocument(_db, subjectId, classId);
  }
}
