/// Word/JSON dan yuklangan yoki koddagi bir bosishda yaratiladigan shablon.
class PresetAssignmentTemplate {
  const PresetAssignmentTemplate({
    required this.id,
    required this.title,
    this.subtitle,
    this.assignmentDataExtras,
  });

  final String id;
  final String title;

  /// Qisqa tavsif; Aqliy hujumda — JSON `questions`dan bitta qator (bitta topshiriq savoli).
  final String? subtitle;

  /// [AssignmentRepository.createAssignment] `data` qismiga qo‘shiladi (masalan
  /// `embeddedMethodConfig` — o‘quvchi ekranida metod matni va quiz savollari).
  final Map<String, dynamic>? assignmentDataExtras;
}
