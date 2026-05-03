import 'package:cloud_firestore/cloud_firestore.dart';

/// `collectionGroup('assignments')` so'rovi natijasi.
class AssignmentLookup {
  const AssignmentLookup({
    required this.subjectId,
    required this.classId,
    required this.topicId,
    required this.methodId,
    required this.assignmentId,
    required this.data,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String methodId;
  final String assignmentId;
  final Map<String, dynamic> data;

  /// `studentGroupTasks/.../items/{id}` — guruh orqali yuborilgan topshiriq.
  static AssignmentLookup? fromStudentGroupTask(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final sid = d['subjectId'] as String?;
    final cid = d['classId'] as String?;
    final tid = d['topicId'] as String?;
    final mid = d['methodId'] as String?;
    final aid = d['assignmentId'] as String?;
    if (sid == null ||
        cid == null ||
        tid == null ||
        mid == null ||
        aid == null ||
        sid.isEmpty ||
        aid.isEmpty) {
      return null;
    }
    return AssignmentLookup(
      subjectId: sid,
      classId: cid,
      topicId: tid,
      methodId: mid,
      assignmentId: aid,
      data: {
        'title': d['title'] ?? 'Topshiriq',
        'code': d['code'] ?? '',
      },
    );
  }

  static String? assignmentPathKeyFromSubmissionDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final segs = doc.reference.path.split('/');
    if (segs.length < 12) return null;
    return '${segs[1]}|${segs[3]}|${segs[5]}|${segs[7]}|${segs[9]}';
  }

  static String assignmentPathKeyFromGroupTaskData(Map<String, dynamic> d) {
    return '${d['subjectId']}|${d['classId']}|${d['topicId']}|${d['methodId']}|${d['assignmentId']}';
  }

  /// `.../assignments/{aid}/submissions/{studentId}` hujjati yo'lidan.
  static AssignmentLookup? fromSubmissionDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final segs = doc.reference.path.split('/');
    if (segs.length < 12) return null;
    return AssignmentLookup(
      subjectId: segs[1],
      classId: segs[3],
      topicId: segs[5],
      methodId: segs[7],
      assignmentId: segs[9],
      data: {
        'title': d['assignmentTitle'] ?? d['title'] ?? 'Topshiriq',
        'code': d['assignmentCode'] ?? d['code'],
      },
    );
  }
}