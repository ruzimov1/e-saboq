import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'curriculum_word_constants.dart';

/// Word dan olingan **quiz** va **T-sxema** shablonlari
/// (`assets/fayllar/informatika_quiz_presets.json`, `...fishbone_...json`).
abstract final class CurriculumWordMethodPresets {
  static Map<String, dynamic>? _informatikaQuiz;
  static Map<String, dynamic>? _informatikaFishbone;

  static final Map<String, dynamic> _kInformatikaQuizFallback = {
    'title': 'Quiz (online test): {topic}',
    'questions': [
      {
        'question':
            '{subject} — {topic}: ushbu mavzuni o‘zlashtirish darajangiz qanday?',
        'options': ['To‘liq tushunarli', 'Qisman tushunarli', 'Qiyinroq tuyuldi'],
        'correctIndex': 0,
      },
      {
        'question': '{topic} bo‘yicha amaliy mashq bajarishga qanchalik tayyorsiz?',
        'options': ['Bajarib ko‘rganman', 'Hali sinab ko‘rganim yo‘q', 'Qiyin, yordam kerak'],
        'correctIndex': 0,
      },
      {
        'question': 'Keyingi darsga {topic} bo‘yicha qanday tayyorgarlik ko‘rasiz?',
        'options': [
          'Mustaqil o‘qish va mustahkamlash',
          'Video yoki onlayn materiallar',
          'O‘qituvchi bilan qo‘shimcha tushuntirish',
        ],
        'correctIndex': 0,
      },
    ],
  };

  static final Map<String, dynamic> _kInformatikaFishboneFallback = {
    'title': 'T-sxema: {topic}',
    'problem':
        'Markaziy muammo yoki savol: {topic}. O‘qituvchi bu qatorni dars vaziyati bilan aniqlashtirishi mumkin.',
    'branches':
        'Chap va o‘ng ustunlar bo‘yicha dalillarni yozing. Har bir yo‘nalish bo‘yicha sabab-moqolarni yozing:\n• Texnik / jihoz\n• Inson / kompetensiya\n• Jarayon / reja\n• Vaqt / resurs\n• Tashqi omillar (tarmoq, qonun-qoida)',
    'sxema':
        'T-sxema: vertikal ustunda — asosiy muammo yoki savol; gorizontal qismda chap va o‘ng tomonda sabablar, omillar yoki taqqoslash nuqtalari. Pastki qatorda qisqa xulosa beriladi. O‘qituvchi o‘quvchidan muammo → tahlil → xulosa zanjirini matnda ifodalashni talab qilishi mumkin. Matn: Word o‘quv dasturidan; `{topic}` va `{subject}` maydonlari dasturda avtomatik to‘ldiriladi.',
  };

  static Future<void> loadFromAssets() async {
    _informatikaQuiz = await _loadOne(
      CurriculumWordConstants.informatikaQuizMethodAssetPath,
    );
    _informatikaFishbone = await _loadOne(
      CurriculumWordConstants.informatikaFishboneMethodAssetPath,
    );
  }

  static Future<Map<String, dynamic>?> _loadOne(String path) async {
    Object? lastError;
    for (final p in CurriculumWordConstants.methodAssetPathVariants(path)) {
      try {
        final s = await rootBundle.loadString(p);
        final map = jsonDecode(s) as Map<String, dynamic>;
        final inf = map['informatika'] as Map<String, dynamic>?;
        if (inf == null) return null;
        return Map<String, dynamic>.from(inf);
      } catch (e) {
        lastError = e;
      }
    }
    if (kDebugMode) {
      debugPrint('CurriculumWordMethodPresets: $path — $lastError');
    }
    return null;
  }

  /// [topic], [subject] — mavzu va fan nomi (transliteratsiya emas, katalogdagi nom).
  static Map<String, dynamic>? informatikaQuizConfig({
    required String topic,
    required String subject,
  }) {
    final raw = _informatikaQuiz ?? _kInformatikaQuizFallback;
    final applied = _applyTokens(Map<String, dynamic>.from(raw), topic, subject);
    applied['preset'] = true;
    return applied;
  }

  static Map<String, dynamic>? informatikaFishboneConfig({
    required String topic,
    required String subject,
  }) {
    final raw = _informatikaFishbone ?? _kInformatikaFishboneFallback;
    final applied = _applyTokens(Map<String, dynamic>.from(raw), topic, subject);
    applied['preset'] = true;
    return applied;
  }

  static dynamic _applyTokens(dynamic v, String topic, String subject) {
    if (v is String) {
      return v
          .replaceAll(CurriculumWordConstants.topicToken, topic)
          .replaceAll(CurriculumWordConstants.subjectToken, subject);
    }
    if (v is List) {
      return v.map((e) => _applyTokens(e, topic, subject)).toList();
    }
    if (v is Map) {
      return v.map(
        (k, val) => MapEntry(
          k is String ? k : '$k',
          _applyTokens(val, topic, subject),
        ),
      );
    }
    return v;
  }

  @visibleForTesting
  static void resetForTest() {
    _informatikaQuiz = null;
    _informatikaFishbone = null;
  }
}
