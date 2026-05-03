import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Google Gemini `generateContent` (bir necha model bo‘yicha ketma-ket urinish).
///
/// Brauzerda bevosita chaqirish ba'zan CORS tufayli ishlamasligi mumkin — mobil yoki backend proksi tavsiya etiladi.
abstract final class GeminiApi {
  /// Mavjud modellar: https://ai.google.dev/gemini-api/docs/models
  ///
  /// Eski nomlar (`gemini-1.5-pro`, `gemini-1.5-flash-8b` va h.k.) ko‘pincha
  /// `v1beta` da `NOT_FOUND` beradi — avvalo 2.5‑lar, keyin barqaror zaxiralar.
  static const models = <String>[
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-2.5-pro',
  ];

  static Future<String> generateText({
    required String apiKey,
    required String prompt,
    double temperature = 0.35,
    int maxOutputTokens = 2048,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw StateError('GEMINI_API_KEY bo\'sh');
    }
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    Object? lastErr;
    for (final model in models) {
      try {
        final uri =
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key';
        final res = await dio.post<Map<String, dynamic>>(
          uri,
          data: <String, dynamic>{
            'contents': <Map<String, dynamic>>[
              {
                'parts': <Map<String, String>>[
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': <String, dynamic>{
              'temperature': temperature,
              'maxOutputTokens': maxOutputTokens,
            },
            'safetySettings': <Map<String, String>>[
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'threshold': 'BLOCK_ONLY_HIGH',
              },
              {
                'category': 'HARM_CATEGORY_HATE_SPEECH',
                'threshold': 'BLOCK_ONLY_HIGH',
              },
            ],
          },
        );

        final data = res.data;
        if (data == null) {
          lastErr = 'Javob bo\'sh';
          continue;
        }
        final text = extractText(data);
        if (text != null && text.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('GeminiApi: model=$model');
          }
          return text.trim();
        }
        lastErr = 'Matn olinmadi (model: $model)';
      } on DioException catch (e) {
        lastErr = e.response?.data ?? e.message;
        if (kDebugMode) {
          debugPrint('GeminiApi model $model: $e');
        }
        continue;
      } catch (e) {
        lastErr = e;
        continue;
      }
    }
    throw StateError('Gemini: $lastErr');
  }

  static String? extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }
    final first = candidates[0];
    if (first is! Map) {
      return null;
    }
    final content = first['content'];
    if (content is! Map) {
      return null;
    }
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return null;
    }
    final p0 = parts[0];
    if (p0 is! Map) {
      return null;
    }
    return p0['text'] as String?;
  }
}
