import 'gemini_api.dart';

/// Metodlar bo‘yicha qisqa AI yordami (Gemini).
abstract final class GeminiMethodCoach {
  /// Noto‘g‘ri tanlovdan keyin vaziyatni davom ettirish (2–5 jumla, o‘zbek).
  static Future<String> caseStudyDynamicBranch({
    required String apiKey,
    required String scenarioSummary,
    required String chosenAction,
    required String systemReaction,
    required String priorContext,
  }) {
    final prompt = StringBuffer()
      ..writeln('Sen interaktiv muammoli vaziyat («case-study») ssenaristisan.')
      ..writeln('O\'quvchi xato yo\'ldagi tanlov qildi. Hozirgi tizim/oqibat:')
      ..writeln(systemReaction)
      ..writeln()
      ..writeln('Tanlangan harakat (o\'quvchi): $chosenAction')
      ..writeln('Vaziyat qisqacha: ${scenarioSummary.trim().isEmpty ? '—' : scenarioSummary.trim()}')
      ..writeln('Oldingi kontekst (agar bor): ${priorContext.trim().isEmpty ? '—' : priorContext.trim()}')
      ..writeln()
      ..writeln('Talab: o\'zbek tilida 2–5 ta qisqa jumla bilan vaziyatni «keyingi lahza» sifatida davom ettir.')
      ..writeln('Realistik IT/xavfsizlik tili. To\'g\'ri yechimni to\'liq bermagan bo\'l — faqat qanday rivojlanishini qayd et.')
      ..writeln('Shaxsiylarni taxmin qilma.');
    return GeminiApi.generateText(
      apiKey: apiKey,
      prompt: prompt.toString(),
      temperature: 0.55,
      maxOutputTokens: 640,
    );
  }

  /// Yozma tahlil bo‘yicha qisqa, do‘stona maslahat (o‘qituvchi bahosi alohida).
  static Future<String> caseStudyReflectionCoach({
    required String apiKey,
    required String scenarioSummary,
    required String reflectionDraft,
    String? probesSummary,
  }) {
    final buf = StringBuffer()
      ..writeln('Sen informatika/xavfsizlik bo\'yicha o\'quvchi yordamchisisan.')
      ..writeln('Vaziyat: ${scenarioSummary.trim().isEmpty ? '—' : scenarioSummary.trim()}')
      ..writeln()
      ..writeln('Oldingi tanlovlar (agar berilgan): ${probesSummary ?? '—'}')
      ..writeln()
      ..writeln('O\'quvchi yozgan tahlil (matn):')
      ..writeln(reflectionDraft.trim().isEmpty ? '—' : reflectionDraft.trim())
      ..writeln()
      ..writeln('Talab: o\'zbek tilida juda qisqa (1 abzas + 2–3 ta bullet) ber:')
      ..writeln('- nima yaxshi;')
      ..writeln('- nimani qo\'shish kerak (masalan zaxira nusxa, rasmiy kanal, xavfni baholash);')
      ..writeln('Taxminiy ball bermagan bo\'l. Shaxsiylarni taxmin qilma.');
    return GeminiApi.generateText(
      apiKey: apiKey,
      prompt: buf.toString(),
      temperature: 0.35,
      maxOutputTokens: 768,
    );
  }

  /// Aqliy hujum: g‘oyalarni guruh nomlari bilan qisqa klasterlash (JSON emas, oddiy matn).
  static Future<String> brainstormClusterDraft({
    required String apiKey,
    required String topicPrompt,
    required List<String> ideas,
  }) {
    final ideasText = ideas.map((e) => '• ${e.trim()}').join('\n');
    final buf = StringBuffer()
      ..writeln('Sen aqliy hujum sessiyasida g\'oyalarni tartibga soluvchi moderatorsan.')
      ..writeln('Mavzu: ${topicPrompt.trim().isEmpty ? '—' : topicPrompt.trim()}')
      ..writeln()
      ..writeln('G\'oyalar ro\'yxati:')
      ..writeln(ideasText.isEmpty ? '—' : ideasText)
      ..writeln()
      ..writeln('Talab: o\'zbek tilida 3–6 ta guruh sarlavhasi yoz; har guruh ostida tegishli g\'oyalarni ro\'yxat qil.')
      ..writeln('Juda uzun bo\'lma (maks. ~40 qator). Original bo\'lgan yoki noyob g\'oyalarni alohida belgilab qo\'y (1 jumlada).');
    return GeminiApi.generateText(
      apiKey: apiKey,
      prompt: buf.toString(),
      temperature: 0.4,
      maxOutputTokens: 1536,
    );
  }

  /// Klaster / T-sxema: bitta fikrni mazmunan tekshirish.
  static Future<String> placementHint({
    required String apiKey,
    required String methodLabel,
    required String sideOrBranch,
    required String studentText,
    required String referenceTerms,
  }) {
    final buf = StringBuffer()
      ..writeln('Sen informatika o\'quvchisi fikrini mantiqiy tekshiruvchi yordamchisan.')
      ..writeln('Metod: $methodLabel')
      ..writeln('Talab qilinayotgan joy (ustun/yo\'nalish): $sideOrBranch')
      ..writeln()
      ..writeln('O\'quvchi qo\'shgan matn: ${studentText.trim().isEmpty ? '—' : studentText.trim()}')
      ..writeln()
      ..writeln('Mavjud termin / kutilgan kontekst (qisqa): ${referenceTerms.trim().isEmpty ? '—' : referenceTerms.trim()}')
      ..writeln()
      ..writeln('Talab: o\'zbek tilida 3–6 jumla. Ushbu joy to\'g\'rimi? Agar shubha bo\'lsa, qaysi boshqa ustun/klasterga yaqinroq ekanini yoz.')
      ..writeln('To\'g\'ridan-to\'g\'ri «noto\'g\'ri» deb aytding, lekin sababini tushuntir.');
    return GeminiApi.generateText(
      apiKey: apiKey,
      prompt: buf.toString(),
      temperature: 0.3,
      maxOutputTokens: 640,
    );
  }

  /// Quiz: mavzu bo‘yicha bitta yangi ko‘p tanlov savoli (JSON qaytmasin — matn blok).
  static Future<String> quizSuggestQuestion({
    required String apiKey,
    required String topicSnippet,
    required String difficulty,
  }) {
    final buf = StringBuffer()
      ..writeln('Sen informatika o\'qituvchisi uchun test tuzuvchisan.')
      ..writeln('Mavzu matni (qisqa): ${topicSnippet.trim().isEmpty ? '—' : topicSnippet.trim()}')
      ..writeln('Daraja: $difficulty')
      ..writeln()
      ..writeln('Talab: o\'zbek tilida bitta test savoli yoz va 4 ta variant (A–D) ber.')
      ..writeln('To\'g\'ri javobni oxirida alohida qatorda «To\'g\'ri: A» yoki B/C/D ko\'rinishida ko\'rsat.')
      ..writeln('Faqat o\'quv darsiga mos, xavfsiz kontent.');
    return GeminiApi.generateText(
      apiKey: apiKey,
      prompt: buf.toString(),
      temperature: 0.45,
      maxOutputTokens: 768,
    );
  }

  /// Umumiy «AI Assistant» bir martalik maslahat (progress, keyingi qadam).
  static Future<String> studyCompanionNudge({
    required String apiKey,
    required String methodType,
    required String assignmentTitle,
    required String situationBrief,
  }) {
    final buf = StringBuffer()
      ..writeln('Sen «e-Saboq» ilovasidagi qisqa AI yordamchisan (personaj: do\'st, rasmiy emas).')
      ..writeln('Metod turi: $methodType')
      ..writeln('Topshiriq: ${assignmentTitle.trim().isEmpty ? '—' : assignmentTitle.trim()}')
      ..writeln()
      ..writeln('Holat (o\'qituvchi yoki tizim bergan qisqa kontekst):')
      ..writeln(situationBrief.trim().isEmpty ? '—' : situationBrief.trim())
      ..writeln()
      ..writeln('Talab: o\'zbek tilida 2–4 jumla. O\'quvchini ruhlantir; agar mos bo\'lsa, 「aniqlik foizi」 yoki 「keyingi qadam」 haqida yumorli-qisqa frazani ishlat.')
      ..writeln('To\'g\'ridan-to\'g\'ri test javobini bermagan bo\'l.');
    return GeminiApi.generateText(
      apiKey: apiKey,
      prompt: buf.toString(),
      temperature: 0.45,
      maxOutputTokens: 512,
    );
  }
}
