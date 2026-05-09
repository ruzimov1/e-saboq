import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'assignment_lookup.dart';
import 'teacher_assignment_item.dart';

/// O'quvchiga berilmasligi kerak bo'lgan maydonlar (kod orqali qidiruvda).
const studentHiddenAssignmentKeys = <String>[
  'teacherNotes',
  'sampleAnswerInternal',
  'teacherOnlyHint',
];

/// Firestore: `.../methods/{methodId}/assignments/{assignmentId}`
class AssignmentRepository {
  AssignmentRepository({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  bool get _ready => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    return _override ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> assignmentsCollection({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
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
        .collection('assignments');
  }

  Future<void> createAssignment({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_ready) return;
    final ref = assignmentsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    ).doc(assignmentId);
    final code = _normalizeAssignmentCode('${data['code'] ?? ''}');
    if (code.isNotEmpty) {
      final batch = _firestore.batch();
      batch.set(ref, data);
      batch.set(
        _firestore.collection('assignmentCodes').doc(code),
        <String, dynamic>{
          'subjectId': subjectId,
          'classId': classId,
          'topicId': topicId,
          'methodId': methodId,
          'assignmentId': assignmentId,
          if (data['teacherId'] != null) 'teacherId': data['teacherId'],
        },
      );
      await batch.commit();
    } else {
      await ref.set(data);
    }
  }

  /// Topshiriq, uning barcha `submissions` va mos `assignmentCodes` indeksi.
  Future<void> deleteAssignment({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
  }) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    final ref = assignmentsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    ).doc(assignmentId);
    final snap = await ref.get();
    if (!snap.exists) {
      return;
    }
    final data = snap.data() ?? {};
    final code = _normalizeAssignmentCode('${data['code'] ?? ''}');
    final subs = await ref.collection('submissions').get();
    for (final s in subs.docs) {
      await s.reference.delete();
    }
    final ideas = await ref.collection('ideaFeed').get();
    for (final s in ideas.docs) {
      await s.reference.delete();
    }
    await ref.delete();
    if (code.isNotEmpty) {
      final codeRef = _firestore.collection('assignmentCodes').doc(code);
      final cSnap = await codeRef.get();
      final cData = cSnap.data();
      if (cSnap.exists &&
          cData != null &&
          (cData['assignmentId'] as String?) == assignmentId) {
        await codeRef.delete();
      }
    }
  }

  /// Nusxalaganda oraliq bo'shliqlar yo'qoladi; katta harf.
  static String _normalizeAssignmentCode(String raw) {
    var s = raw.trim().toUpperCase();
    s = s.replaceAll(RegExp(r'[\s\u200B-\u200D\uFEFF]'), '');
    return s;
  }

  /// Avvalo `assignmentCodes` (indekssiz tezkor), keyin `collectionGroup` (eski hujjatlar).
  Future<AssignmentLookup?> findAssignmentByCode(String rawCode) async {
    if (!_ready) return null;
    final code = _normalizeAssignmentCode(rawCode);
    if (code.isEmpty) return null;

    final indexDoc =
        await _firestore.collection('assignmentCodes').doc(code).get();
    if (indexDoc.exists) {
      final p = indexDoc.data();
      if (p != null) {
        final a = p['subjectId'] as String?;
        final b = p['classId'] as String?;
        final t = p['topicId'] as String?;
        final m = p['methodId'] as String?;
        final aid = p['assignmentId'] as String?;
        if (a != null && b != null && t != null && m != null && aid != null) {
          final asg = await assignmentsCollection(
            subjectId: a,
            classId: b,
            topicId: t,
            methodId: m,
          ).doc(aid).get();
          final l = _lookupFromAssignmentDocument(asg);
          if (l != null) {
            return l;
          }
        }
      }
    }

    final snap = await _firestore
        .collectionGroup('assignments')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    return _lookupFromAssignmentDocument(snap.docs.first);
  }

  /// O'qituvchi: yashirilmagan barcha maydonlar.
  Future<Map<String, dynamic>?> getAssignmentDataRaw({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
  }) async {
    if (!_ready) {
      return null;
    }
    final doc = await assignmentsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    ).doc(assignmentId).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data();
  }

  /// Mavjud topshiriq hujjatini yangilash (maydonlar `update` orqali qo'shiladi).
  Future<void> updateAssignment({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
    required Map<String, dynamic> data,
  }) async {
    if (!_ready) {
      throw StateError('Firebase sozlanmagan');
    }
    await assignmentsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    ).doc(assignmentId).update(data);
  }

  /// Bitta topshiriq (o'quvchi: maxsus maydonlar olib tashlangan).
  Future<AssignmentLookup?> fetchAssignmentLookup({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
    required String assignmentId,
  }) async {
    if (!_ready) {
      return null;
    }
    final doc = await assignmentsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    ).doc(assignmentId).get();
    return _lookupFromAssignmentDocument(doc);
  }

  AssignmentLookup? _lookupFromAssignmentDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) {
      return null;
    }
    final d = doc.data();
    if (d == null) {
      return null;
    }
    final segments = doc.reference.path.split('/');
    if (segments.length < 10) {
      return null;
    }
    final safe = Map<String, dynamic>.from(d);
    for (final k in studentHiddenAssignmentKeys) {
      safe.remove(k);
    }
    return AssignmentLookup(
      subjectId: segments[1],
      classId: segments[3],
      topicId: segments[5],
      methodId: segments[7],
      assignmentId: segments[9],
      data: safe,
    );
  }

  /// Barcha fanlar bo'ylab o'qituvchi yaratgan topshiriqlar (`teacherId` maydoni kerak).
  /// Yangi topshiriqlar ro'yxat boshida bo'ladi (createdAt bo'yicha teskari tartib).
  Stream<List<TeacherAssignmentItem>> watchAssignmentsForTeacher(String teacherId) {
    if (!_ready || teacherId.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collectionGroup('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map(TeacherAssignmentItem.fromDoc).toList();
          items.sort((a, b) {
            final ca = a.createdAt;
            final cb = b.createdAt;
            if (ca == null && cb == null) return 0;
            if (ca == null) return 1;
            if (cb == null) return -1;
            return cb.compareTo(ca); // teskari: yangi birinchi
          });
          return items;
        });
  }

  /// Ushbu metod ostidagi barcha topshiriqlar (real vaqtda).
  /// Yangi topshiriqlar ro'yxat boshida bo'ladi (createdAt bo'yicha teskari tartib).
  Stream<List<Map<String, dynamic>>> watchAssignmentsForMethod({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
  }) {
    if (!_ready) return Stream.value([]);
    return assignmentsCollection(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
      methodId: methodId,
    ).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .toList();
      list.sort((a, b) {
        final ca = a['createdAt'];
        final cb = b['createdAt'];
        if (ca == null && cb == null) return 0;
        if (ca == null) return 1;
        if (cb == null) return -1;
        // Firestore Timestamp yoki DateTime bo'lishi mumkin
        final ta = ca is Timestamp ? ca.toDate() : (ca as DateTime);
        final tb = cb is Timestamp ? cb.toDate() : (cb as DateTime);
        return tb.compareTo(ta); // teskari: yangi birinchi
      });
      return list;
    });
  }
}
