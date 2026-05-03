import 'package:flutter/foundation.dart';

import 'gemini_api.dart';

/// O'quvchi javobini **yordamchi tahlil** qilish (Google Gemini).
/// API kalit: `.env` faylida `GEMINI_API_KEY=...` (https://aistudio.google.com/apikey).
///
/// Brauzer (web) muhitida to'g'ridan-to'g'ri so'rov ba'zan CORS yoki
/// xavfsizlik tufayli ishlamasligi mumkin; bunday hollarda mobil ilova
/// yoki backend proksi tavsiya etiladi.
abstract final class GeminiSubmissionReviewer {
  static Future<String> reviewSubmission({
    required String apiKey,
    required String assignmentTitle,
    String? rubric,
    required String answerDescription,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Sen o\'quvchining topshirig\'ini tahlil qiluvchi yordamchisan.')
      ..writeln('O\'qituchining yakuniy bahosi o\'rnatiladi — sen faqat yordam berasan.')
      ..writeln('Quyidagilarni o\'zbek tilida, qisqa va aniq ber:')
      ..writeln('1) Bitta qisqa xulosa (2-4 jumla).')
      ..writeln('2) Ijobiy tomonlar (agar bor, bullet).')
      ..writeln('3) Yaxshilash tavsiyalari (bullet).')
      ..writeln('4) Taxminiy tavsiyaviy ball: 0–100 (faqat tavsiya), shu qatordan keyin: "Tavsiyaviy ball: XX"')
      ..writeln('Shaxsiy identifikator va ism-familani taxmin qilma.')
      ..writeln()
      ..writeln('Topshiriq sarlavhasi: $assignmentTitle');
    if (rubric != null && rubric.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Baholash mezonlari (agar mavjud):')
        ..writeln(rubric.trim());
    }
    buffer
      ..writeln()
      ..writeln('O\'quvchi topshirig\'i (JSON yoki tavsif):')
      ..writeln(answerDescription.trim().isEmpty ? '—' : answerDescription.trim());

    final prompt = buffer.toString();
    try {
      return await GeminiApi.generateText(
        apiKey: apiKey,
        prompt: prompt,
        temperature: 0.35,
        maxOutputTokens: 2048,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GeminiSubmissionReviewer: $e');
      }
      rethrow;
    }
  }
}
