import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../router/assignment_route_args.dart';
import '../../../teacher/assignments/data/assignment_lookup.dart';

/// Firestore: `.../assignments/{assignmentId}/submissions/{studentId}`
class SubmissionRepository {
  SubmissionRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  DocumentReference<Map<String, dynamic>> _assignmentRef({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
  }) {
    return _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('classes')
        .doc(classId)
        .collection('topics')
        .doc(topicId)
        .collection('methods')
        .doc(methodId)
        .collection('assignments')
        .doc(assignmentId);
  }

  CollectionReference<Map<String, dynamic>> _submissions({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
  }) {
    return _assignmentRef(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
      assignmentId: assignmentId,
    ).collection('submissions');
  }

  /// Real vaqt fikrlar oqimi (o‘qituvchi moderatsiya).
  CollectionReference<Map<String, dynamic>> ideaFeedCollection(
    AssignmentRouteArgs args,
  ) {
    if (args.assignmentId == null || args.assignmentId!.isEmpty) {
      throw StateError('assignmentId yo‘q');
    }
    return _assignmentRef(
      subjectId: args.subjectId,
      classId: args.classId,
      topicId: args.topicId,
      methodId: args.methodId,
      assignmentId: args.assignmentId!,
    ).collection('ideaFeed');
  }

  CollectionReference<Map<String, dynamic>> _ideaFeedFromLookup(
    AssignmentLookup lookup,
  ) {
    return _assignmentRef(
      subjectId: lookup.subjectId,
      classId: lookup.classId,
      topicId: lookup.topicId,
      methodId: lookup.methodId,
      assignmentId: lookup.assignmentId,
    ).collection('ideaFeed');
  }

  Future<void> submit({
    required AssignmentLookup lookup,
    required String studentId,
    required dynamic answer,
    double? score,
  }) async {
    if (!_ready) return;
    final data = <String, dynamic>{
      'studentId': studentId,
      'answer': answer,
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewStatus': 'submitted',
    };
    if (score != null) {
      data['score'] = score;
    }
    data['subjectId'] = lookup.subjectId;
    data['classId'] = lookup.classId;
    data['topicId'] = lookup.topicId;
    data['methodId'] = lookup.methodId;
    data['assignmentId'] = lookup.assignmentId;
    data['assignmentTitle'] = lookup.data['title'];
    data['assignmentCode'] = lookup.data['code'];
    final subRef = _submissions(
      subjectId: lookup.subjectId,
      classId: lookup.classId,
      topicId: lookup.topicId,
      methodId: lookup.methodId,
      assignmentId: lookup.assignmentId,
    ).doc(studentId);

    final ideas = _extractBrainstormIdeas(answer);
    if (ideas != null) {
      final feed = _ideaFeedFromLookup(lookup);
      final existing = await feed.where('studentId', isEqualTo: studentId).get();
      if (existing.docs.isNotEmpty) {
        await subRef.set(data, SetOptions(merge: true));
        return;
      }
      final batch = _firestore.batch();
      batch.set(subRef, data, SetOptions(merge: true));
      for (var i = 0; i < ideas.length; i++) {
        final r = feed.doc();
        batch.set(r, <String, dynamic>{
          'text': ideas[i],
          'studentId': studentId,
          'lineIndex': i,
          'submittedAt': FieldValue.serverTimestamp(),
          'likeUserIds': <String>[],
          'likeCount': 0,
        });
      }
      await batch.commit();
      return;
    }

    await subRef.set(data, SetOptions(merge: true));
  }

  List<String>? _extractBrainstormIdeas(dynamic answer) {
    if (answer is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(answer);
    if (m['kind'] != 'brainstorm') {
      return null;
    }
    final raw = m['ideas'];
    if (raw is! List) {
      return <String>[];
    }
    final out = <String>[];
    for (final e in raw) {
      final t = '$e'.trim();
      if (t.isNotEmpty) {
        out.add(t);
      }
    }
    return out;
  }

  /// O‘qituvchi: haqiqiy vaqtda fikrlar oqimi (tartib: clientda `submittedAt` bo‘yicha).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchIdeaFeed(
    AssignmentRouteArgs args,
  ) {
    if (!_ready || args.assignmentId == null) {
      return const Stream.empty();
    }
    return ideaFeedCollection(args).snapshots();
  }

  /// O‘quvchi doskasi: barcha fikrlar (sinfdoshlar + o‘zi).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchIdeaFeedByLookup(
    AssignmentLookup lookup,
  ) {
    if (!_ready) {
      return const Stream.empty();
    }
    return _ideaFeedFromLookup(lookup).snapshots();
  }

  /// O‘quvchi: aynan o‘z fikrlari (baho/izoh ko‘rinishi uchun).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchIdeaFeedForStudent({
    required AssignmentLookup lookup,
    required String studentId,
  }) {
    if (!_ready || studentId.isEmpty) {
      return const Stream.empty();
    }
    return _ideaFeedFromLookup(lookup)
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  /// Ushbu o‘quvchining fikr hujjatlari soni.
  Future<int> countBrainstormIdeasForStudent({
    required AssignmentLookup lookup,
    required String studentId,
  }) async {
    if (!_ready || studentId.isEmpty) {
      return 0;
    }
    final q = await _ideaFeedFromLookup(lookup)
        .where('studentId', isEqualTo: studentId)
        .get();
    return q.docs.length;
  }

  /// Bitta fikrni real vaqtda doskaga (incremental UI).
  Future<void> addBrainstormIdeaToFeed({
    required AssignmentLookup lookup,
    required String studentId,
    required String text,
    required int lineIndex,
  }) async {
    if (!_ready) {
      return;
    }
    final t = text.trim();
    if (t.isEmpty) {
      return;
    }
    final feed = _ideaFeedFromLookup(lookup);
    await feed.add(<String, dynamic>{
      'text': t,
      'studentId': studentId,
      'lineIndex': lineIndex,
      'submittedAt': FieldValue.serverTimestamp(),
      'likeUserIds': <String>[],
      'likeCount': 0,
    });
  }

  /// Stikerga like (bitta marta: qayta bosilganda olib tashlanadi).
  Future<void> toggleIdeaLike({
    required AssignmentLookup lookup,
    required String ideaDocumentId,
    required String studentId,
  }) async {
    if (!_ready || studentId.isEmpty) {
      return;
    }
    final ref = _ideaFeedFromLookup(lookup).doc(ideaDocumentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }
      final d = snap.data()!;
      var ids = (d['likeUserIds'] as List<dynamic>?)?.map((e) => '$e').toList() ?? <String>[];
      if (ids.contains(studentId)) {
        ids = List<String>.from(ids)..remove(studentId);
      } else {
        ids = List<String>.from(ids)..add(studentId);
      }
      tx.update(ref, {
        'likeUserIds': ids,
        'likeCount': ids.length,
      });
    });
  }

  /// Nomaqbul yoki dublikat fikrni o‘chirish.
  Future<void> deleteIdeaDocument({
    required AssignmentRouteArgs args,
    required String ideaDocumentId,
  }) async {
    if (!_ready || args.assignmentId == null) {
      return;
    }
    await ideaFeedCollection(args).doc(ideaDocumentId).delete();
  }

  /// O‘qituvchi: bitta fikr (stiker) uchun 0–10 va izoh — `ideaFeed` hujjatida.
  Future<void> updateIdeaFeedTeacherFeedback({
    required AssignmentRouteArgs args,
    required String ideaDocumentId,
    required int grade10,
    String? teacherComment,
  }) async {
    if (!_ready || args.assignmentId == null) {
      return;
    }
    if (grade10 < 0 || grade10 > 10) {
      throw ArgumentError('grade10: 0 dan 10 gacha');
    }
    final ref = ideaFeedCollection(args).doc(ideaDocumentId);
    final payload = <String, dynamic>{
      'grade10': grade10,
      'gradedAt': FieldValue.serverTimestamp(),
    };
    final c = teacherComment?.trim();
    if (c != null && c.isNotEmpty) {
      payload['teacherComment'] = c;
    } else {
      payload['teacherComment'] = FieldValue.delete();
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  /// Ushbu o'quvchining shu topshirigiga yuborishini (izoh, AI) kuzatish.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSubmissionForStudent({
    required AssignmentLookup lookup,
    required String studentId,
  }) {
    if (!_ready || studentId.isEmpty) {
      return const Stream.empty();
    }
    return _submissions(
      subjectId: lookup.subjectId,
      classId: lookup.classId,
      topicId: lookup.topicId,
      methodId: lookup.methodId,
      assignmentId: lookup.assignmentId,
    ).doc(studentId).snapshots();
  }

  /// Takroran yuborilmasligi uchun.
  Future<bool> hasSubmitted({
    required AssignmentLookup lookup,
    required String studentId,
  }) async {
    if (!_ready || studentId.isEmpty) {
      return false;
    }
    final doc = await _submissions(
      subjectId: lookup.subjectId,
      classId: lookup.classId,
      topicId: lookup.topicId,
      methodId: lookup.methodId,
      assignmentId: lookup.assignmentId,
    ).doc(studentId).get();
    return doc.exists;
  }

  /// O'qituvchi: sun'iy intellekt yordamchi tahlil matni (Gemini va hokazo).
  Future<void> setSubmissionAiFeedback({
    required AssignmentRouteArgs args,
    required String studentId,
    required String aiFeedback,
  }) async {
    if (!_ready || args.assignmentId == null) return;
    await _submissions(
      subjectId: args.subjectId,
      classId: args.classId,
      topicId: args.topicId,
      methodId: args.methodId,
      assignmentId: args.assignmentId!,
    ).doc(studentId).set(
      <String, dynamic>{
        'aiFeedback': aiFeedback,
        'aiFeedbackAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// O'qituvchi: ko'rib chiqish holati va izoh (`reviewStatus`: submitted | reviewed | returned).
  /// [teacherGrade10] — 0…10 o‘quvchi fikr/javobga o‘qituvchi bahosi (Aqliy hujum va boshqalar).
  Future<void> updateSubmissionReview({
    required AssignmentRouteArgs args,
    required String studentId,
    required String reviewStatus,
    String? teacherComment,
    int? teacherGrade10,
  }) async {
    if (!_ready || args.assignmentId == null) return;
    final payload = <String, dynamic>{
      'reviewStatus': reviewStatus,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (teacherComment != null) {
      payload['teacherComment'] = teacherComment;
    }
    if (teacherGrade10 != null) {
      if (teacherGrade10 < 0 || teacherGrade10 > 10) {
        throw ArgumentError('teacherGrade10: 0 dan 10 gacha');
      }
      payload['grade10'] = teacherGrade10;
    }
    await _submissions(
      subjectId: args.subjectId,
      classId: args.classId,
      topicId: args.topicId,
      methodId: args.methodId,
      assignmentId: args.assignmentId!,
    ).doc(studentId).set(payload, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSubmissions(
    AssignmentRouteArgs args,
  ) {
    if (!_ready || args.assignmentId == null) {
      return const Stream.empty();
    }
    return _submissions(
      subjectId: args.subjectId,
      classId: args.classId,
      topicId: args.topicId,
      methodId: args.methodId,
      assignmentId: args.assignmentId!,
    ).snapshots();
  }

  /// Barcha topshiriqlarda ushbu o'quvchining yuborishlari (`studentId` maydoni).
  /// Eslatma: `collectionGroup` + `documentId()` UID bilan ishlatilmaydi — to'liq yo'l kerak.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMySubmissions(
    String studentId,
  ) {
    if (!_ready || studentId.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collectionGroup('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  /// O'quvchi: o'z yuborilgan javobini (`.../submissions/{studentId}`) o'chirish.
  Future<void> deleteMySubmission({
    required DocumentReference<Map<String, dynamic>> ref,
    required String studentId,
  }) async {
    if (!_ready || studentId.isEmpty) return;
    if (ref.id != studentId) {
      throw StateError('Ruxsat yo\'q');
    }
    final snap = await ref.get();
    final d = snap.data();
    if (d != null && d['studentId'] != null && d['studentId'] != studentId) {
      throw StateError('Ruxsat yo\'q');
    }
    await ref.delete();
  }
}
