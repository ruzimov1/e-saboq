import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../curriculum/curriculum_presets.dart';
import '../curriculum/informatika_json_presets.dart';
import '../utils/code_generator.dart';
import 'brainstorm_session_config.dart';

/// `MethodAssignmentsScreen` / yaratish formasi: Firestore `data` + `assignmentId`.
class BuiltBrainstormAssignment {
  const BuiltBrainstormAssignment({
    required this.assignmentId,
    required this.data,
  });

  final String assignmentId;
  final Map<String, dynamic> data;
}

/// `method_assignments_screen` dagi bir bosishli yaratish bilan bir xil, qo‘shimcha
/// o‘qituvchi sozlamalari (`mainConcept`, `brainstormSession`).
BuiltBrainstormAssignment buildBrainstormAssignmentData({
  required String teacherId,
  required String subjectId,
  required String classId,
  required String topicId,
  required String methodId,
  required PresetAssignmentTemplate template,
  required int listIndex0,
  required String rowTitle,
  required String mainConcept,
  required BrainstormSessionConfig session,
  /// `false` bo‘lsa, faqat [mainConcept] / [template] asosida joylashtiriladi
  /// (tayyor savollar bazasidan matn, JSON sloti ustidan yozilmaydi).
  bool applyInformatikaJsonSlot = true,
}) {
  final id = const Uuid().v4();
  final code = generateAssignmentCode();
  final concept = mainConcept.trim();
  final data = <String, dynamic>{
    'code': code,
    'title': rowTitle.trim().isNotEmpty
        ? rowTitle.trim()
        : template.title,
    'deadline': Timestamp.fromDate(
      DateTime.now().add(const Duration(days: 7)),
    ),
    'createdAt': FieldValue.serverTimestamp(),
    'fromPreset': true,
    'presetTemplateId': template.id,
    'teacherId': teacherId,
    'brainstormSession': session.toFirestoreMap(),
    if (template.assignmentDataExtras != null) ...template.assignmentDataExtras!,
  };

  if (subjectId == 'informatika' &&
      methodId == CurriculumPresets.brainstormId &&
      applyInformatikaJsonSlot) {
    final bySlot = InformatikaJsonPresets.brainstormAssignmentExtrasBySlot(
      classId: classId,
      topicLabel: CurriculumPresets.topicLabel(
        subjectId,
        classId,
        topicId,
      ),
      slotIndex0: listIndex0,
    );
    if (bySlot != null) {
      for (final e in bySlot.entries) {
        data[e.key] = e.value;
      }
    }
    final emb = data['embeddedMethodConfig'];
    final prompt = emb is Map
        ? (emb['prompt'] as String? ?? '').trim()
        : '';
    if (prompt.isEmpty) {
      final sub = template.subtitle?.trim();
      if (sub != null && sub.isNotEmpty) {
        final extra = InformatikaJsonPresets.brainstormAssignmentExtrasFromPlainQuestion(
          assignmentConfigTitle: template.title,
          questionText: sub,
        );
        for (final e in extra.entries) {
          data[e.key] = e.value;
        }
      }
    }
  } else if (data['embeddedMethodConfig'] == null) {
    data['embeddedMethodConfig'] = {
      'title': template.title,
      'prompt': concept.isNotEmpty
          ? concept
          : (template.subtitle?.trim() ?? template.title),
      'brainstormGuide': _kDefaultGuide,
    };
  }

  if (data['embeddedMethodConfig'] is Map) {
    final emb = Map<String, dynamic>.from(
      data['embeddedMethodConfig'] as Map,
    );
    if (concept.isNotEmpty) {
      emb['prompt'] = concept;
    }
    final t = emb['title'] as String? ?? '';
    if (t.trim().isEmpty) {
      emb['title'] = data['title'] as String? ?? template.title;
    }
    if (emb['brainstormGuide'] == null) {
      emb['brainstormGuide'] = _kDefaultGuide;
    }
    emb['preset'] = true;
    data['embeddedMethodConfig'] = emb;
  }
  return BuiltBrainstormAssignment(assignmentId: id, data: data);
}

const String _kDefaultGuide = 'G\'oyalarni erkin yozing, har bir qator bitta fikr. '
    'Talaqqosiz fikr yuriting; tanqidni keyinga qoldiring.';
