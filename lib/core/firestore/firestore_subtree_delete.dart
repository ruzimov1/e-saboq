import 'package:cloud_firestore/cloud_firestore.dart';

/// `subjects` ostidagi sinf / mavzu / metod / topshiriq / topshiriq javoblari zanjirini o'chirish.
abstract final class FirestoreSubtreeDelete {
  static Future<void> deleteSubjectDocument(
    FirebaseFirestore db,
    String subjectId,
  ) async {
    final classesCol =
        db.collection('subjects').doc(subjectId).collection('classes');
    final classesSnap = await classesCol.get();
    for (final c in classesSnap.docs) {
      await _deleteTopicsUnderClass(db, subjectId, c.id);
      await c.reference.delete();
    }
    await db.collection('subjects').doc(subjectId).delete();
  }

  static Future<void> deleteClassDocument(
    FirebaseFirestore db,
    String subjectId,
    String classId,
  ) async {
    await _deleteTopicsUnderClass(db, subjectId, classId);
    await db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .delete();
  }

  static Future<void> _deleteTopicsUnderClass(
    FirebaseFirestore db,
    String subjectId,
    String classId,
  ) async {
    final topicsCol = db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics');
    final topicsSnap = await topicsCol.get();
    for (final t in topicsSnap.docs) {
      await _deleteMethodsUnderTopic(db, subjectId, classId, t.id);
      await t.reference.delete();
    }
  }

  static Future<void> deleteTopicDocument(
    FirebaseFirestore db,
    String subjectId,
    String classId,
    String topicId,
  ) async {
    await _deleteMethodsUnderTopic(db, subjectId, classId, topicId);
    await db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics')
        .doc(topicId)
        .delete();
  }

  static Future<void> _deleteMethodsUnderTopic(
    FirebaseFirestore db,
    String subjectId,
    String classId,
    String topicId,
  ) async {
    final methodsCol = db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics')
        .doc(topicId)
        .collection('methods');
    final methodsSnap = await methodsCol.get();
    for (final m in methodsSnap.docs) {
      await _deleteAssignmentsUnderMethod(
        db,
        subjectId,
        classId,
        topicId,
        m.id,
      );
      await m.reference.delete();
    }
  }

  static Future<void> deleteMethodDocument(
    FirebaseFirestore db,
    String subjectId,
    String classId,
    String topicId,
    String methodId,
  ) async {
    await _deleteAssignmentsUnderMethod(
      db,
      subjectId,
      classId,
      topicId,
      methodId,
    );
    await db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics')
        .doc(topicId)
        .collection('methods')
        .doc(methodId)
        .delete();
  }

  static Future<void> _deleteAssignmentsUnderMethod(
    FirebaseFirestore db,
    String subjectId,
    String classId,
    String topicId,
    String methodId,
  ) async {
    final methodRef = db
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics')
        .doc(topicId)
        .collection('methods')
        .doc(methodId);
    final assignmentsSnap = await methodRef.collection('assignments').get();
    for (final a in assignmentsSnap.docs) {
      final subsSnap = await a.reference.collection('submissions').get();
      for (final s in subsSnap.docs) {
        await s.reference.delete();
      }
      await a.reference.delete();
    }
  }
}
