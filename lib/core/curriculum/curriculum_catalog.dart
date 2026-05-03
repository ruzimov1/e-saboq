import '../../features/teacher/subjects/data/subject_model.dart';
import '../../features/teacher/classes/data/class_model.dart';
import '../../features/teacher/topics/data/topic_model.dart';

/// O'quv dasturi: barcha o'qituvchilar uchun bir xil fanlar, sinflar va mavzular.
abstract final class CurriculumCatalog {
  static const String systemTeacherId = '__curriculum__';

  /// Barqaror fan identifikatorlari (Firestore yo'llari uchun).
  static const List<({String id, String name})> subjectEntries = [
    (id: 'matematika', name: 'Matematika'),
    (id: 'ona_tili', name: 'Ona tili'),
    (id: 'adabiyot', name: 'Adabiyot'),
    (id: 'ingliz_tili', name: 'Ingliz tili'),
    (id: 'tarix', name: 'Tarix'),
    (id: 'geografiya', name: 'Geografiya'),
    (id: 'biologiya', name: 'Biologiya'),
    (id: 'kimyo', name: 'Kimyo'),
    (id: 'fizika', name: 'Fizika'),
    (id: 'informatika', name: 'Informatika'),
  ];

  static List<String> get subjectIds =>
      subjectEntries.map((e) => e.id).toList(growable: false);

  /// Katalog fanining nomi; o‘qituvchi qo‘shgan fanlar uchun `null`.
  static String? catalogSubjectName(String subjectId) {
    for (final e in subjectEntries) {
      if (e.id == subjectId) return e.name;
    }
    return null;
  }

  /// `classId` bo‘yicha kontekst: masalan `9` → `9-sinf` (raqamli sinflar).
  static String gradeContextLabel(String classId) {
    final t = classId.trim();
    if (t.isEmpty) return '';
    if (RegExp(r'^\d+$').hasMatch(t)) return '$t-sinf';
    return t;
  }

  static List<SubjectModel> get subjects => subjectEntries
      .map(
        (e) => SubjectModel(
          id: e.id,
          teacherId: systemTeacherId,
          name: e.name,
        ),
      )
      .toList(growable: false);

  /// 5–11 sinflar.
  static List<ClassModel> get defaultGrades => List<ClassModel>.generate(
        7,
        (i) {
          final n = 5 + i;
          return ClassModel(id: '$n', name: '$n-sinf');
        },
        growable: false,
      );

  static bool isCurriculumSubject(String subjectId) =>
      subjectIds.contains(subjectId);

  /// Mavzular: fan bo'yicha; Informatika — O'zbekiston o'rta maktab dasturi bo'yicha sinfga bog'liq.
  static List<TopicModel> topicsFor(String subjectId, String classId) {
    if (subjectId == 'informatika') {
      final bases = _informatikaTopicsByClass[classId];
      if (bases != null && bases.isNotEmpty) {
        return _topicModelsFromBases(subjectId, classId, bases);
      }
      return _topicModelsFromBases(
        subjectId,
        classId,
        _informatikaTopics9,
      );
    }
    final bases = _topicBases[subjectId] ?? _genericBases;
    return _topicModelsFromBases(subjectId, classId, bases);
  }

  static List<TopicModel> _topicModelsFromBases(
    String subjectId,
    String classId,
    List<String> bases,
  ) {
    return List<TopicModel>.generate(
      bases.length,
      (i) => TopicModel(
        id: 'cur_${subjectId}_${classId}_$i',
        name: '$classId-sinf: ${bases[i]}',
      ),
      growable: false,
    );
  }

  static const List<String> _genericBases = [
    '1-mavzu',
    '2-mavzu',
    '3-mavzu',
    '4-mavzu',
    '5-mavzu',
    '6-mavzu',
  ];

  static const Map<String, List<String>> _topicBases = {
    'matematika': [
      'Natural sonlar va kasrlar',
      'Algebraik ifodalar',
      'Tenglamalar va tengsizliklar',
      'Geometriya',
      'Funksiyalar va grafiklar',
      'Masalalar yig\'indisi',
    ],
    'ona_tili': [
      'So\'z boyligi',
      'Grammatika',
      'Matn tahlili',
      'Ijodiy yozish',
      'Nutq madaniyati',
      'Adabiyotdan parchalar',
    ],
    'adabiyot': [
      'Nazm va she\'riyat',
      'Nasr asarlari',
      'Adabiyot tarixi',
      'Ijodiy tahlil',
      'Qahramonlar va mavzu',
      'Mustaqil o\'qish',
    ],
    'ingliz_tili': [
      'Grammar',
      'Vocabulary',
      'Reading',
      'Writing',
      'Listening',
      'Speaking',
    ],
    'tarix': [
      'Qadimgi dunyo tarixi',
      'O\'rta asrlar',
      'Yangi vaqtlar tarixi',
      'O\'zbekiston tarixi',
      'Manbashunoslik',
      'Xronologiya va xaritalar',
    ],
    'geografiya': [
      'Fizik geografiya',
      'Iqlim va tabiat',
      'Aholi va joylar',
      'Iqtisodiy geografiya',
      'O\'zbekiston geografiyasi',
      'Xaritachilik',
    ],
    'biologiya': [
      'Hujayra va to\'qimalar',
      'Organizmlar dunyosi',
      'Genetika',
      'Evolutsiya',
      'Ekologiya',
      'Inson anatomiyasi',
    ],
    'kimyo': [
      'Atom va molekula',
      'Kimyaviy bog\'lanish',
      'Reaksiyalar',
      'Organik kimyo',
      'Ergashmalar',
      'Hisob-kitoblar',
    ],
    'fizika': [
      'Mexanika',
      'Issiqlik va molekulyar fizika',
      'Elektr va magnit',
      'Optika',
      'Atom va yadro',
      'Laboratoriya ishlari',
    ],
  };

  /// 9-sinf: `fayllar/t-sxema/9_sinf_t_schema_full.json` dagi `topic` bilan sinxron.
  static const List<String> _informatikaTopics9 = [
    'Kompyuter tizimlari va ularning tarkibi',
    'Kiritish qurilmalari',
    'Chiqarish qurilmalari',
    'Xotira qurilmalari',
    'Kompyuterning ishlash prinsipi',
    'Operatsion tizimlar',
    'Fayllar va papkalar bilan ishlash',
    'Fayl tizimi',
    'Axborot xavfsizligi',
    'Kompyuter viruslari',
    'Kompyuter tarmoqlari',
    'Lokal va global tarmoqlar',
    'Internet xizmatlari',
    'Elektron pochta',
    'Veb-saytlar va brauzerlar',
    'Qidiruv tizimlari',
    'Grafika bilan ishlash',
    'Hujjatlar bilan ishlash',
    'Elektron jadvallar',
    'Taqdimotlar',
    'Veb-sahifa yaratish',
  ];

  /// 10–11-sinf: `fayllar/t-sxema/10_11_sinf_t_schema_full.json` dagi `topic` bilan sinxron.
  static const List<String> _informatikaTopics10_11 = [
    'Bilimlar bazasi',
    'Dasturiy ta\'minot',
    'Tizim boshqaruvi',
    'Axborot xavfsizligi',
    'Raqamli tengsizlik',
    'Kompyuter tarmoqlari',
    'Ekspert tizimlar',
    'Elektron jadvallar',
    'Ma\'lumotlar bazasi',
    'Multimedia tahrirlash',
    'Sun\'iy intellekt',
    'ITning jamiyatga ta\'siri',
    'Internet texnologiyalari',
    'Loyiha boshqaruvi',
    'Tizim hayotiy sikli',
    'Grafik dizayn',
    'Animatsiya',
    'Mail merge',
    'Veb dasturlash',
  ];

  /// Informatika: sinf bo'yicha mavzular (nomda sinf prefiksi `topicsFor` orqali qo'shiladi).
  static const Map<String, List<String>> _informatikaTopicsByClass = {
    '5': [
      'Matnli hujjat bilan ishlash',
      'Tasvirlar bilan ishlash',
      'Diagrammalar bilan ishlash',
      'Dasturlashni boshlash',
      'Qidiruv tizimlarida ishlash',
      'Elektron pochtada ishlash',
    ],
    '6': [
      'Matnli hujjatlar bilan ishlash',
      'Grafika bilan ishlash',
      'Elektron jadvallar bilan ishlash',
      'Ma\'lumotlar bazasi bilan ishlash',
      'Dasturlashni o\'rganish',
      'Internetda ishlashni o\'rganish',
      'Elektron pochtadan foydalanishni o\'rganish',
      'Multimedia bilan ishlash',
    ],
    '7': [
      'Matnli hujjatlardan maqsadli foydalanish',
      'Multimediadan maqsadli foydalanish',
      'Elektron jadvallardan maqsadli foydalanish',
      'Ma\'lumotlar bazasidan maqsadli foydalanish',
    ],
    '8': [
      'Maqsadni amalga oshirishda dasturlashdan foydalanish',
      'Maqsadni amalga oshirish uchun veb-sayt dizaynini yaratish',
      'Kompyuter tarmoqlaridan maqsadli foydalanish',
      'Maqsadni amalga oshirish uchun video yoki animatsiya',
      '1-bob. Kompyuter tizimining turlari va komponentlari',
      '2-bob. Kiritish va chiqarish qurilmalari',
      '3-bob. Xotira qurilmalari va ma\'lumot almashish vositalari',
      '4-bob. Kompyuter tarmoqlari va ulardan foydalanish',
      '5-bob. Axborot texnologiyalarining ta\'siri',
      '6-bob. AKTni tadbiq etish',
      '7-bob. Tizimning hayot davri',
      '8-bob. Xavfsizlik texnikasi qoidalari',
      '9-bob. Auditoriya',
      '10-bob. Kommunikatsiya',
      '11-bob. Fayllar boshqaruvi',
      '12-bob. Tasvirlar',
      '13-bob. Loyihalash',
      '14-bob. Uslublar',
      '15-bob. Xatolarni tekshirish',
      '16-bob. Grafik va xaritalar',
      '17-bob. Hujjatlar bilan ishlash',
      '18-bob. Ma\'lumotlarni boshqarish',
      '19-bob. Taqdimot',
      '20-bob. Ma\'lumotlar tahlili',
      '21-bob. Veb-saytlar yaratish',
    ],
    '9': _informatikaTopics9,
    '10': _informatikaTopics10_11,
    '11': _informatikaTopics10_11,
  };
}
