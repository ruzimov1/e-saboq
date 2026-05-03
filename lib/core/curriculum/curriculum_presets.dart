import '../../features/teacher/methods/data/method_model.dart';
import 'curriculum_catalog.dart';
import 'informatika_json_presets.dart';
import 'curriculum_word_assignments.dart';
import 'curriculum_word_method_presets.dart';
import 'preset_assignment_template.dart';

export 'preset_assignment_template.dart';

/// Har bir mavzuda o'qituvchiga tayyor — zamonaviy metodlar va topshiriq shablonlari.
abstract final class CurriculumPresets {
  static const String quizId = 'preset_quiz';
  static const String brainstormId = 'preset_brainstorm';
  static const String caseId = 'preset_case';
  static const String groupId = 'preset_group';
  static const String fishboneId = 'preset_fishbone';

  static bool isPresetMethodId(String id) => id.startsWith('preset_');

  static String _topicLabel(String subjectId, String classId, String topicId) {
    final topics = CurriculumCatalog.topicsFor(subjectId, classId);
    for (final t in topics) {
      if (t.id == topicId) return t.name;
    }
    return topicId;
  }

  /// Katalogdagi to‘liq mavzu sarlavhasi (masalan `5-sinf: ...`).
  static String topicLabel(
    String subjectId,
    String classId,
    String topicId,
  ) {
    return _topicLabel(subjectId, classId, topicId);
  }

  /// Tayyor topshiriqlar ro‘yxati: `Metod · sinf · mavzu · N-topshiriq`
  static String readyPresetRowTitle({
    required String methodId,
    required String classId,
    required String subjectId,
    required String topicId,
    required int taskNumber1Based,
  }) {
    if (taskNumber1Based < 1) {
      throw ArgumentError.value(taskNumber1Based, 'taskNumber1Based');
    }
    final m = _presetMethodShortName(methodId);
    final s = '$classId-sinf';
    final t = InformatikaJsonPresets.baseTopicName(
      _topicLabel(subjectId, classId, topicId),
    );
    return '$m · $s · $t · $taskNumber1Based-topshiriq';
  }

  static String _presetMethodShortName(String methodId) {
    return switch (methodId) {
      quizId => 'Test (Quiz)',
      brainstormId => 'Aqliy hujum',
      caseId => 'Muammoli vaziyat',
      groupId => 'Klaster',
      fishboneId => 'T-sxema',
      _ => 'Topshiriq',
    };
  }

  static String _subjectName(String subjectId) {
    for (final e in CurriculumCatalog.subjectEntries) {
      if (e.id == subjectId) return e.name;
    }
    return subjectId;
  }

  /// Mavzu bo'yicha tayyor metodlar (e-Saboq metodikasi + qo'shimcha).
  /// [overrideTopicLabel] — maxsus fan + qo'lda qo'shilgan mavzu uchun sarlavha (masalan `5-sinf: ...`).
  static List<MethodModel> presetMethodsFor({
    required String subjectId,
    required String classId,
    required String topicId,
    String? overrideTopicLabel,
  }) {
    final topic = (overrideTopicLabel != null && overrideTopicLabel.trim().isNotEmpty)
        ? overrideTopicLabel.trim()
        : _topicLabel(subjectId, classId, topicId);
    final subject = _subjectName(subjectId);

    // Tartib: Aqliy hujum → Muammoli vaziyat → Klaster → Test (Quiz) → T-sxema
    final models = <MethodModel>[
      MethodModel(
        id: brainstormId,
        type: 'brainstorm',
        config: <String, dynamic>{
          'title': 'Aqliy hujum: $topic',
          'preset': true,
          'prompt':
              'Mavzu bo\'yicha barcha g\'oyalarni yozing (tanqid qilmasdan). Keyin eng yaxshi 3 tasini tanlang.',
        },
      ),
      MethodModel(
        id: caseId,
        type: 'case',
        config: <String, dynamic>{
          'title': 'Muammoli vaziyat: $topic',
          'preset': true,
          'scenario':
              'Haqiqiy hayotdan qisqa vaziyat: muammoni aniqlang, sabablarni tahlil qiling, 2 ta yechim yo\'lini asoslang.',
        },
      ),
      MethodModel(
        id: groupId,
        type: 'group',
        config: <String, dynamic>{
          'title': 'Klaster: $topic',
          'preset': true,
          'instructions':
              'Markaziy tushuncha atrofida g\'oyalarni klasterlarga ajrating: har bir klaster uchun sarlavha va 2–3 ta misol.',
        },
      ),
      MethodModel(
        id: quizId,
        type: 'quiz',
        config: <String, dynamic>{
          'title': 'Test (Quiz): $topic',
          'preset': true,
          'questions': [
            {
              'question':
                  '$subject — $topic: mavzuni qanchalik o\'zlashtirgansiz?',
              'options': [
                'To\'liq tushunarli',
                'Qisman tushunarli',
                'Qiyin',
              ],
              'correctIndex': 0,
            },
            {
              'question': 'Keyingi darsga qanday tayyorgarlik ko\'rasiz?',
              'options': [
                'Mustaqil o\'qish',
                'Video materiallar',
                'O\'qituvchi bilan maslahat',
              ],
              'correctIndex': 0,
            },
          ],
        },
      ),
      MethodModel(
        id: fishboneId,
        type: 'fishbone',
        config: <String, dynamic>{
          'title': 'T-sxema: $topic',
          'preset': true,
          'problem': 'Mavzu yoki taqqoslash savoli (T-sxemaning ustuni).',
          'branches':
              'Chap va o\'ng ustunlar bo\'yicha fikrlarni yozing; pastda qisqa xulosa.',
        },
      ),
    ];

    if (subjectId == 'informatika') {
      final q = CurriculumWordMethodPresets.informatikaQuizConfig(
        topic: topic,
        subject: subject,
      );
      final f = CurriculumWordMethodPresets.informatikaFishboneConfig(
        topic: topic,
        subject: subject,
      );
      return [
        for (final m in models)
          if (m.id == quizId && q != null)
            MethodModel(id: quizId, type: 'quiz', config: q)
          else if (m.id == fishboneId && f != null)
            MethodModel(id: fishboneId, type: 'fishbone', config: f)
          else
            m,
      ];
    }
    return models;
  }

  static MethodModel? presetMethodById({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
  }) {
    if (!isPresetMethodId(methodId)) return null;
    for (final m in presetMethodsFor(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    )) {
      if (m.id == methodId) return m;
    }
    return null;
  }

  /// Bir bosishda yaratiladigan topshiriq sarlavhalari (mavzu kontekstida).
  static List<PresetAssignmentTemplate> presetAssignmentTemplates({
    required String subjectId,
    required String classId,
    required String topicId,
  }) {
    final topic = _topicLabel(subjectId, classId, topicId);
    return [
      PresetAssignmentTemplate(
        id: 'hw_review',
        title: 'Uyga vazifa: $topic — qayta ishlash',
        subtitle: 'Mavzu bo\'yicha qisqa yozma yoki mashqlar',
      ),
      PresetAssignmentTemplate(
        id: 'mini_test',
        title: 'Nazorat: $topic — bilimni tekshirish',
        subtitle: '10-15 daqiqalik mini-test tavsiyasi',
      ),
      PresetAssignmentTemplate(
        id: 'project_group',
        title: 'Loyiha (guruh): $topic',
        subtitle: 'Tadqiqot yoki taqdimot tayyorlash',
      ),
      PresetAssignmentTemplate(
        id: 'reflection',
        title: 'Refleksiya: $topic',
        subtitle: 'O\'z-o\'zini baholash va savollar',
      ),
    ];
  }

  /// Informatika: har bir sinf va mavzu uchun, har bir tayyor metodga mos shablonlar
  /// (Aqliy hujum: ro'yxat bo'sh — savollar bazasi; Klaster: bo'sh — topshiriq
  /// metod tahririda «Kodli topshiriq yaratish» bilan).
  /// Boshqa fanlar — [presetAssignmentTemplates] (4 ta).
  static List<PresetAssignmentTemplate> presetAssignmentTemplatesForMethod({
    required String subjectId,
    required String classId,
    required String topicId,
    required String methodId,
  }) {
    if (methodId == groupId) {
      return const <PresetAssignmentTemplate>[];
    }
    if (subjectId == 'informatika' && methodId == brainstormId) {
      return const <PresetAssignmentTemplate>[];
    }
    if (subjectId == 'informatika' && methodId == quizId) {
      return const <PresetAssignmentTemplate>[];
    }
    if (subjectId == 'informatika' && isPresetMethodId(methodId)) {
      final topic = _topicLabel(subjectId, classId, topicId);
      final fromJson = InformatikaJsonPresets.templatesFor(
        methodId: methodId,
        classId: classId,
        topicLabel: topic,
      );
      if (fromJson.isNotEmpty) {
        return fromJson;
      }
      final fromWord = CurriculumWordAssignments.informatikaFor(
        methodId,
        topic,
      );
      if (fromWord.isNotEmpty) {
        if (methodId == brainstormId) {
          return _informatikaBrainstormAttachJson(
            fromWord,
            classId: classId,
            topicLabel: topic,
          );
        }
        return fromWord;
      }
      return _informatikaPresetAssignmentsForMethod(
        methodId,
        topic,
        classId,
      );
    }
    return presetAssignmentTemplates(
      subjectId: subjectId,
      classId: classId,
      topicId: topicId,
    );
  }

  /// Aqliy hujum: Word/oddiy sarlavha ustiga JSONdagi 5 alohida savolni
  /// [assignmentDataExtras] sifatida biriktiradi (slot: ro‘yxat indeksi).
  static List<PresetAssignmentTemplate> _informatikaBrainstormAttachJson(
    List<PresetAssignmentTemplate> items, {
    required String classId,
    required String topicLabel,
  }) {
    return List<PresetAssignmentTemplate>.generate(
      items.length,
      (i) {
        final t = items[i];
        final ex = InformatikaJsonPresets.brainstormAssignmentExtrasBySlot(
          classId: classId,
          topicLabel: topicLabel,
          slotIndex0: i,
        );
        if (ex == null) {
          final sub = t.subtitle?.trim();
          if (sub != null && sub.isNotEmpty) {
            final plain = InformatikaJsonPresets
                .brainstormAssignmentExtrasFromPlainQuestion(
              assignmentConfigTitle: t.title,
              questionText: sub,
            );
            if (plain.isNotEmpty) {
              return PresetAssignmentTemplate(
                id: t.id,
                title: t.title,
                subtitle: sub,
                assignmentDataExtras: plain,
              );
            }
          }
          return t;
        }
        final sub = _shortQuestionFromBrainstormEmbed(ex) ?? t.subtitle;
        return PresetAssignmentTemplate(
          id: t.id,
          title: t.title,
          subtitle: sub,
          assignmentDataExtras: ex,
        );
      },
    );
  }

  static String? _shortQuestionFromBrainstormEmbed(Map<String, dynamic> ex) {
    final emb = ex['embeddedMethodConfig'] as Map<String, dynamic>?;
    if (emb == null) {
      return null;
    }
    final p = emb['prompt'] as String? ?? '';
    if (p.isEmpty) {
      return null;
    }
    final parts = p.split('\n\n');
    if (parts.isEmpty) {
      return p.trim();
    }
    return parts.last.trim();
  }

  static List<PresetAssignmentTemplate> _informatikaPresetAssignmentsForMethod(
    String methodId,
    String topic,
    String classId,
  ) {
    switch (methodId) {
      case quizId:
        return [
          PresetAssignmentTemplate(
            id: '${quizId}_inf_1',
            title: 'Test (Quiz): $topic — asosiy tushunchalar',
            subtitle: 'Mavzuning kalit ideyalari bo\'yicha tez tekshiruv',
          ),
          PresetAssignmentTemplate(
            id: '${quizId}_inf_2',
            title: 'Test (Quiz): $topic — amaliy bilim',
            subtitle: 'Kompyuter va AKTdan foydalanish bo\'yicha',
          ),
          PresetAssignmentTemplate(
            id: '${quizId}_inf_3',
            title: 'Test (Quiz): $topic — qisqa nazorat (10 daqiqa)',
            subtitle: 'Dars yakunidagi mini-test',
          ),
          PresetAssignmentTemplate(
            id: '${quizId}_inf_4',
            title: 'Test (Quiz): $topic — axborot xavfsizligi va etika',
            subtitle: 'Parol, shaxsiy ma\'lumot, ishonchli manbalar',
          ),
          PresetAssignmentTemplate(
            id: '${quizId}_inf_5',
            title: 'Test (Quiz): $topic — mustahkamlash',
            subtitle: 'Oldingi mavzular bilan bog\'langan takrorlash',
          ),
        ];
      case brainstormId:
        return _informatikaBrainstormAttachJson(
          [
            PresetAssignmentTemplate(
              id: '${brainstormId}_inf_1',
              title: 'Aqliy hujum: $topic — kalit so\'zlar va atamalar',
              subtitle: 'Mavzuga oid barcha muhim terminlarni yozish',
            ),
            PresetAssignmentTemplate(
              id: '${brainstormId}_inf_2',
              title: 'Aqliy hujum: $topic — muammo va yechim g\'oyalari',
              subtitle: 'Amaliyotdagi vaziyatlar va IT yechimlari',
            ),
            PresetAssignmentTemplate(
              id: '${brainstormId}_inf_3',
              title: 'Aqliy hujum: $topic — AKT vositalari',
              subtitle: 'Dastur, qurilma, xizmat — qisqa ro\'yxat',
            ),
            PresetAssignmentTemplate(
              id: '${brainstormId}_inf_4',
              title: 'Aqliy hujum: $topic — kasb va kelajak',
              subtitle: 'Informatika bilan bog\'liq kasblar haqida g\'oyalar',
            ),
            PresetAssignmentTemplate(
              id: '${brainstormId}_inf_5',
              title: 'Aqliy hujum: $topic — loyiha g\'oyalari',
              subtitle: 'Sinfdagi yoki uyda bajariladigan kichik loyihalar',
            ),
          ],
          classId: classId,
          topicLabel: topic,
        );
      case caseId:
        return [
          PresetAssignmentTemplate(
            id: '${caseId}_inf_1',
            title: 'Case: $topic — fayl yo\'qoldi, nima qilasiz?',
            subtitle: 'Zaxira nusxa, qidiruv, xavfsizlik qoidalari',
          ),
          PresetAssignmentTemplate(
            id: '${caseId}_inf_2',
            title: 'Case: $topic — parolni begonalarga bermaslik',
            subtitle: 'Phishing va ijtimoiy injeneriya vaziyati',
          ),
          PresetAssignmentTemplate(
            id: '${caseId}_inf_3',
            title: 'Case: $topic — shubhali xat yoki havola',
            subtitle: 'Tarmoqda xavfsiz harakatlar rejasi',
          ),
          PresetAssignmentTemplate(
            id: '${caseId}_inf_4',
            title: 'Case: $topic — guruhbila loyiha muddati',
            subtitle: 'Rollar, muddat, muloqot vositalari',
          ),
          PresetAssignmentTemplate(
            id: '${caseId}_inf_5',
            title: 'Case: $topic — internet manbasi ishonchliligi',
            subtitle: 'Manbashunoslik va tekshirish qadamlari',
          ),
        ];
      case fishboneId:
        return [
          PresetAssignmentTemplate(
            id: '${fishboneId}_inf_1',
            title: 'T-sxema: $topic — mavzu bo\'yicha tahlil',
            subtitle: 'Chap va o\'ng ustunlar bo\'yicha fikrlar',
          ),
        ];
      case groupId:
        return [
          PresetAssignmentTemplate(
            id: '${groupId}_inf_1',
            title: 'Klaster: $topic — taqdimot tayyorlash',
            subtitle: 'Slayd va nutq tuzilmasi',
          ),
          PresetAssignmentTemplate(
            id: '${groupId}_inf_2',
            title: 'Klaster: $topic — qisqa video / skrin-kast',
            subtitle: 'Mavzuni tushuntirish bo\'yicha',
          ),
          PresetAssignmentTemplate(
            id: '${groupId}_inf_3',
            title: 'Klaster: $topic — infografika yoki plakat',
            subtitle: 'Vizual qisqa xulosalar',
          ),
          PresetAssignmentTemplate(
            id: '${groupId}_inf_4',
            title: 'Klaster: $topic — veb-resurs tahlili',
            subtitle: 'Ishonchli sayt va ma\'lumot tanlash',
          ),
          PresetAssignmentTemplate(
            id: '${groupId}_inf_5',
            title: 'Klaster: $topic — mini-loyiha hisoboti',
            subtitle: 'Maqsad, usul, natija',
          ),
        ];
      default:
        return List<PresetAssignmentTemplate>.generate(
          5,
          (i) => PresetAssignmentTemplate(
            id: '${methodId}_inf_fb_${i + 1}',
            title: 'Topshiriq ${i + 1}: $topic',
            subtitle: 'Informatika — umumiy shablon',
          ),
        );
    }
  }
}
