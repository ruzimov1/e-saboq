import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/teacher/assignments/data/assignment_lookup.dart';

/// O'quvchi topshirig'i qoralamasi (tarmoq uzilganda ham saqlanadi).
abstract final class AssignmentDraftStore {
  static String _key(AssignmentLookup l, String studentId) =>
      'es_draft_v1_${l.subjectId}_${l.classId}_${l.topicId}_${l.methodId}_${l.assignmentId}_$studentId';

  static Future<void> save(
    AssignmentLookup l,
    String studentId,
    Map<String, dynamic> payload,
  ) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(l, studentId), jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> load(
    AssignmentLookup l,
    String studentId,
  ) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(l, studentId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final o = jsonDecode(raw);
      if (o is Map<String, dynamic>) return o;
      if (o is Map) return Map<String, dynamic>.from(o);
    } catch (_) {}
    return null;
  }

  static Future<void> clear(AssignmentLookup l, String studentId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(l, studentId));
  }
}
