import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/firestore/firestore_subtree_delete.dart';
import 'subject_model.dart';

class SubjectsRepository {
  SubjectsRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  /// Fan sarlavhasi: avvalo katalog, so‘ng Firestore `name` (maxsus fanlar).
  Future<String> displayNameForSubject(String subjectId) async {
    final catalog = CurriculumCatalog.catalogSubjectName(subjectId);
    if (catalog != null) return catalog;
    if (!_ready) return subjectId;
    final doc = await _db.collection('subjects').doc(subjectId).get();
    final n = doc.data()?['name'] as String?;
    final t = n?.trim();
    if (t != null && t.isNotEmpty) return t;
    return subjectId;
  }

  /// O'quv dasturi (katalog) + o'qituvchi qo'shgan fanlar (Firestore).
  Stream<List<SubjectModel>> watchSubjects(String teacherId) {
    if (teacherId.isEmpty) {
      return Stream.value([]);
    }
    final catalog = CurriculumCatalog.subjects;
    if (!_ready) {
      return Stream.value(catalog);
    }
    return _db
        .collection('subjects')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
      final custom = snap.docs.map(subjectModelFromDoc).toList();
      final merged = [...catalog, ...custom];
      merged.sort((a, b) => a.name.compareTo(b.name));
      return merged;
    });
  }

  Future<String> createSubject({
    required String teacherId,
    required String name,
  }) async {
    final doc = await _db.collection('subjects').add({
      'teacherId': teacherId,
      'name': name.trim(),
      'custom': true,
    });
    final subjectId = doc.id;
    if (_ready) {
      try {
        await _seedDefaultClassesForCustomSubject(subjectId);
      } catch (_) {
        await doc.delete();
        rethrow;
      }
    }
    return subjectId;
  }

  /// 5–11 sinflar — tizim fanlari kabi, lekin Firestore da (maxsus fanlar uchun).
  Future<void> _seedDefaultClassesForCustomSubject(String subjectId) async {
    final col = _db.collection('subjects').doc(subjectId).collection('classes');
    final batch = _db.batch();
    for (final g in CurriculumCatalog.defaultGrades) {
      batch.set(col.doc(g.id), {'name': g.name});
    }
    await batch.commit();
  }

  /// Faqat Firestore dagi qo'shimcha fanlar (tizim fanlari o'chmaydi).
  Future<void> deleteSubject(String subjectId) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    if (CurriculumCatalog.isCurriculumSubject(subjectId)) {
      throw StateError('Tizim fanini o\'chirib bo\'lmaydi');
    }
    await FirestoreSubtreeDelete.deleteSubjectDocument(_db, subjectId);
  }
}
