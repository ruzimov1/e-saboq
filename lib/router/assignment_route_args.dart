import '../core/curriculum/preset_assignment_template.dart';

/// Tayyor JSON savollar banki (faqat marshrut `extra`).
class BrainstormQuestionBankRouteArgs {
  const BrainstormQuestionBankRouteArgs({
    required this.subjectId,
    required this.classId,
    required this.topicId,
    required this.methodId,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String methodId;
}

/// Aqliy hujum: shablon + qator indeksi (JSON slot yoki ro‘yxatdagi o‘rin).
class CreateBrainstormTaskRouteArgs {
  const CreateBrainstormTaskRouteArgs({
    required this.subjectId,
    required this.classId,
    required this.topicId,
    required this.methodId,
    required this.template,
    required this.listIndex0,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String methodId;
  final PresetAssignmentTemplate template;
  final int listIndex0;
}

/// Topshiriq yaratish / natijalar uchun marshrut `extra`.
class AssignmentRouteArgs {
  const AssignmentRouteArgs({
    required this.subjectId,
    required this.classId,
    required this.topicId,
    required this.methodId,
    this.assignmentId,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String methodId;
  final String? assignmentId;
}
