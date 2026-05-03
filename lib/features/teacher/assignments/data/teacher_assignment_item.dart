import 'package:cloud_firestore/cloud_firestore.dart';

/// Global ro'yxat uchun — `assignments` hujjati + yo'l identifikatorlari.
class TeacherAssignmentItem {
  const TeacherAssignmentItem({
    required this.subjectId,
    required this.classId,
    required this.topicId,
    required this.methodId,
    required this.assignmentId,
    required this.code,
    required this.title,
    this.deadline,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String methodId;
  final String assignmentId;
  final String code;
  final String title;
  final DateTime? deadline;

  /// Muddati o'tmagan (yoki muddat yo'q).
  bool get isActive {
    final d = deadline;
    if (d == null) return true;
    return !d.isBefore(DateTime.now());
  }

  factory TeacherAssignmentItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final path = doc.reference.path.split('/');
    final data = doc.data();
    final ts = data['deadline'] as Timestamp?;
    return TeacherAssignmentItem(
      subjectId: path.length > 1 ? path[1] : '',
      classId: path.length > 3 ? path[3] : '',
      topicId: path.length > 5 ? path[5] : '',
      methodId: path.length > 7 ? path[7] : '',
      assignmentId: doc.id,
      code: '${data['code'] ?? ''}',
      title: '${data['title'] ?? 'Topshiriq'}',
      deadline: ts?.toDate(),
    );
  }
}
