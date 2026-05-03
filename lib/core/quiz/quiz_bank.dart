import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// `fayllar/quizz/*.json` — kelishuvli quiz banki tuzilmasi.
/// Har bir [QuizBankTopic] ichida savollar; har bir savol da 4 ta variant (A–D).
abstract final class QuizBankJson {
  static const optionOrder = ['A', 'B', 'C', 'D'];

  static String assetPathForGradeId(String classId) {
    final g = classId.trim();
    if (g == '10' || g == '11') {
      return 'fayllar/quizz/10_11_sinf_quiz.json';
    }
    return 'fayllar/quizz/${g}_sinf_quiz.json';
  }

  static Future<QuizBankPayload?> loadForClassId(String classId) async {
    final path = assetPathForGradeId(classId);
    try {
      final raw = await rootBundle.loadString(path);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return QuizBankPayload.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Firestore [config.questions] elementi: `[o‘qituvchi tanlagan]` tartibda.
  static Map<String, dynamic> toMethodQuestionMap(QuizBankQuestion q) {
    final opts = <String>[];
    for (final k in optionOrder) {
      final t = q.options[k];
      if (t != null && t.trim().isNotEmpty) {
        opts.add(t.trim());
      }
    }
    while (opts.length < 4) {
      opts.add('—');
    }
    final letters = optionOrder;
    final correctLetter = q.correct.trim().toUpperCase();
    var correctIndex = letters.indexOf(correctLetter);
    if (correctIndex < 0) {
      correctIndex = 0;
    }
    return <String, dynamic>{
      'question': q.text,
      'options': opts.take(4).toList(),
      'correctIndex': correctIndex,
      'topic': q.sourceTopic,
    };
  }
}

class QuizBankPayload {
  const QuizBankPayload({
    required this.grade,
    required this.topics,
  });

  final String grade;
  final List<QuizBankTopic> topics;

  factory QuizBankPayload.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'] as List<dynamic>? ?? [];
    return QuizBankPayload(
      grade: '${json['grade'] ?? ''}',
      topics: [
        for (var ti = 0; ti < rawTopics.length; ti++)
          QuizBankTopic.fromJson(
            rawTopics[ti] as Map<String, dynamic>,
            topicIndex: ti,
          ),
      ],
    );
  }
}

class QuizBankTopic {
  const QuizBankTopic({
    required this.title,
    required this.questions,
  });

  final String title;
  final List<QuizBankQuestion> questions;

  factory QuizBankTopic.fromJson(
    Map<String, dynamic> json, {
    required int topicIndex,
  }) {
    final title = '${json['topic'] ?? json['title'] ?? ''}';
    final rawQ = json['questions'] as List<dynamic>? ?? [];
    final list = <QuizBankQuestion>[];
    for (var qi = 0; qi < rawQ.length; qi++) {
      final e = rawQ[qi];
      if (e is Map<String, dynamic>) {
        list.add(
          QuizBankQuestion.fromJson(
            e,
            sourceTopic: title,
            topicIndex: topicIndex,
            questionIndex: qi,
          ),
        );
      }
    }
    return QuizBankTopic(title: title, questions: list);
  }
}

class QuizBankQuestion {
  const QuizBankQuestion({
    required this.text,
    required this.options,
    required this.correct,
    required this.sourceTopic,
    required this.topicIndex,
    required this.questionIndex,
  });

  final String text;
  final Map<String, String> options;
  final String correct;
  final String sourceTopic;
  final int topicIndex;
  final int questionIndex;

  String get selectionKey => '$topicIndex:$questionIndex';

  factory QuizBankQuestion.fromJson(
    Map<String, dynamic> json, {
    required String sourceTopic,
    int topicIndex = 0,
    int questionIndex = 0,
  }) {
    final optsRaw = json['options'];
    final map = <String, String>{};
    if (optsRaw is Map) {
      for (final en in optsRaw.entries) {
        final k = '${en.key}'.toUpperCase();
        map[k] = '${en.value}';
      }
    }
    return QuizBankQuestion(
      text: '${json['question'] ?? ''}',
      options: map,
      correct: '${json['correct'] ?? 'A'}'.toUpperCase(),
      sourceTopic: sourceTopic,
      topicIndex: topicIndex,
      questionIndex: questionIndex,
    );
  }
}
