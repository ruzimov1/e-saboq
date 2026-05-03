import 'package:cloud_firestore/cloud_firestore.dart';

/// O‘qituvchi dashboard: case-study yuborishlarini client-side tahlil.
abstract final class CaseStudyDashboardAnalytics {
  static List<Map<String, dynamic>> probesFromSubmissionData(Map<String, dynamic>? d) {
    if (d == null) return const [];
    final answer = d['answer'];
    if (answer is! Map) return const [];
    final m = Map<String, dynamic>.from(answer);
    if ((m['kind'] as String? ?? '') != 'case') return const [];
    final raw = m['caseProbes'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static int probeCount(Map<String, dynamic>? d) => probesFromSubmissionData(d).length;

  /// So‘nggi taassurof tanlovi noto‘g‘ri bo‘lsa (o‘quvchi mantiqiy xato yo‘lda).
  static bool lastProbeIncorrect(Map<String, dynamic>? d) {
    final p = probesFromSubmissionData(d);
    if (p.isEmpty) return false;
    return p.last['correct'] == false;
  }

  /// Barcha tanlovlar to‘g‘ri (taassurof bo‘lgan topshiriq uchun).
  static bool allProbesCorrect(Map<String, dynamic>? d) {
    final p = probesFromSubmissionData(d);
    if (p.isEmpty) return false;
    for (final x in p) {
      if (x['correct'] == false) return false;
    }
    return true;
  }

  /// `label` → necha marta tanlangan (heatmap).
  static Map<String, int> heatmapFromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, int>{};
    for (final doc in docs) {
      for (final p in probesFromSubmissionData(doc.data())) {
        final label = '${p['label'] ?? ''}'.trim();
        if (label.isEmpty) continue;
        map[label] = (map[label] ?? 0) + 1;
      }
    }
    return map;
  }

  static double percentAllCorrect(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var total = 0;
    var ok = 0;
    for (final doc in docs) {
      final d = doc.data();
      if (probesFromSubmissionData(d).isEmpty) continue;
      total++;
      if (allProbesCorrect(d)) ok++;
    }
    if (total == 0) return 0;
    return ok / total;
  }

  static int deadEndCount(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var n = 0;
    for (final doc in docs) {
      if (lastProbeIncorrect(doc.data())) n++;
    }
    return n;
  }
}

/// JSON `tasks` ro‘yxatini tahrir / reorder uchun tekis matnlar.
List<String> caseStudyTaskLinesForEditor(Map<String, dynamic> entry) {
  final tasks = entry['tasks'];
  if (tasks is! List) return [];
  final out = <String>[];
  for (final raw in tasks) {
    if (raw is String) {
      final s = raw.trim();
      if (s.isNotEmpty) out.add(s);
    } else if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final alert = '${m['alert'] ?? ''}'.trim();
      final scen = '${m['scenario'] ?? ''}'.trim();
      if (alert.isNotEmpty && scen.isNotEmpty) {
        out.add('$alert — $scen');
      } else if (scen.isNotEmpty) {
        out.add(scen);
      }
      final opts = m['options'];
      if (opts is List) {
        for (final o in opts) {
          if (o is Map) {
            final lab = '${o['label'] ?? ''}'.trim();
            if (lab.isNotEmpty) out.add('  · $lab');
          }
        }
      }
    }
  }
  return out;
}

/// Birinchi «kiber» blokning `scenario` matni (bo‘lmasa `null`).
String? caseStudyFirstInteractiveScenario(Map<String, dynamic> entry) {
  final tasks = entry['tasks'];
  if (tasks is! List) return null;
  for (final raw in tasks) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final scen = '${m['scenario'] ?? ''}'.trim();
      if (scen.isNotEmpty) return scen;
    }
  }
  return null;
}
