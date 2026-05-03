import '../curriculum/informatika_json_presets.dart';
import 'case_study_cyber_models.dart';

/// Case-study vaziyatini topshirig‘ / metod / JSON bankidan aniqlash.
abstract final class CaseStudyBank {
  static CaseCyberTask? resolveTask({
    required String classId,
    required String topicLabel,
    required Map<String, dynamic> assignmentData,
    required Map<String, dynamic>? methodConfig,
    required int seed,
  }) {
    final emb = _embedded(assignmentData);
    if (emb != null) {
      final cyber = emb['caseCyber'];
      if (cyber is Map) {
        return CaseCyberTask.fromStructuredJson(Map<String, dynamic>.from(cyber));
      }
      final scenario = '${emb['scenario'] ?? ''}'.trim();
      if (scenario.isNotEmpty) {
        return CaseCyberTask.fromLegacyScenario(scenario);
      }
    }

    final ms =
        '${methodConfig?['scenario'] ?? methodConfig?['caseScenario'] ?? ''}'.trim();
    if (ms.isNotEmpty) {
      return CaseCyberTask.fromLegacyScenario(ms);
    }

    final entry = InformatikaJsonPresets.caseStudyTopicEntryForClass(
      classId: classId,
      topicLabel: topicLabel,
    );
    if (entry == null) {
      return null;
    }
    return pickTaskFromEntry(entry, seed);
  }

  static Map<String, dynamic>? _embedded(Map<String, dynamic> assignmentData) {
    final e = assignmentData['embeddedMethodConfig'];
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return Map<String, dynamic>.from(e);
    return null;
  }

  /// `topics[].tasks` ro‘yxatidan: strukturalangan obyekt yoki qator.
  static CaseCyberTask? pickTaskFromEntry(Map<String, dynamic> entry, int seed) {
    final raw = entry['tasks'];
    if (raw is! List || raw.isEmpty) return null;

    final structured = <Map<String, dynamic>>[];
    final plain = <String>[];
    for (final t in raw) {
      if (t is Map) {
        structured.add(Map<String, dynamic>.from(t));
      } else {
        final s = '$t'.trim();
        if (s.isNotEmpty) plain.add(s);
      }
    }

    final rnd = seed.abs();
    if (structured.isNotEmpty) {
      final i = rnd % structured.length;
      final m = structured[i];
      return CaseCyberTask.fromStructuredJson(m);
    }
    if (plain.isNotEmpty) {
      final i = rnd % plain.length;
      return CaseCyberTask.fromLegacyScenario(plain[i]);
    }
    return null;
  }
}
