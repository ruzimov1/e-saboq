import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'preset_assignment_template.dart';
import 'curriculum_word_constants.dart';

/// `fayllar/informatika_method_assignments.json` — Word/Excel matnini shu faylga
/// qo'ying: `{topic}` o'zgaruvchisi sarlavha va qo'shimchada ishlatiladi.
abstract final class CurriculumWordAssignments {
  static Map<String, List<_RawTemplate>>? _informatika;

  static bool get isLoaded => _informatika != null;

  static Future<void> loadFromAssets() async {
    Object? lastError;
    for (final path in CurriculumWordConstants.methodAssetPathVariants(
      CurriculumWordConstants.informatikaAssignmentsAssetPath,
    )) {
      try {
        final s = await rootBundle.loadString(path);
        _parseInformatika(s);
        return;
      } catch (e) {
        lastError = e;
      }
    }
    _informatika = null;
    if (kDebugMode) {
      debugPrint('CurriculumWordAssignments: yuklanmadi — $lastError');
    }
  }

  @visibleForTesting
  static void loadFromString(String json) => _parseInformatika(json);

  static void _parseInformatika(String s) {
    final map = jsonDecode(s) as Map<String, dynamic>;
    final inf = map['informatika'] as Map<String, dynamic>?;
    if (inf == null) {
      _informatika = null;
      return;
    }
    _informatika = inf.map(
      (methodId, raw) {
        final list = (raw as List<dynamic>)
            .map(
              (e) => _RawTemplate.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        return MapEntry(methodId, list);
      },
    );
  }

  static List<PresetAssignmentTemplate> informatikaFor(
    String methodId,
    String topic,
  ) {
    final list = _informatika?[methodId];
    if (list == null || list.isEmpty) {
      return const [];
    }
    return list
        .map(
          (r) => PresetAssignmentTemplate(
            id: r.id,
            title: r.applyTopic(r.title, topic),
            subtitle: r.subtitle == null || r.subtitle!.isEmpty
                ? null
                : r.applyTopic(r.subtitle!, topic),
          ),
        )
        .toList();
  }
}

class _RawTemplate {
  const _RawTemplate({required this.id, required this.title, this.subtitle});

  final String id;
  final String title;
  final String? subtitle;

  String applyTopic(String s, String topic) {
    return s.replaceAll(CurriculumWordConstants.topicToken, topic);
  }

  factory _RawTemplate.fromJson(Map<String, dynamic> m) {
    return _RawTemplate(
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}',
      subtitle: m['subtitle'] as String?,
    );
  }
}
