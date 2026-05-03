import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'brainstorm_topic_model.dart';
import 'curriculum_catalog.dart';
import 'preset_assignment_template.dart';

abstract final class InformatikaJsonPresets {
  static final Map<String, String> _fileByLogicalKey = {
    'quiz_5': 'fayllar/quizz/5_sinf_quiz.json',
    'quiz_6': 'fayllar/quizz/6_sinf_quiz.json',
    'quiz_7': 'fayllar/quizz/7_sinf_quiz.json',
    'quiz_8': 'fayllar/quizz/8_sinf_quiz.json',
    'quiz_9': 'fayllar/quizz/9_sinf_mukammal_quiz.json',
    'quiz_10_11': 'fayllar/quizz/10_11_sinf_quiz.json',
    'bs_5': 'fayllar/aqliy-hujum/5_sinf_brainstorming.json',
    'bs_6': 'fayllar/aqliy-hujum/6_sinf_brainstorming.json',
    'bs_7': 'fayllar/aqliy-hujum/7_sinf_brainstorming.json',
    'bs_8': 'fayllar/aqliy-hujum/8_sinf_brainstorming.json',
    'bs_9': 'fayllar/aqliy-hujum/9_sinf_brainstorming_full.json',
    'bs_10_11': 'fayllar/aqliy-hujum/10_11_sinf_brainstorming.json',
    'cs_5': 'fayllar/case-study/5_sinf_case_study.json',
    'cs_6': 'fayllar/case-study/6_sinf_case_study.json',
    'cs_7': 'fayllar/case-study/7_sinf_case_study.json',
    'cs_8': 'fayllar/case-study/8_sinf_case_study.json',
    'cs_9': 'fayllar/case-study/9_sinf_case_study.json',
    'cs_10_11': 'fayllar/case-study/10_11_sinf_case_study.json',
    'cl_5': 'fayllar/claster/5_sinf_cluster_fixed.json',
    'cl_6': 'fayllar/claster/6_sinf_cluster.json',
    'cl_7': 'fayllar/claster/7_sinf_cluster.json',
    'cl_8': 'fayllar/claster/8_sinf_cluster.json',
    'cl_9': 'fayllar/claster/9_sinf_cluster.json',
    'cl_10_11': 'fayllar/claster/10_11_sinf_cluster.json',
    'ts_5': 'fayllar/t-sxema/5_sinf_t_schema.json',
    'ts_6': 'fayllar/t-sxema/6_sinf_t_schema.json',
    'ts_7': 'fayllar/t-sxema/7_sinf_t_schema.json',
    'ts_8': 'fayllar/t-sxema/8_sinf_t_schema.json',
    'ts_9': 'fayllar/t-sxema/9_sinf_t_schema_full.json',
    'ts_10_11': 'fayllar/t-sxema/10_11_sinf_t_schema_full.json',
  };

  static final Map<String, Map<String, dynamic>> _rawByLogicalKey =
      <String, Map<String, dynamic>>{};
  static bool _ready = false;

  static String _classFileKey(String classId) {
    final d = RegExp(r'\d+').firstMatch(classId)?.group(0);
    if (d == '10' || d == '11') return '10_11';
    return d ?? classId.trim();
  }

  static const List<MapEntry<String, String>> _brainstormFallbackAssets = [
    MapEntry('bs_5', 'fayllar/aqliy-hujum/5_sinf_brainstorming.json'),
    MapEntry('bs_6', 'fayllar/aqliy-hujum/6_sinf_brainstorming.json'),
    MapEntry('bs_7', 'fayllar/aqliy-hujum/7_sinf_brainstorming.json'),
    MapEntry('bs_8', 'fayllar/aqliy-hujum/8_sinf_brainstorming.json'),
    MapEntry('bs_9', 'fayllar/aqliy-hujum/9_sinf_brainstorming_full.json'),
    MapEntry('bs_10_11', 'fayllar/aqliy-hujum/10_11_sinf_brainstorming.json'),
  ];

  static Future<void> loadFromAssets() async {
    _rawByLogicalKey.clear();
    _ready = false;

    for (final e in _fileByLogicalKey.entries) {
      try {
        final s = await rootBundle.loadString(e.value);
        final m = jsonDecode(s);
        if (m is Map<String, dynamic>) {
          _rawByLogicalKey[e.key] = m;
        }
      } catch (err, st) {
        if (kDebugMode) {
          debugPrint('InformatikaJsonPresets: ${e.key} yuklanmadi (${e.value})');
          debugPrint('$err');
          debugPrint('$st');
        }
      }
    }

    for (final e in _brainstormFallbackAssets) {
      if (_rawByLogicalKey.containsKey(e.key)) {
        continue;
      }
      try {
        final s = await rootBundle.loadString(e.value);
        final m = jsonDecode(s);
        if (m is Map<String, dynamic>) {
          _rawByLogicalKey[e.key] = m;
        }
      } catch (err, st) {
        if (kDebugMode) {
          debugPrint('InformatikaJsonPresets: ${e.key} fallback yuklanmadi (${e.value})');
          debugPrint('$err');
          debugPrint('$st');
        }
      }
    }

    _ready = _rawByLogicalKey.isNotEmpty;
  }

  static bool get isReady => _ready;

  /// `fayllar/claster/*` — barcha mavzu qatorlari: `topics`, `mavzular_klasteri`, `informatika_klaster_shablon`.
  static List<Map<String, dynamic>> clusterFileTopicRowsForClass(String classId) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['cl_$classKey'];
    if (raw == null) return const [];
    return _clusterTopicEntriesList(raw);
  }

  /// `umumiy_markaziy_goya` (yoki `umumiy_goya`) matni, bo‘lmasa `null`.
  static String? clusterFileUmbrellaGoya(String classId) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['cl_$classKey'];
    if (raw == null) return null;
    final u = '${raw['umumiy_markaziy_goya'] ?? raw['umumiy_goya'] ?? ''}'.trim();
    return u.isEmpty ? null : u;
  }

  /// T-sxema JSON (`fayllar/t-sxema/*`, `ts_*`): mavzular nomlari.
  static List<String> tSchemaTopicNamesForClass(String classId) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['ts_$classKey'];
    if (raw == null) return const [];
    final topics = raw['topics'];
    if (topics is! List) return const [];
    final out = <String>[];
    for (final t in topics) {
      if (t is Map<String, dynamic>) {
        final n = _topicNameFromEntry(t);
        if (n.isNotEmpty) out.add(n);
      } else if (t is Map) {
        final n = _topicNameFromEntry(Map<String, dynamic>.from(t));
        if (n.isNotEmpty) out.add(n);
      }
    }
    return out;
  }

  /// Katalog mavzusiga eng mos `topics[]` elementi (`topic`, `left`, `right`, …).
  static Map<String, dynamic>? tSchemaTopicEntryForClass({
    required String classId,
    required String topicLabel,
  }) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['ts_$classKey'];
    if (raw == null) return null;
    return _findTopicEntry(raw, baseTopicName(topicLabel));
  }

  /// `fayllar/case-study/*` bo‘yicha katalog mavzusiga mos band.
  static Map<String, dynamic>? caseStudyTopicEntryForClass({
    required String classId,
    required String topicLabel,
  }) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['cs_$classKey'];
    if (raw == null) return null;
    return _findTopicEntry(raw, baseTopicName(topicLabel));
  }

  /// Barcha sinf JSON-laridagi muammoli vaziyat mavzulari (dashboard qidiruvi).
  static List<CaseStudyCatalogRow> caseStudyCatalogRows() {
    const keys = ['5', '6', '7', '8', '9', '10_11'];
    final out = <CaseStudyCatalogRow>[];
    if (!_ready) return out;
    for (final key in keys) {
      final raw = _rawByLogicalKey['cs_$key'];
      if (raw == null) continue;
      final gradeLabel = key == '10_11' ? '10–11 sinf' : '$key-sinf';
      for (final e in _topicEntries(raw)) {
        final t = _topicNameFromEntry(e);
        if (t.isEmpty) continue;
        out.add(
          CaseStudyCatalogRow(
            classKey: key,
            gradeLabel: gradeLabel,
            topicName: t,
            topicEntry: e,
          ),
        );
      }
    }
    return out;
  }

  /// Klaster tahriri: `fayllar/claster/*` bo‘yicha.
  ///
  /// - Yangi format (5-sinf shablon): `markaziy_goya` + `kalit_sozlar` + `mavzu_nomi`.
  /// - Eski format: har bir `center`/`topic` boshqa mavzularning qisqa nomi sifatida.
  ///
  /// Mavjud bo‘lmasa `null`.
  static Map<String, dynamic>? clusterEditorDefaultsForTopic({
    required String classId,
    required String topicLabel,
  }) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['cl_$classKey'];
    if (raw == null) return null;
    final entries = _clusterTopicEntriesList(raw);
    if (entries.isEmpty) return null;
    final catalogBase = baseTopicName(topicLabel);
    final main = _findTopicEntryInList(entries, catalogBase);
    if (main == null) return null;
    final keywords = _extractTextList(main['kalit_sozlar']);
    if (keywords.isNotEmpty) {
      var center = '${main['markaziy_goya'] ?? ''}'.trim();
      if (center.isEmpty) {
        center = _topicNameFromEntry(main);
      }
      if (center.isEmpty) return null;
      final topicTitle = '${main['mavzu_nomi'] ?? _topicNameFromEntry(main)}'.trim();
      final umbrella = '${raw['umumiy_markaziy_goya'] ?? raw['umumiy_goya'] ?? ''}'
          .trim();
      return {
        'center': center,
        'branchLabels': keywords,
        if (topicTitle.isNotEmpty) 'mavzu_nomi': topicTitle,
        if (umbrella.isNotEmpty) 'umumiy_markaziy_goya': umbrella,
      };
    }
    final center = _topicNameFromEntry(main);
    if (center.isEmpty) return null;
    final centerKey = _normTopicForMatch(center);
    final branchLabels = <String>[];
    for (final e in entries) {
      final n = _topicNameFromEntry(e);
      if (n.isEmpty) continue;
      if (_normTopicForMatch(n) == centerKey) continue;
      branchLabels.add(n);
    }
    return {
      'center': center,
      'branchLabels': branchLabels,
    };
  }

  /// Tayyor savollar bazasi: barcha mavzular (sinf fayli `bs_*` bo‘yicha).
  static List<BrainstormTopicModel> brainstormTopicBankForClass(String classId) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['bs_$classKey'];
    if (raw == null) {
      return const [];
    }
    final entries = _topicEntries(raw);
    final out = <BrainstormTopicModel>[];
    for (var i = 0; i < entries.length; i++) {
      final name = _topicNameFromEntry(entries[i]);
      final qs = _extractTextList(entries[i]['questions']);
      if (name.isEmpty || qs.isEmpty) {
        continue;
      }
      out.add(BrainstormTopicModel(index: i, name: name, questions: qs));
    }
    return out;
  }

  /// Hozirgi darsdagi bitta mavzuga (katalog) mos JSON bo‘limi: faqat o‘sha savollar.
  static List<BrainstormTopicModel> brainstormTopicBankForSelectedTopic({
    required String classId,
    required String topicLabel,
  }) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['bs_$classKey'];
    if (raw == null) {
      return const [];
    }
    final catalogBase = baseTopicName(topicLabel);
    final match = _findBrainstormMatch(
      raw,
      classKey: classKey,
      classId: classId,
      catalogBase: catalogBase,
    );
    if (match == null) {
      return const [];
    }
    return <BrainstormTopicModel>[
      BrainstormTopicModel(
        index: match.topicIndex,
        name: match.name,
        questions: match.lines,
      ),
    ];
  }

  static String baseTopicName(String topic) {
    var s = topic.trim();
    s = s.replaceFirst(RegExp(r'^\d+\s*-\s*sinf\s*:\s*', caseSensitive: false), '');
    s = s.replaceFirst(RegExp(r'^\d+\s*sinf\s*:\s*', caseSensitive: false), '');
    s = s.replaceFirst(RegExp(r'^\d+\s*-\s*sinf\s*-\s*', caseSensitive: false), '');
    return s.trim();
  }

  static List<Map<String, dynamic>> quizBankQuestionsForTopic({
    required String classId,
    required String topicLabel,
  }) {
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['quiz_$classKey'];
    if (raw == null) return const [];
    final catalogBase = baseTopicName(topicLabel);
    final entry = _findTopicEntry(raw, catalogBase);
    if (entry == null) return const [];
    return _convertQuizQuestions(entry['questions']);
  }

  /// O‘qituvchi kiritgan yagona savolni `questions[]` elementi shakliga keltiradi.
  static Map<String, dynamic>? normalizeQuizQuestionMap(Map<String, dynamic> q) {
    final list = _convertQuizQuestions([q]);
    if (list.isEmpty) return null;
    return list.first;
  }

  static List<PresetAssignmentTemplate> templatesFor({
    required String methodId,
    required String classId,
    required String topicLabel,
  }) {
    final classKey = _classFileKey(classId);
    final catalogBase = baseTopicName(topicLabel);
    return switch (methodId) {
      'preset_quiz' => _quizTemplates(
          _rawByLogicalKey['quiz_$classKey'],
          classKey,
          classId,
          catalogBase,
        ),
      'preset_brainstorm' => _brainstormTemplates(
          _rawByLogicalKey['bs_$classKey'],
          classKey,
          classId,
          catalogBase,
        ),
      'preset_case' => _caseTemplates(
          _rawByLogicalKey['cs_$classKey'],
          classKey,
          classId,
          catalogBase,
        ),
      'preset_group' => _clusterTemplates(
          _rawByLogicalKey['cl_$classKey'],
          classKey,
          classId,
          catalogBase,
        ),
      'preset_fishbone' => _tSchemaTemplates(
          _rawByLogicalKey['ts_$classKey'],
          classKey,
          classId,
          catalogBase,
        ),
      _ => const [],
    };
  }

  static bool _matchTopic(String a, String b) {
    final na = _normTopicForMatch(a);
    final nb = _normTopicForMatch(b);
    return na.isNotEmpty && na == nb;
  }

  /// Klaster input va JSON etalonini solishtirish.
  static String normForClusterCompare(String s) => _norm(s);

  static String _norm(String s) {
    var v = s.toLowerCase();
    v = v
        .replaceAll('’', '\'')
        .replaceAll('‘', '\'')
        .replaceAll('`', '\'')
        .replaceAll('ʻ', '\'')
        .replaceAll('ʼ', '\'');
    v = v.replaceAll(RegExp(r'[^a-z0-9\u0400-\u04FF\s]'), ' ');
    v = v.replaceAll(RegExp(r'\s+'), ' ').trim();
    return v;
  }

  static String _normTopicForMatch(String s) {
    var v = _norm(baseTopicName(s));
    v = v.replaceAll(RegExp(r'\b(sinf|mavzu|bob|bolim|bo lim)\b'), ' ');
    v = v.replaceAll(RegExp(r'\s+'), ' ').trim();
    return v;
  }

  static bool _matchTopicLoose(String a, String b) {
    if (_matchTopic(a, b)) return true;
    final na = _normTopicForMatch(a);
    final nb = _normTopicForMatch(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na.contains(nb) || nb.contains(na)) return true;
    return _wordOverlapScore(na, nb) >= 0.55;
  }

  static double _wordOverlapScore(String a, String b) {
    final sa = a.split(' ').where((e) => e.trim().length > 1).toSet();
    final sb = b.split(' ').where((e) => e.trim().length > 1).toSet();
    if (sa.isEmpty || sb.isEmpty) return 0;
    final inter = sa.intersection(sb).length.toDouble();
    final denom = sa.length > sb.length ? sa.length.toDouble() : sb.length.toDouble();
    return denom <= 0 ? 0 : inter / denom;
  }

  static List<Map<String, dynamic>> _convertQuizQuestions(dynamic rawQuestions) {
    if (rawQuestions is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final q in rawQuestions) {
      if (q is! Map) continue;
      final question = '${q['question'] ?? ''}'.trim();
      if (question.isEmpty) continue;

      final opts = <String>[];
      final rawOptions = q['options'];
      if (rawOptions is List) {
        opts.addAll(rawOptions.map((e) => '$e'));
      } else if (rawOptions is Map) {
        final pairs = <MapEntry<String, String>>[];
        rawOptions.forEach((k, v) => pairs.add(MapEntry('$k', '$v')));
        pairs.sort((a, b) => a.key.compareTo(b.key));
        opts.addAll(pairs.map((e) => e.value));
      }
      if (opts.isEmpty) continue;

      var correctIndex = 0;
      final ci = q['correctIndex'];
      if (ci is num) {
        correctIndex = ci.toInt();
      } else {
        final c = '${q['correct'] ?? ''}'.trim().toUpperCase();
        if (c.isNotEmpty && c.length == 1) {
          final code = c.codeUnitAt(0);
          if (code >= 65 && code <= 90) {
            correctIndex = code - 65;
          }
        }
      }
      if (correctIndex < 0 || correctIndex >= opts.length) {
        correctIndex = 0;
      }

      out.add({
        'question': question,
        'options': opts,
        'correctIndex': correctIndex,
      });
    }
    return out;
  }

  static Map<String, dynamic> _wrapEmbedded(Map<String, dynamic> embeddedMethodConfig) {
    return {
      'fromInfJsonPreset': true,
      'embeddedMethodConfig': embeddedMethodConfig,
    };
  }

  static const String _kBrainstormGuide =
      'G\'oyalarni erkin yozing, tanqidni keyinga qoldiring, keyin asosiy '
      'fikrlarni guruhlab bitta xulosaga keling.';

  static Map<String, dynamic> _brainstormEmbeddedForQuestion({
    required String assignmentConfigTitle,
    required String questionText,
  }) {
    return {
      'title': assignmentConfigTitle,
      'prompt': questionText.trim(),
      'brainstormGuide': _kBrainstormGuide,
      'preset': true,
    };
  }

  static String? brainstormJsonQuestionAt({
    required String classId,
    required String topicLabel,
    required int slotIndex0,
  }) {
    if (slotIndex0 < 0) return null;
    final classKey = _classFileKey(classId);
    final raw = _rawByLogicalKey['bs_$classKey'];
    if (raw == null) return null;
    final match = _findBrainstormMatch(
      raw,
      classKey: classKey,
      classId: classId,
      catalogBase: baseTopicName(topicLabel),
    );
    if (match == null || slotIndex0 >= match.lines.length) return null;
    final v = match.lines[slotIndex0].trim();
    return v.isEmpty ? null : v;
  }

  static Map<String, dynamic>? brainstormAssignmentExtrasBySlot({
    required String classId,
    required String topicLabel,
    required int slotIndex0,
  }) {
    final q = brainstormJsonQuestionAt(
      classId: classId,
      topicLabel: topicLabel,
      slotIndex0: slotIndex0,
    );
    if (q == null || q.trim().isEmpty) return null;
    final title = 'Aqliy hujum: ${baseTopicName(topicLabel)}';
    return _wrapEmbedded(
      _brainstormEmbeddedForQuestion(
        assignmentConfigTitle: title,
        questionText: q,
      ),
    );
  }

  static Map<String, dynamic> brainstormAssignmentExtrasFromPlainQuestion({
    required String assignmentConfigTitle,
    required String questionText,
  }) {
    final q = questionText.trim();
    if (q.isEmpty) return <String, dynamic>{};
    return _wrapEmbedded(
      _brainstormEmbeddedForQuestion(
        assignmentConfigTitle: assignmentConfigTitle,
        questionText: q,
      ),
    );
  }

  static List<PresetAssignmentTemplate> _quizTemplates(
    Map<String, dynamic>? raw,
    String classKey,
    String classId,
    String catalogBase,
  ) {
    if (classKey.isEmpty || classId.isEmpty || raw == null) return const [];
    final entry = _findTopicEntry(raw, catalogBase);
    if (entry == null) return const [];
    final questions = _convertQuizQuestions(entry['questions']);
    if (questions.isEmpty) return const [];

    final out = <PresetAssignmentTemplate>[];
    final max = questions.length < 5 ? questions.length : 5;
    for (var i = 0; i < max; i++) {
      final q = questions[i];
      out.add(
        PresetAssignmentTemplate(
          id: 'preset_quiz_inf_${i + 1}',
          title: 'Quiz: $catalogBase',
          subtitle: q['question'] as String?,
          assignmentDataExtras: _wrapEmbedded({
            'title': 'Quiz: $catalogBase',
            'questions': [q],
            'preset': true,
          }),
        ),
      );
    }
    return out;
  }

  static void _appendBrainstormTopicTemplates({
    required List<PresetAssignmentTemplate> out,
    required String classKey,
    required int topicIndex,
    required List<String> lines,
    required String topicName,
  }) {
    final clean = lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final max = clean.length < 5 ? clean.length : 5;
    for (var i = 0; i < max; i++) {
      final q = clean[i];
      out.add(
        PresetAssignmentTemplate(
          id: 'infjson_bs_${classKey}_${topicIndex}_$i',
          title: 'Aqliy hujum: $topicName — ${i + 1}/$max',
          subtitle: q,
          assignmentDataExtras: _wrapEmbedded(
            _brainstormEmbeddedForQuestion(
              assignmentConfigTitle: 'Aqliy hujum: $topicName (savol ${i + 1})',
              questionText: q,
            ),
          ),
        ),
      );
    }
  }

  static int? _informatikaCatalogTopicIndex(String classId, String catalogBase) {
    final list = CurriculumCatalog.topicsFor('informatika', classId);
    for (var i = 0; i < list.length; i++) {
      if (_matchTopicLoose(baseTopicName(list[i].name), catalogBase)) {
        return i;
      }
    }
    return null;
  }

  static _BrainMatch? _brainMatchFromTopicEntry(
    Map<String, dynamic> topic, {
    required int topicIndex,
  }) {
    final name = _topicNameFromEntry(topic);
    final lines = _extractTextList(topic['questions']);
    if (name.isEmpty || lines.isEmpty) return null;
    return _BrainMatch(name: name, topicIndex: topicIndex, lines: lines);
  }

  static _BrainMatch? _findBrainstormMatch(
    Map<String, dynamic> raw, {
    required String classKey,
    required String classId,
    required String catalogBase,
  }) {
    final entries = _topicEntries(raw);
    if (entries.isEmpty) return null;

    if (classKey.isNotEmpty) {
      final pref = _informatikaCatalogTopicIndex(classId, catalogBase);
      if (pref != null && pref >= 0 && pref < entries.length) {
        final m = _brainMatchFromTopicEntry(entries[pref], topicIndex: pref);
        if (m != null) {
          // O‘rta maktab dasturidagi mavzu va JSON `topics[]` qatori bir-biriga
          // mos: indeks ishonchli, so‘zdarajidagi overlap 0.2 esa rad etilardi.
          return m;
        }
      }
    }

    for (var i = 0; i < entries.length; i++) {
      final m = _brainMatchFromTopicEntry(entries[i], topicIndex: i);
      if (m == null) continue;
      if (_matchTopicLoose(catalogBase, m.name)) {
        return m;
      }
    }

    _BrainMatch? best;
    var bestScore = 0.0;
    final nBase = _normTopicForMatch(catalogBase);
    for (var i = 0; i < entries.length; i++) {
      final m = _brainMatchFromTopicEntry(entries[i], topicIndex: i);
      if (m == null) continue;
      final score = _wordOverlapScore(nBase, _normTopicForMatch(m.name));
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    if (best != null && bestScore >= 0.12) return best;
    return null;
  }

  static List<PresetAssignmentTemplate> _brainstormTemplates(
    Map<String, dynamic>? raw,
    String classKey,
    String classId,
    String catalogBase,
  ) {
    if (classKey.isEmpty || classId.isEmpty || raw == null) return const [];
    final match = _findBrainstormMatch(
      raw,
      classKey: classKey,
      classId: classId,
      catalogBase: catalogBase,
    );
    if (match == null) return const [];
    final out = <PresetAssignmentTemplate>[];
    _appendBrainstormTopicTemplates(
      out: out,
      classKey: classKey,
      topicIndex: match.topicIndex,
      lines: match.lines,
      topicName: match.name,
    );
    return out;
  }

  static List<PresetAssignmentTemplate> _caseTemplates(
    Map<String, dynamic>? raw,
    String classKey,
    String classId,
    String catalogBase,
  ) {
    if (classKey.isEmpty || classId.isEmpty || raw == null) return const [];
    final entry = _findTopicEntry(raw, catalogBase);
    if (entry == null) return const [];
    final lines = _caseStudyPlainScenarioStrings(entry['tasks']);
    if (lines.isEmpty) return const [];
    final max = lines.length < 5 ? lines.length : 5;
    return List<PresetAssignmentTemplate>.generate(max, (i) {
      final q = lines[i];
      return PresetAssignmentTemplate(
        id: 'preset_case_inf_${i + 1}',
        title: 'Case: $catalogBase',
        subtitle: q,
        assignmentDataExtras: _wrapEmbedded({
          'title': 'Case: $catalogBase',
          'scenario': q,
          'preset': true,
        }),
      );
    }, growable: false);
  }

  static List<PresetAssignmentTemplate> _clusterTemplates(
    Map<String, dynamic>? raw,
    String classKey,
    String classId,
    String catalogBase,
  ) {
    if (classKey.isEmpty || classId.isEmpty || raw == null) return const [];
    final entries = _clusterTopicEntriesList(raw);
    if (entries.isEmpty) return const [];

    final centers = <String>[];
    for (final e in entries) {
      final c = _topicNameFromEntry(e);
      if (c.isNotEmpty) centers.add(c);
    }
    if (centers.isEmpty) return const [];

    final selected = <String>[];
    for (final c in centers) {
      if (_matchTopicLoose(catalogBase, c)) selected.add(c);
    }
    if (selected.isEmpty) selected.add(centers.first);

    while (selected.length < 5) {
      selected.add(selected.first);
    }

    return List<PresetAssignmentTemplate>.generate(5, (i) {
      final c = selected[i];
      return PresetAssignmentTemplate(
        id: 'preset_group_inf_${i + 1}',
        title: 'Klaster: $catalogBase',
        subtitle: c,
        assignmentDataExtras: _wrapEmbedded({
          'title': 'Klaster: $catalogBase',
          'instructions':
              'Markaziy tushuncha: $c. Klaster tarmoqlari, misollar va yakuniy xulosani yozing.',
          'preset': true,
        }),
      );
    }, growable: false);
  }

  static List<PresetAssignmentTemplate> _tSchemaTemplates(
    Map<String, dynamic>? raw,
    String classKey,
    String classId,
    String catalogBase,
  ) {
    if (classKey.isEmpty || classId.isEmpty || raw == null) return const [];
    final entry = _findTopicEntry(raw, catalogBase);
    if (entry == null) return const [];

    final leftTitle = '${entry['left_title'] ?? 'Afzalliklari'}'.trim();
    final rightTitle = '${entry['right_title'] ?? 'Kamchiliklari'}'.trim();
    final left = _extractTextList(entry['left']);
    final right = _extractTextList(entry['right']);
    if (left.isEmpty && right.isEmpty) return const [];

    final lines = <String>[
      '$leftTitle: ${left.join('; ')}',
      '$rightTitle: ${right.join('; ')}',
    ].where((e) => e.trim().isNotEmpty).toList(growable: false);
    final branches = lines.join('\n');

    var centerLabel = _topicNameFromEntry(entry).trim();
    if (centerLabel.isEmpty) {
      centerLabel = catalogBase;
    }

    final leftItems = <Map<String, dynamic>>[
      for (var i = 0; i < left.length; i++)
        {'id': 'ts_${classKey}_l$i', 'text': left[i]},
    ];
    final rightItems = <Map<String, dynamic>>[
      for (var i = 0; i < right.length; i++)
        {'id': 'ts_${classKey}_r$i', 'text': right[i]},
    ];

    return [
      PresetAssignmentTemplate(
        id: 'preset_fishbone_inf_1',
        title: 'T-sxema: $catalogBase',
        subtitle: 'Interaktiv stikerlar (chap/o‘ng)',
        assignmentDataExtras: _wrapEmbedded({
          'title': 'T-sxema: $catalogBase',
          'problem': centerLabel,
          'branches': branches,
          'sxema':
              'T-sxema: chap va o\'ng ustunlarda dalillarni yozing, so\'ng qisqa xulosa bering.',
          'preset': true,
          'tSchemaInteractive': true,
          'tSchemaCenter': centerLabel,
          'tSchemaLeftTitle': leftTitle,
          'tSchemaRightTitle': rightTitle,
          'tSchemaLeftItems': leftItems,
          'tSchemaRightItems': rightItems,
          'tSchemaDurationMinutes': 15,
          'tSchemaMaxUserStickers': 3,
        }),
      ),
    ];
  }

  static List<Map<String, dynamic>> _topicEntries(Map<String, dynamic> raw) {
    final t = raw['topics'];
    if (t is! List) return const [];
    return t.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> _clusterTopicEntriesList(Map<String, dynamic> raw) {
    final out = <Map<String, dynamic>>[];
    void addFrom(dynamic list) {
      if (list is! List) {
        return;
      }
      for (final e in list) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        }
      }
    }
    addFrom(raw['topics']);
    if (out.isNotEmpty) {
      return out;
    }
    addFrom(raw['mavzular_klasteri']);
    if (out.isNotEmpty) {
      return out;
    }
    addFrom(raw['informatika_klaster_shablon']);
    return out;
  }

  static Map<String, dynamic>? _findTopicEntryInList(
    List<Map<String, dynamic>> entries,
    String catalogBase,
  ) {
    if (entries.isEmpty) return null;
    for (final e in entries) {
      final name = _topicNameFromEntry(e);
      if (_matchTopic(catalogBase, name)) {
        return e;
      }
    }
    for (final e in entries) {
      final name = _topicNameFromEntry(e);
      if (_matchTopicLoose(catalogBase, name)) {
        return e;
      }
    }
    Map<String, dynamic>? best;
    var bestScore = 0.0;
    final base = _normTopicForMatch(catalogBase);
    for (final e in entries) {
      final score = _wordOverlapScore(base, _normTopicForMatch(_topicNameFromEntry(e)));
      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }
    if (best != null && bestScore >= 0.12) {
      return best;
    }
    return entries.first;
  }

  static Map<String, dynamic>? _findTopicEntry(
    Map<String, dynamic> raw,
    String catalogBase,
  ) {
    return _findTopicEntryInList(_topicEntries(raw), catalogBase);
  }

  static String _topicNameFromEntry(Map<String, dynamic> e) {
    for (final k in const ['mavzu_nomi', 'mavzu', 'topic', 'name', 'center']) {
      final v = '${e[k] ?? ''}'.trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static List<String> _caseStudyPlainScenarioStrings(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final e in raw) {
      if (e is String) {
        final t = e.trim();
        if (t.isNotEmpty) out.add(t);
      } else if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final s = '${m['scenario'] ?? m['text'] ?? m['body'] ?? ''}'.trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }

  static List<String> _extractTextList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
  }
}

/// `InformatikaJsonPresets.caseStudyCatalogRows()` uchun bitta mavzu qatori.
class CaseStudyCatalogRow {
  const CaseStudyCatalogRow({
    required this.classKey,
    required this.gradeLabel,
    required this.topicName,
    required this.topicEntry,
  });

  final String classKey;
  final String gradeLabel;
  final String topicName;
  final Map<String, dynamic> topicEntry;

  String get searchBlob =>
      '${gradeLabel.toLowerCase()} ${topicName.toLowerCase()} ${classKey.toLowerCase()}';
}

class _BrainMatch {
  const _BrainMatch({
    required this.name,
    required this.topicIndex,
    required this.lines,
  });

  final String name;
  final int topicIndex;
  final List<String> lines;
}
