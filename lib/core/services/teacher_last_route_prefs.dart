import 'package:shared_preferences/shared_preferences.dart';

import '../curriculum/curriculum_catalog.dart';

/// O'qituvchi oxirgi ochilgan joy: sinf bo'yicha fan → mavzular → metodlar.
enum TeacherLastDepth { subjects, topics, methods }

class TeacherLastRoute {
  const TeacherLastRoute({
    this.classId,
    this.subjectId,
    this.topicId,
    required this.depth,
  });

  final String? classId;
  final String? subjectId;
  final String? topicId;
  final TeacherLastDepth depth;

  String get label {
    switch (depth) {
      case TeacherLastDepth.subjects:
        return 'Fanlar';
      case TeacherLastDepth.topics:
        return 'Mavzular';
      case TeacherLastDepth.methods:
        return 'Metodlar';
    }
  }

  /// Masalan: "9-sinf · Informatika · Metodlar" (katalog mavzusi nomi bo‘lsa).
  String contextSummaryLine() {
    final parts = <String>[];
    if (classId != null && classId!.trim().isNotEmpty) {
      parts.add(CurriculumCatalog.gradeContextLabel(classId!));
    }
    if (subjectId != null && subjectId!.trim().isNotEmpty) {
      parts.add(
        CurriculumCatalog.catalogSubjectName(subjectId!) ?? subjectId!.trim(),
      );
    }
    if (depth == TeacherLastDepth.methods &&
        topicId != null &&
        topicId!.trim().isNotEmpty &&
        subjectId != null &&
        classId != null) {
      for (final t
          in CurriculumCatalog.topicsFor(subjectId!.trim(), classId!.trim())) {
        if (t.id == topicId) {
          parts.add(t.name);
          break;
        }
      }
    }
    if (parts.isEmpty) return label;
    return '${parts.join(' · ')} — $label';
  }
}

abstract final class TeacherLastRoutePrefs {
  static const _kSubject = 'teacher_last_subject_id';
  static const _kClass = 'teacher_last_class_id';
  static const _kTopic = 'teacher_last_topic_id';
  static const _kDepth = 'teacher_last_depth';

  static Future<void> save({
    String? classId,
    String? subjectId,
    String? topicId,
    required TeacherLastDepth depth,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDepth, depth.name);
    if (classId != null && classId.isNotEmpty) {
      await p.setString(_kClass, classId);
    } else {
      await p.remove(_kClass);
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      await p.setString(_kSubject, subjectId);
    } else {
      await p.remove(_kSubject);
    }
    if (topicId != null && topicId.isNotEmpty) {
      await p.setString(_kTopic, topicId);
    } else {
      await p.remove(_kTopic);
    }
  }

  static Future<TeacherLastRoute?> read() async {
    final p = await SharedPreferences.getInstance();
    final depth = _parseDepth(p.getString(_kDepth));
    if (depth == null) return null;
    final cid = p.getString(_kClass);
    final sid = p.getString(_kSubject);
    final tid = p.getString(_kTopic);
    switch (depth) {
      case TeacherLastDepth.subjects:
        if (cid == null || cid.isEmpty) return null;
        return TeacherLastRoute(
          classId: cid,
          subjectId: null,
          topicId: null,
          depth: depth,
        );
      case TeacherLastDepth.topics:
        if (cid == null || sid == null) return null;
        if (cid.isEmpty || sid.isEmpty) return null;
        return TeacherLastRoute(
          classId: cid,
          subjectId: sid,
          topicId: null,
          depth: depth,
        );
      case TeacherLastDepth.methods:
        if (cid == null || sid == null || tid == null) return null;
        if (cid.isEmpty || sid.isEmpty || tid.isEmpty) return null;
        return TeacherLastRoute(
          classId: cid,
          subjectId: sid,
          topicId: tid,
          depth: depth,
        );
    }
  }

  static TeacherLastDepth? _parseDepth(String? name) {
    if (name == null) return null;
    if (name == 'classes') {
      return null;
    }
    for (final d in TeacherLastDepth.values) {
      if (d.name == name) {
        return d;
      }
    }
    return null;
  }
}
