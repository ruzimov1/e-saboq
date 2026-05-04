// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'e-Saboq';

  @override
  String get loginTitle => 'Kirish';

  @override
  String get registerTitle => 'Ro\'yxatdan o\'tish';

  @override
  String get joinByCode => 'Kod bilan kirish';

  @override
  String get myAssignments => 'Mening topshiriqlarim';

  @override
  String get assignments => 'Topshiriqlar';

  @override
  String get assignmentResults => 'Natijalar';

  @override
  String get noSubmissionsYet => 'Hali javob yo\'q';

  @override
  String get subjects => 'Fanlar';

  @override
  String get save => 'Saqlash';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get delete => 'O\'chirish';

  @override
  String get networkOffline =>
      'Tarmoq yo\'q — ma\'lumotlar keshdan ko\'rinishi mumkin';

  @override
  String get networkOnline => 'Tarmoq ulandi';

  @override
  String get submissionStatusSubmitted => 'Yuborilgan';

  @override
  String get submissionStatusReviewed => 'Ko\'rib chiqilgan';

  @override
  String get submissionStatusReturned => 'Qaytarilgan';

  @override
  String get teacherComment => 'O\'qituvchi izohi';

  @override
  String get reviewSave => 'Baholashni saqlash';

  @override
  String get exportCsv => 'CSV nusxa';

  @override
  String get csvCopied => 'CSV buferga nusxalandi';

  @override
  String get rubricLabel => 'Baholash mezonlari (o\'quvchiga ko\'rinadi)';

  @override
  String get teacherNotesLabel =>
      'Ichki eslatma (faqat o\'qituvchi, o\'quvchiga ko\'rinmaydi)';

  @override
  String get groupWorkOptional => 'Guruh topshirig\'i (keyingi bosqich, belgi)';

  @override
  String get draftSaved => 'Qoralama saqlandi';

  @override
  String get viewAnswer => 'Javobni ko\'rish';

  @override
  String statsAssignments(int total, int active, int closed) {
    return 'Topshiriqlar: $total · Faol: $active · Yakunlangan: $closed';
  }

  @override
  String avgQuizScore(String score) {
    return 'Quiz o\'rtacha: $score';
  }

  @override
  String get noAvgQuiz => 'Quiz balli hali yo\'q';

  @override
  String get aiReviewTooltip => 'AI tahlil';

  @override
  String get aiReviewTitle => 'Sun\'iy intellekt yordamchisi';

  @override
  String get aiReviewLoading => 'Tahlil yuborilmoqda…';

  @override
  String get aiKeyMissing =>
      'Gemini kalit yo\'q: .env fayliga GEMINI_API_KEY= qo\'shing (aistudio.google.com/apikey)';

  @override
  String get aiDisclaimer =>
      'AI faqat yordam beradi; yakuniy baho o\'qituvchining qarorida.';

  @override
  String get aiSaveToSubmission => 'Natijaga saqlash';

  @override
  String get aiFeedbackSaved => 'AI tahlili saqlandi';

  @override
  String get aiFeedbackLabel => 'AI tahlili';

  @override
  String get registerSubtitle => 'Yangi hisob yarating';

  @override
  String get resultsFilterAll => 'Barchasi';

  @override
  String get resultsFilterSubmitted => 'Yuborilgan';

  @override
  String get resultsFilterReviewed => 'Ko\'rib chiqilgan';

  @override
  String get resultsFilterReturned => 'Qaytarilgan';

  @override
  String get resultsFilterNoGrade => 'Baho qo\'yilmagan';

  @override
  String get resultsDateRangePick => 'Sana oralig\'i';

  @override
  String get resultsClearDateRange => 'Sanani tozalash';

  @override
  String get resultsNoMatchesFilter =>
      'Tanlangan filtr bo\'yicha natija topilmadi.';

  @override
  String get brainstormIdeaFeedEmpty =>
      'Hozircha fikr yo\'q. O\'quvchilar yuborsa, stikerlar bu yerda ko\'rinadi. Nomuvofiq fikrni o\'chirish yoki har bir fikrga baho va izoh berishingiz mumkin.';

  @override
  String get assignmentUntitled => 'Topshiriq';

  @override
  String get reviewStatusFieldLabel => 'Holat';

  @override
  String get resultsAnswerHeading => 'Javob';

  @override
  String resultsQuizPercent(String percent) {
    return 'Test: $percent%';
  }

  @override
  String resultsGrade10Chip(String grade) {
    return 'Baho: $grade/10';
  }

  @override
  String get brainstormTabStudents => 'O\'quvchilar';

  @override
  String get brainstormTabIdeaFeed => 'Fikrlar oqimi';

  @override
  String get resultsAssignmentRouteMissing =>
      'Topshiriq tanlanmagan (marshrut).';

  @override
  String get brainstormDeleteIdeaTitle => 'Fikrni o\'chirish';

  @override
  String get brainstormDeleteIdeaBody =>
      'Ushbu fikr oqimdan olib tashlansinmi? Javob ro\'yxatidagi yuborish o\'zgarmaydi — faqat stiker oqimi.';

  @override
  String get brainstormIdeaGradeDialogTitle => 'Fikr — baho va izoh';

  @override
  String get gradeOutOfTenTitle => 'Baho (0–10)';

  @override
  String brainstormAvgGrade(String avg) {
    return 'O\'rtacha baho: $avg/10';
  }

  @override
  String get brainstormAvgGradeNone => 'O\'rtacha baho: hali yo\'q';

  @override
  String get brainstormEditGradeComment => 'Baho va izoh';

  @override
  String brainstormStudentLine(String name) {
    return 'O\'quvchi: $name';
  }

  @override
  String brainstormCommentLine(String text) {
    return 'Izoh: $text';
  }

  @override
  String get brainstormIdeaDeleted => 'Fikr olib tashlandi';

  @override
  String get studentListLoginPrompt =>
      'Ro\'yxatni ko\'rish uchun tizimga kiring.';

  @override
  String get studentBulkDeleteSelectedTitle => 'Tanlanganlarni o\'chirish';

  @override
  String studentBulkDeleteSelectedMessage(int count) {
    return '$count ta element o\'chirilsinmi? Guruhdan kelganlar ro\'yxatdan olib tashlanadi, yuborilgan javoblar butunlay o\'chiriladi.';
  }

  @override
  String get studentBulkDeleteAllTitle => 'Barchasini o\'chirish';

  @override
  String studentBulkDeleteAllMessage(int total) {
    return 'Guruh zahirasidagi $total ta yozuv o\'chiriladi (bajarishdagi + barcha yuborilgan javoblar). Davom etsinmi?';
  }

  @override
  String get studentBulkDeleteNothingToRemove =>
      'O\'chirish uchun element yo\'q';

  @override
  String studentBulkDeletedPartial(int failed) {
    return 'Ba\'zi elementlar o\'chirilmadi ($failed ta)';
  }

  @override
  String get studentBulkDeletedOk => 'O\'chirildi';

  @override
  String studentBulkDeleteAllError(int failed) {
    return 'Xato: $failed ta o\'chirilmadi';
  }

  @override
  String get studentBulkDeletedAllOk => 'Barchasi o\'chirildi';

  @override
  String get studentSelectItems => 'Tanlang';

  @override
  String studentSelectedCount(int count) {
    return '$count ta tanlandi';
  }

  @override
  String get studentDeleteViaSelection => 'Tanlash orqali o\'chirish';

  @override
  String get studentDeleteEverything => 'Hammasini o\'chirish';

  @override
  String get studentDeleteDialogTitle => 'O\'chirish';

  @override
  String get studentAssignmentsEmptyHint =>
      'Hali topshiriq yo\'q. Topshiriq yoki guruh kodi bilan qo\'shiling.';

  @override
  String get studentGroupInboxSection => 'Guruhdan (bajarish)';

  @override
  String get studentSubmittedSection => 'Yuborilgan';

  @override
  String studentCodeLine(String code) {
    return 'Kod: $code';
  }

  @override
  String get studentMetaScore => 'Ball';

  @override
  String studentMetaTeacherGrade10(int n) {
    return 'O\'qituvchi: $n/10';
  }

  @override
  String get studentSubmissionHasFeedbackNote => '(baho, izoh yoki tahlil bor)';

  @override
  String get studentSubmissionScreenTitle => 'Yuborilgan javob';

  @override
  String get studentDetailLoginForAnswer =>
      'Javobni ko\'rish uchun tizimga kiring.';

  @override
  String get studentSubmissionMissing =>
      'Yuborilgan javob topilmadi (o\'chirilgan bo\'lishi mumkin).';

  @override
  String studentDetailSubmittedAt(String when) {
    return 'Yuborilgan: $when';
  }

  @override
  String get studentDetailStatusLabel => 'Holat';

  @override
  String studentDetailQuizPointsSuffix(String points) {
    return ' · $points ball';
  }

  @override
  String get studentYourAnswer => 'Sizning javobingiz';

  @override
  String get studentYourAnswers => 'Sizning javoblaringiz';

  @override
  String get studentMethodLoadError => 'Metod tafsilotlari yuklanmadi.';

  @override
  String get studentQuizNotConfigured => 'Quiz savollari saqlanmagan.';

  @override
  String get studentPollAnswerHeading => 'So\'rovnoma javobi';

  @override
  String get studentAssignmentSectionTitle => 'Topshiriq';

  @override
  String studentTeacherOverallGrade10(int n) {
    return 'O\'qituvchi umumiy bahosi: $n/10';
  }

  @override
  String get studentBrainstormTeacherPerIdea => 'O\'qituvchi: har bir fikr';

  @override
  String get studentBrainstormTeacherPerIdeaHint =>
      'Aqliy hujumda har bir fikr uchun alohida baho va izoh bu yerda ko\'rinadi (o\'qituvchi yuborgach).';

  @override
  String get studentBrainstormIdeasMissingNote =>
      'Fikr yozuvlari topilmadi (eski yuborish yoki tizim). Yuqorida saqlangan javob ko\'rsatilgan.';

  @override
  String get studentBrainstormNoTeacherGradeYet =>
      'Hozircha o\'qituvchi bahosi kiritilmagan.';

  @override
  String get studentAnswerShownAbove => '(Yuqorida ko\'rsatilgan)';

  @override
  String get studentQuizCorrect => 'To\'g\'ri';

  @override
  String studentQuizCorrectOption(String answer) {
    return 'To\'g\'ri variant: $answer';
  }

  @override
  String get studentQuizPrevious => 'Oldingi';

  @override
  String get studentQuizNext => 'Keyingi';

  @override
  String get studentQuizTimeElapsed => 'Tugadi';

  @override
  String get studentMethodCaseScenario => 'Vaziyat (case-study)';

  @override
  String get studentMethodBrainstormPrompt => 'Savol';

  @override
  String get studentMethodBrainstormGuide => 'Yo\'riqnoma';

  @override
  String get studentMethodRoleRoles => 'Rollar';

  @override
  String get studentMethodRoleScenario => 'Vaziyat';

  @override
  String get studentMethodFishboneDiagram => 'T-sxema';

  @override
  String get studentMethodFishboneCenter => 'Markaz';

  @override
  String get studentMethodFishboneBranches => 'Tahlil';

  @override
  String get studentMethodGroupInstructions => 'Ko\'rsatma';

  @override
  String get caseStudyScenarioSavedSnack => 'Ssenariy metodga saqlandi';

  @override
  String get caseStudySolutionKeySavedSnack => 'Yechim kaliti saqlandi';

  @override
  String get caseStudyReviewCompareSubtitle =>
      'Yonma-yon: o\'quvchi javobi · namunaviy yechim';

  @override
  String get caseStudyPanelStudent => 'O\'quvchi';

  @override
  String get caseStudyPanelReference => 'Namunaviy (yechim kaliti)';

  @override
  String get caseStudyQuickGrade => 'Tezkor baho';

  @override
  String caseStudyStarTooltipPoints(int points) {
    return '$points ball';
  }

  @override
  String caseStudyExactScore(int n) {
    return 'Aniq bal: $n / 10';
  }

  @override
  String get caseStudyCommentHint =>
      'Matnli izoh (ovozli yozuv — keyingi bosqich)';

  @override
  String get caseStudyNoProbeSelections => 'Tanlovlar hali yo\'q';

  @override
  String get caseStudyHeatmapEmpty =>
      'Tanlovlar statistikasi hali yo\'q (yoki taassurof tanlovlari bo\'lmagan javoblar).';

  @override
  String get caseStudyHeatmapTitle => 'Tanlovlar heatmap';

  @override
  String get caseStudyMethodNotSelected => 'Metod tanlanmagan';

  @override
  String get caseStudyNoAssignments => 'Bu metod uchun topshiriqlar yo\'q';

  @override
  String get caseStudyAssignmentPickerLabel => 'Topshiriq';

  @override
  String get caseStudyVisualAnalysisTitle => 'Vizual tahlil';

  @override
  String get caseStudyVisualAnalysisSubtitle =>
      'Quyidagi ko\'rsatkichlar tanlangan topshiriq bo\'yicha real vaqtda yangilanadi (heatmap, xavfsiz yo\'l ulushi, ogohlantirishlar).';

  @override
  String caseStudyDeadEndWarning(int count) {
    return 'Ogohlantirish: $count ta javobda so\'nggi tanlov noto\'g\'ri (mantiqiy berk yo\'l ehtimoli)';
  }

  @override
  String get caseStudyAllProbesCorrectTitle =>
      'Sinf bo\'yicha: barcha tanlovlar to\'g\'ri';

  @override
  String caseStudyScenarioAnswerShare(String percent) {
    return '$percent% · taassurof javoblari';
  }

  @override
  String get caseStudyNoSubmissionsYet => 'Hali yuborishlar yo\'q';

  @override
  String get caseStudyColTime => 'Vaqt';

  @override
  String get caseStudyColStages => 'Bosqichlar';

  @override
  String get caseStudyColWarning => 'Ogohlantirish';

  @override
  String get caseStudyColGrade => 'Baho';

  @override
  String get caseStudyColActions => ' ';

  @override
  String get caseStudyCatalogSearchLabel => 'Mavzu qidiruv (barcha sinflar)';

  @override
  String get caseStudyJsonBankHint =>
      'JSON bankidan tanlang · tartibni Drag-and-drop bilan o\'zgartiring';

  @override
  String get caseStudyEditOrderTitle => 'Tahrir (tartib)';

  @override
  String get caseStudyClear => 'Tozalash';

  @override
  String get caseStudySaveFirstBandScenario =>
      'Birinchi bandni ssenariy sifatida saqlash';

  @override
  String get caseStudySaveAllBandsScenario =>
      'Barcha bandlarni ssenariyga (birlashtirilgan)';

  @override
  String get caseStudyInteractiveScenarioMissing =>
      'Bu mavzuda interaktiv ssenariy topilmadi';

  @override
  String get caseStudySaveInteractiveScenario =>
      'Interaktiv ssenariyni saqlash';

  @override
  String get caseStudySaveSolutionOrder =>
      'Tartib — yechim kaliti (ketma-ketlik)';

  @override
  String get caseStudyAppBarPanel => 'Case-study panel';

  @override
  String get caseStudyNoMethodParams => 'Metod parametrlari yo\'q';

  @override
  String get caseStudyAppBarDashboard => 'Case-study · boshqaruv paneli';

  @override
  String get caseStudyNavMonitoring => 'Monitoring';

  @override
  String get caseStudyNavConstructor => 'Konstruktor';

  @override
  String get caseStudyNavAnalysis => 'Tahlil';

  @override
  String get csvColDisplayName => 'display_name';

  @override
  String get csvColStudentId => 'student_id';

  @override
  String get csvColSubmittedAt => 'submitted_at';

  @override
  String get csvColScore => 'score';

  @override
  String get csvColGrade10 => 'grade10';

  @override
  String get csvColReviewStatus => 'review_status';

  @override
  String get csvColTeacherComment => 'teacher_comment';

  @override
  String get csvColAiFeedback => 'ai_feedback';

  @override
  String get csvColAnswerText => 'answer_text';

  @override
  String get actionRetry => 'Qayta urinish';

  @override
  String get joinSnackLoginForAssignment =>
      'Avval «Kirish» — topshiriq kodi tizimda ishlatiladi.';

  @override
  String get joinSnackEnterCode => 'Kod kiriting';

  @override
  String get joinSnackCodeInvalid => 'Kod topilmadi yoki noto\'g\'ri';

  @override
  String get joinSnackLoginForGroup =>
      'Guruhga qo\'shilish uchun tizimga kiring.';

  @override
  String get joinSnackGroupStudentOnly => 'Guruh a\'zoligi o\'quvchilar uchun.';

  @override
  String get joinSnackEnterGroupCode => 'Guruh kodini kiriting';

  @override
  String get joinSnackGroupJoined =>
      'Guruhga qo\'shildingiz. «Mening topshiriqlarim» ni oching.';

  @override
  String get joinTabAssignmentCode => 'Topshiriq kodi';

  @override
  String get joinTabGroupCode => 'Guruh kodi';

  @override
  String get joinLoginCardTitle => 'Tizimga kiring';

  @override
  String get joinLoginCardSubtitleAssignment =>
      'Topshiriq kodi yuborilgach ochiladi.';

  @override
  String get joinAssignmentIntro =>
      'O\'qituvchi bergan topshiriq kodini kiriting (masalan: XK7F2). Kod nusxalanganda oraliq bo\'shliqlar e\'tiborsiz yechiladi.';

  @override
  String get joinTeacherPreviewTitle => 'O\'qituvchi rejimi';

  @override
  String get joinTeacherPreviewSubtitle =>
      'Kod orqali topshiriqni ko\'rush mumkin. Javob yuborish o\'quvchilar uchun.';

  @override
  String get joinFieldAssignmentCode => 'Topshiriq kodi';

  @override
  String get joinFieldAssignmentHint => 'Masalan: XK7F2';

  @override
  String get joinOpenAssignment => 'Topshiriqqa o\'tish';

  @override
  String get joinGroupIntro =>
      'O\'qituvchi bergan guruh kirish kodini kiriting. Keyin sizga shu guruh orqali topshiriqlar «Mening topshiriqlarim» da ko\'rinadi.';

  @override
  String get joinStudentOnlyCardTitle => 'Avval o\'quvchi sifatida kiring';

  @override
  String get joinFieldGroupCode => 'Guruh kodi';

  @override
  String get joinFieldGroupHint => '6 belgi';

  @override
  String get joinGroupSubmit => 'Guruhga qo\'shilish';

  @override
  String get firebaseErrorIndexBuilding =>
      'Firestore so\'rovi uchun indeks yaratilmoqda yoki kerak. Bir necha daqiqadan so\'ng qayta urinib ko\'ring; o\'qituvchidan `firebase deploy --only firestore:indexes` bajarilganini tekshiring.';

  @override
  String get firebaseErrorPermissionStudent =>
      'Ruxsat rad etildi. Avval o\'quvchi sifatida tizimga kiring.';

  @override
  String get forgotPasswordTitle => 'Parolni tiklash';

  @override
  String get forgotPasswordBody =>
      'Loginni kiriting. Tizim Firebase orqali tiklash havolasini yuborishga harakat qiladi (pochta sozlamalari qarab).';

  @override
  String get forgotPasswordLoginField => 'Login';

  @override
  String get forgotPasswordSubmit => 'Yuborish';

  @override
  String get forgotPasswordSent =>
      'So\'rov yuborildi. Agar xat kelmasa, Firebase Console va email domenini tekshiring.';

  @override
  String get teacherClassDeleteTitle => 'Sinfni o\'chirish';

  @override
  String teacherClassDeleteMessage(String name) {
    return '\"$name\" va uning ostidagi mavzular, metodlar va topshiriqlar butunlay o\'chiriladi.';
  }

  @override
  String get teacherClassDeleted => 'Sinf o\'chirildi';

  @override
  String get teacherMethodDeleteTitle => 'Metodni o\'chirish';

  @override
  String teacherMethodDeleteMessage(String name) {
    return '\"$name\" va unga bog\'langan topshiriqlar butunlay o\'chiriladi.';
  }

  @override
  String get teacherMethodDeleted => 'Metod o\'chirildi';
}
