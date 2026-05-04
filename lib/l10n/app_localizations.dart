import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In uz, this message translates to:
  /// **'e-Saboq'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get registerTitle;

  /// No description provided for @joinByCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod bilan kirish'**
  String get joinByCode;

  /// No description provided for @myAssignments.
  ///
  /// In uz, this message translates to:
  /// **'Mening topshiriqlarim'**
  String get myAssignments;

  /// No description provided for @assignments.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriqlar'**
  String get assignments;

  /// No description provided for @assignmentResults.
  ///
  /// In uz, this message translates to:
  /// **'Natijalar'**
  String get assignmentResults;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hali javob yo\'q'**
  String get noSubmissionsYet;

  /// No description provided for @subjects.
  ///
  /// In uz, this message translates to:
  /// **'Fanlar'**
  String get subjects;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get delete;

  /// No description provided for @networkOffline.
  ///
  /// In uz, this message translates to:
  /// **'Tarmoq yo\'q — ma\'lumotlar keshdan ko\'rinishi mumkin'**
  String get networkOffline;

  /// No description provided for @networkOnline.
  ///
  /// In uz, this message translates to:
  /// **'Tarmoq ulandi'**
  String get networkOnline;

  /// No description provided for @submissionStatusSubmitted.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgan'**
  String get submissionStatusSubmitted;

  /// No description provided for @submissionStatusReviewed.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rib chiqilgan'**
  String get submissionStatusReviewed;

  /// No description provided for @submissionStatusReturned.
  ///
  /// In uz, this message translates to:
  /// **'Qaytarilgan'**
  String get submissionStatusReturned;

  /// No description provided for @teacherComment.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi izohi'**
  String get teacherComment;

  /// No description provided for @reviewSave.
  ///
  /// In uz, this message translates to:
  /// **'Baholashni saqlash'**
  String get reviewSave;

  /// No description provided for @exportCsv.
  ///
  /// In uz, this message translates to:
  /// **'CSV nusxa'**
  String get exportCsv;

  /// No description provided for @csvCopied.
  ///
  /// In uz, this message translates to:
  /// **'CSV buferga nusxalandi'**
  String get csvCopied;

  /// No description provided for @rubricLabel.
  ///
  /// In uz, this message translates to:
  /// **'Baholash mezonlari (o\'quvchiga ko\'rinadi)'**
  String get rubricLabel;

  /// No description provided for @teacherNotesLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ichki eslatma (faqat o\'qituvchi, o\'quvchiga ko\'rinmaydi)'**
  String get teacherNotesLabel;

  /// No description provided for @groupWorkOptional.
  ///
  /// In uz, this message translates to:
  /// **'Guruh topshirig\'i (keyingi bosqich, belgi)'**
  String get groupWorkOptional;

  /// No description provided for @draftSaved.
  ///
  /// In uz, this message translates to:
  /// **'Qoralama saqlandi'**
  String get draftSaved;

  /// No description provided for @viewAnswer.
  ///
  /// In uz, this message translates to:
  /// **'Javobni ko\'rish'**
  String get viewAnswer;

  /// No description provided for @statsAssignments.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriqlar: {total} · Faol: {active} · Yakunlangan: {closed}'**
  String statsAssignments(int total, int active, int closed);

  /// No description provided for @avgQuizScore.
  ///
  /// In uz, this message translates to:
  /// **'Quiz o\'rtacha: {score}'**
  String avgQuizScore(String score);

  /// No description provided for @noAvgQuiz.
  ///
  /// In uz, this message translates to:
  /// **'Quiz balli hali yo\'q'**
  String get noAvgQuiz;

  /// No description provided for @aiReviewTooltip.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlil'**
  String get aiReviewTooltip;

  /// No description provided for @aiReviewTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sun\'iy intellekt yordamchisi'**
  String get aiReviewTitle;

  /// No description provided for @aiReviewLoading.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil yuborilmoqda…'**
  String get aiReviewLoading;

  /// No description provided for @aiKeyMissing.
  ///
  /// In uz, this message translates to:
  /// **'Gemini kalit yo\'q: .env fayliga GEMINI_API_KEY= qo\'shing (aistudio.google.com/apikey)'**
  String get aiKeyMissing;

  /// No description provided for @aiDisclaimer.
  ///
  /// In uz, this message translates to:
  /// **'AI faqat yordam beradi; yakuniy baho o\'qituvchining qarorida.'**
  String get aiDisclaimer;

  /// No description provided for @aiSaveToSubmission.
  ///
  /// In uz, this message translates to:
  /// **'Natijaga saqlash'**
  String get aiSaveToSubmission;

  /// No description provided for @aiFeedbackSaved.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlili saqlandi'**
  String get aiFeedbackSaved;

  /// No description provided for @aiFeedbackLabel.
  ///
  /// In uz, this message translates to:
  /// **'AI tahlili'**
  String get aiFeedbackLabel;

  /// No description provided for @registerSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi hisob yarating'**
  String get registerSubtitle;

  /// No description provided for @resultsFilterAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get resultsFilterAll;

  /// No description provided for @resultsFilterSubmitted.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgan'**
  String get resultsFilterSubmitted;

  /// No description provided for @resultsFilterReviewed.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rib chiqilgan'**
  String get resultsFilterReviewed;

  /// No description provided for @resultsFilterReturned.
  ///
  /// In uz, this message translates to:
  /// **'Qaytarilgan'**
  String get resultsFilterReturned;

  /// No description provided for @resultsFilterNoGrade.
  ///
  /// In uz, this message translates to:
  /// **'Baho qo\'yilmagan'**
  String get resultsFilterNoGrade;

  /// No description provided for @resultsDateRangePick.
  ///
  /// In uz, this message translates to:
  /// **'Sana oralig\'i'**
  String get resultsDateRangePick;

  /// No description provided for @resultsClearDateRange.
  ///
  /// In uz, this message translates to:
  /// **'Sanani tozalash'**
  String get resultsClearDateRange;

  /// No description provided for @resultsNoMatchesFilter.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan filtr bo\'yicha natija topilmadi.'**
  String get resultsNoMatchesFilter;

  /// No description provided for @brainstormIdeaFeedEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha fikr yo\'q. O\'quvchilar yuborsa, stikerlar bu yerda ko\'rinadi. Nomuvofiq fikrni o\'chirish yoki har bir fikrga baho va izoh berishingiz mumkin.'**
  String get brainstormIdeaFeedEmpty;

  /// No description provided for @assignmentUntitled.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq'**
  String get assignmentUntitled;

  /// No description provided for @reviewStatusFieldLabel.
  ///
  /// In uz, this message translates to:
  /// **'Holat'**
  String get reviewStatusFieldLabel;

  /// No description provided for @resultsAnswerHeading.
  ///
  /// In uz, this message translates to:
  /// **'Javob'**
  String get resultsAnswerHeading;

  /// No description provided for @resultsQuizPercent.
  ///
  /// In uz, this message translates to:
  /// **'Test: {percent}%'**
  String resultsQuizPercent(String percent);

  /// No description provided for @resultsGrade10Chip.
  ///
  /// In uz, this message translates to:
  /// **'Baho: {grade}/10'**
  String resultsGrade10Chip(String grade);

  /// No description provided for @brainstormTabStudents.
  ///
  /// In uz, this message translates to:
  /// **'O\'quvchilar'**
  String get brainstormTabStudents;

  /// No description provided for @brainstormTabIdeaFeed.
  ///
  /// In uz, this message translates to:
  /// **'Fikrlar oqimi'**
  String get brainstormTabIdeaFeed;

  /// No description provided for @resultsAssignmentRouteMissing.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq tanlanmagan (marshrut).'**
  String get resultsAssignmentRouteMissing;

  /// No description provided for @brainstormDeleteIdeaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Fikrni o\'chirish'**
  String get brainstormDeleteIdeaTitle;

  /// No description provided for @brainstormDeleteIdeaBody.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu fikr oqimdan olib tashlansinmi? Javob ro\'yxatidagi yuborish o\'zgarmaydi — faqat stiker oqimi.'**
  String get brainstormDeleteIdeaBody;

  /// No description provided for @brainstormIdeaGradeDialogTitle.
  ///
  /// In uz, this message translates to:
  /// **'Fikr — baho va izoh'**
  String get brainstormIdeaGradeDialogTitle;

  /// No description provided for @gradeOutOfTenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Baho (0–10)'**
  String get gradeOutOfTenTitle;

  /// No description provided for @brainstormAvgGrade.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha baho: {avg}/10'**
  String brainstormAvgGrade(String avg);

  /// No description provided for @brainstormAvgGradeNone.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha baho: hali yo\'q'**
  String get brainstormAvgGradeNone;

  /// No description provided for @brainstormEditGradeComment.
  ///
  /// In uz, this message translates to:
  /// **'Baho va izoh'**
  String get brainstormEditGradeComment;

  /// No description provided for @brainstormStudentLine.
  ///
  /// In uz, this message translates to:
  /// **'O\'quvchi: {name}'**
  String brainstormStudentLine(String name);

  /// No description provided for @brainstormCommentLine.
  ///
  /// In uz, this message translates to:
  /// **'Izoh: {text}'**
  String brainstormCommentLine(String text);

  /// No description provided for @brainstormIdeaDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Fikr olib tashlandi'**
  String get brainstormIdeaDeleted;

  /// No description provided for @studentListLoginPrompt.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatni ko\'rish uchun tizimga kiring.'**
  String get studentListLoginPrompt;

  /// No description provided for @studentBulkDeleteSelectedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tanlanganlarni o\'chirish'**
  String get studentBulkDeleteSelectedTitle;

  /// No description provided for @studentBulkDeleteSelectedMessage.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta element o\'chirilsinmi? Guruhdan kelganlar ro\'yxatdan olib tashlanadi, yuborilgan javoblar butunlay o\'chiriladi.'**
  String studentBulkDeleteSelectedMessage(int count);

  /// No description provided for @studentBulkDeleteAllTitle.
  ///
  /// In uz, this message translates to:
  /// **'Barchasini o\'chirish'**
  String get studentBulkDeleteAllTitle;

  /// No description provided for @studentBulkDeleteAllMessage.
  ///
  /// In uz, this message translates to:
  /// **'Guruh zahirasidagi {total} ta yozuv o\'chiriladi (bajarishdagi + barcha yuborilgan javoblar). Davom etsinmi?'**
  String studentBulkDeleteAllMessage(int total);

  /// No description provided for @studentBulkDeleteNothingToRemove.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish uchun element yo\'q'**
  String get studentBulkDeleteNothingToRemove;

  /// No description provided for @studentBulkDeletedPartial.
  ///
  /// In uz, this message translates to:
  /// **'Ba\'zi elementlar o\'chirilmadi ({failed} ta)'**
  String studentBulkDeletedPartial(int failed);

  /// No description provided for @studentBulkDeletedOk.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirildi'**
  String get studentBulkDeletedOk;

  /// No description provided for @studentBulkDeleteAllError.
  ///
  /// In uz, this message translates to:
  /// **'Xato: {failed} ta o\'chirilmadi'**
  String studentBulkDeleteAllError(int failed);

  /// No description provided for @studentBulkDeletedAllOk.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi o\'chirildi'**
  String get studentBulkDeletedAllOk;

  /// No description provided for @studentSelectItems.
  ///
  /// In uz, this message translates to:
  /// **'Tanlang'**
  String get studentSelectItems;

  /// No description provided for @studentSelectedCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta tanlandi'**
  String studentSelectedCount(int count);

  /// No description provided for @studentDeleteViaSelection.
  ///
  /// In uz, this message translates to:
  /// **'Tanlash orqali o\'chirish'**
  String get studentDeleteViaSelection;

  /// No description provided for @studentDeleteEverything.
  ///
  /// In uz, this message translates to:
  /// **'Hammasini o\'chirish'**
  String get studentDeleteEverything;

  /// No description provided for @studentDeleteDialogTitle.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get studentDeleteDialogTitle;

  /// No description provided for @studentAssignmentsEmptyHint.
  ///
  /// In uz, this message translates to:
  /// **'Hali topshiriq yo\'q. Topshiriq yoki guruh kodi bilan qo\'shiling.'**
  String get studentAssignmentsEmptyHint;

  /// No description provided for @studentGroupInboxSection.
  ///
  /// In uz, this message translates to:
  /// **'Guruhdan (bajarish)'**
  String get studentGroupInboxSection;

  /// No description provided for @studentSubmittedSection.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgan'**
  String get studentSubmittedSection;

  /// No description provided for @studentCodeLine.
  ///
  /// In uz, this message translates to:
  /// **'Kod: {code}'**
  String studentCodeLine(String code);

  /// No description provided for @studentMetaScore.
  ///
  /// In uz, this message translates to:
  /// **'Ball'**
  String get studentMetaScore;

  /// No description provided for @studentMetaTeacherGrade10.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi: {n}/10'**
  String studentMetaTeacherGrade10(int n);

  /// No description provided for @studentSubmissionHasFeedbackNote.
  ///
  /// In uz, this message translates to:
  /// **'(baho, izoh yoki tahlil bor)'**
  String get studentSubmissionHasFeedbackNote;

  /// No description provided for @studentSubmissionScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgan javob'**
  String get studentSubmissionScreenTitle;

  /// No description provided for @studentDetailLoginForAnswer.
  ///
  /// In uz, this message translates to:
  /// **'Javobni ko\'rish uchun tizimga kiring.'**
  String get studentDetailLoginForAnswer;

  /// No description provided for @studentSubmissionMissing.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgan javob topilmadi (o\'chirilgan bo\'lishi mumkin).'**
  String get studentSubmissionMissing;

  /// No description provided for @studentDetailSubmittedAt.
  ///
  /// In uz, this message translates to:
  /// **'Yuborilgan: {when}'**
  String studentDetailSubmittedAt(String when);

  /// No description provided for @studentDetailStatusLabel.
  ///
  /// In uz, this message translates to:
  /// **'Holat'**
  String get studentDetailStatusLabel;

  /// No description provided for @studentDetailQuizPointsSuffix.
  ///
  /// In uz, this message translates to:
  /// **' · {points} ball'**
  String studentDetailQuizPointsSuffix(String points);

  /// No description provided for @studentYourAnswer.
  ///
  /// In uz, this message translates to:
  /// **'Sizning javobingiz'**
  String get studentYourAnswer;

  /// No description provided for @studentYourAnswers.
  ///
  /// In uz, this message translates to:
  /// **'Sizning javoblaringiz'**
  String get studentYourAnswers;

  /// No description provided for @studentMethodLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Metod tafsilotlari yuklanmadi.'**
  String get studentMethodLoadError;

  /// No description provided for @studentQuizNotConfigured.
  ///
  /// In uz, this message translates to:
  /// **'Quiz savollari saqlanmagan.'**
  String get studentQuizNotConfigured;

  /// No description provided for @studentPollAnswerHeading.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovnoma javobi'**
  String get studentPollAnswerHeading;

  /// No description provided for @studentAssignmentSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq'**
  String get studentAssignmentSectionTitle;

  /// No description provided for @studentTeacherOverallGrade10.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi umumiy bahosi: {n}/10'**
  String studentTeacherOverallGrade10(int n);

  /// No description provided for @studentBrainstormTeacherPerIdea.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi: har bir fikr'**
  String get studentBrainstormTeacherPerIdea;

  /// No description provided for @studentBrainstormTeacherPerIdeaHint.
  ///
  /// In uz, this message translates to:
  /// **'Aqliy hujumda har bir fikr uchun alohida baho va izoh bu yerda ko\'rinadi (o\'qituvchi yuborgach).'**
  String get studentBrainstormTeacherPerIdeaHint;

  /// No description provided for @studentBrainstormIdeasMissingNote.
  ///
  /// In uz, this message translates to:
  /// **'Fikr yozuvlari topilmadi (eski yuborish yoki tizim). Yuqorida saqlangan javob ko\'rsatilgan.'**
  String get studentBrainstormIdeasMissingNote;

  /// No description provided for @studentBrainstormNoTeacherGradeYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha o\'qituvchi bahosi kiritilmagan.'**
  String get studentBrainstormNoTeacherGradeYet;

  /// No description provided for @studentAnswerShownAbove.
  ///
  /// In uz, this message translates to:
  /// **'(Yuqorida ko\'rsatilgan)'**
  String get studentAnswerShownAbove;

  /// No description provided for @studentQuizCorrect.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri'**
  String get studentQuizCorrect;

  /// No description provided for @studentQuizCorrectOption.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri variant: {answer}'**
  String studentQuizCorrectOption(String answer);

  /// No description provided for @studentQuizPrevious.
  ///
  /// In uz, this message translates to:
  /// **'Oldingi'**
  String get studentQuizPrevious;

  /// No description provided for @studentQuizNext.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi'**
  String get studentQuizNext;

  /// No description provided for @studentQuizTimeElapsed.
  ///
  /// In uz, this message translates to:
  /// **'Tugadi'**
  String get studentQuizTimeElapsed;

  /// No description provided for @studentMethodCaseScenario.
  ///
  /// In uz, this message translates to:
  /// **'Vaziyat (case-study)'**
  String get studentMethodCaseScenario;

  /// No description provided for @studentMethodBrainstormPrompt.
  ///
  /// In uz, this message translates to:
  /// **'Savol'**
  String get studentMethodBrainstormPrompt;

  /// No description provided for @studentMethodBrainstormGuide.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'riqnoma'**
  String get studentMethodBrainstormGuide;

  /// No description provided for @studentMethodRoleRoles.
  ///
  /// In uz, this message translates to:
  /// **'Rollar'**
  String get studentMethodRoleRoles;

  /// No description provided for @studentMethodRoleScenario.
  ///
  /// In uz, this message translates to:
  /// **'Vaziyat'**
  String get studentMethodRoleScenario;

  /// No description provided for @studentMethodFishboneDiagram.
  ///
  /// In uz, this message translates to:
  /// **'T-sxema'**
  String get studentMethodFishboneDiagram;

  /// No description provided for @studentMethodFishboneCenter.
  ///
  /// In uz, this message translates to:
  /// **'Markaz'**
  String get studentMethodFishboneCenter;

  /// No description provided for @studentMethodFishboneBranches.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil'**
  String get studentMethodFishboneBranches;

  /// No description provided for @studentMethodGroupInstructions.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rsatma'**
  String get studentMethodGroupInstructions;

  /// No description provided for @caseStudyScenarioSavedSnack.
  ///
  /// In uz, this message translates to:
  /// **'Ssenariy metodga saqlandi'**
  String get caseStudyScenarioSavedSnack;

  /// No description provided for @caseStudySolutionKeySavedSnack.
  ///
  /// In uz, this message translates to:
  /// **'Yechim kaliti saqlandi'**
  String get caseStudySolutionKeySavedSnack;

  /// No description provided for @caseStudyReviewCompareSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yonma-yon: o\'quvchi javobi · namunaviy yechim'**
  String get caseStudyReviewCompareSubtitle;

  /// No description provided for @caseStudyPanelStudent.
  ///
  /// In uz, this message translates to:
  /// **'O\'quvchi'**
  String get caseStudyPanelStudent;

  /// No description provided for @caseStudyPanelReference.
  ///
  /// In uz, this message translates to:
  /// **'Namunaviy (yechim kaliti)'**
  String get caseStudyPanelReference;

  /// No description provided for @caseStudyQuickGrade.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor baho'**
  String get caseStudyQuickGrade;

  /// No description provided for @caseStudyStarTooltipPoints.
  ///
  /// In uz, this message translates to:
  /// **'{points} ball'**
  String caseStudyStarTooltipPoints(int points);

  /// No description provided for @caseStudyExactScore.
  ///
  /// In uz, this message translates to:
  /// **'Aniq bal: {n} / 10'**
  String caseStudyExactScore(int n);

  /// No description provided for @caseStudyCommentHint.
  ///
  /// In uz, this message translates to:
  /// **'Matnli izoh (ovozli yozuv — keyingi bosqich)'**
  String get caseStudyCommentHint;

  /// No description provided for @caseStudyNoProbeSelections.
  ///
  /// In uz, this message translates to:
  /// **'Tanlovlar hali yo\'q'**
  String get caseStudyNoProbeSelections;

  /// No description provided for @caseStudyHeatmapEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Tanlovlar statistikasi hali yo\'q (yoki taassurof tanlovlari bo\'lmagan javoblar).'**
  String get caseStudyHeatmapEmpty;

  /// No description provided for @caseStudyHeatmapTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tanlovlar heatmap'**
  String get caseStudyHeatmapTitle;

  /// No description provided for @caseStudyMethodNotSelected.
  ///
  /// In uz, this message translates to:
  /// **'Metod tanlanmagan'**
  String get caseStudyMethodNotSelected;

  /// No description provided for @caseStudyNoAssignments.
  ///
  /// In uz, this message translates to:
  /// **'Bu metod uchun topshiriqlar yo\'q'**
  String get caseStudyNoAssignments;

  /// No description provided for @caseStudyAssignmentPickerLabel.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq'**
  String get caseStudyAssignmentPickerLabel;

  /// No description provided for @caseStudyVisualAnalysisTitle.
  ///
  /// In uz, this message translates to:
  /// **'Vizual tahlil'**
  String get caseStudyVisualAnalysisTitle;

  /// No description provided for @caseStudyVisualAnalysisSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagi ko\'rsatkichlar tanlangan topshiriq bo\'yicha real vaqtda yangilanadi (heatmap, xavfsiz yo\'l ulushi, ogohlantirishlar).'**
  String get caseStudyVisualAnalysisSubtitle;

  /// No description provided for @caseStudyDeadEndWarning.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirish: {count} ta javobda so\'nggi tanlov noto\'g\'ri (mantiqiy berk yo\'l ehtimoli)'**
  String caseStudyDeadEndWarning(int count);

  /// No description provided for @caseStudyAllProbesCorrectTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sinf bo\'yicha: barcha tanlovlar to\'g\'ri'**
  String get caseStudyAllProbesCorrectTitle;

  /// No description provided for @caseStudyScenarioAnswerShare.
  ///
  /// In uz, this message translates to:
  /// **'{percent}% · taassurof javoblari'**
  String caseStudyScenarioAnswerShare(String percent);

  /// No description provided for @caseStudyNoSubmissionsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hali yuborishlar yo\'q'**
  String get caseStudyNoSubmissionsYet;

  /// No description provided for @caseStudyColTime.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt'**
  String get caseStudyColTime;

  /// No description provided for @caseStudyColStages.
  ///
  /// In uz, this message translates to:
  /// **'Bosqichlar'**
  String get caseStudyColStages;

  /// No description provided for @caseStudyColWarning.
  ///
  /// In uz, this message translates to:
  /// **'Ogohlantirish'**
  String get caseStudyColWarning;

  /// No description provided for @caseStudyColGrade.
  ///
  /// In uz, this message translates to:
  /// **'Baho'**
  String get caseStudyColGrade;

  /// No description provided for @caseStudyColActions.
  ///
  /// In uz, this message translates to:
  /// **' '**
  String get caseStudyColActions;

  /// No description provided for @caseStudyCatalogSearchLabel.
  ///
  /// In uz, this message translates to:
  /// **'Mavzu qidiruv (barcha sinflar)'**
  String get caseStudyCatalogSearchLabel;

  /// No description provided for @caseStudyJsonBankHint.
  ///
  /// In uz, this message translates to:
  /// **'JSON bankidan tanlang · tartibni Drag-and-drop bilan o\'zgartiring'**
  String get caseStudyJsonBankHint;

  /// No description provided for @caseStudyEditOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tahrir (tartib)'**
  String get caseStudyEditOrderTitle;

  /// No description provided for @caseStudyClear.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get caseStudyClear;

  /// No description provided for @caseStudySaveFirstBandScenario.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi bandni ssenariy sifatida saqlash'**
  String get caseStudySaveFirstBandScenario;

  /// No description provided for @caseStudySaveAllBandsScenario.
  ///
  /// In uz, this message translates to:
  /// **'Barcha bandlarni ssenariyga (birlashtirilgan)'**
  String get caseStudySaveAllBandsScenario;

  /// No description provided for @caseStudyInteractiveScenarioMissing.
  ///
  /// In uz, this message translates to:
  /// **'Bu mavzuda interaktiv ssenariy topilmadi'**
  String get caseStudyInteractiveScenarioMissing;

  /// No description provided for @caseStudySaveInteractiveScenario.
  ///
  /// In uz, this message translates to:
  /// **'Interaktiv ssenariyni saqlash'**
  String get caseStudySaveInteractiveScenario;

  /// No description provided for @caseStudySaveSolutionOrder.
  ///
  /// In uz, this message translates to:
  /// **'Tartib — yechim kaliti (ketma-ketlik)'**
  String get caseStudySaveSolutionOrder;

  /// No description provided for @caseStudyAppBarPanel.
  ///
  /// In uz, this message translates to:
  /// **'Case-study panel'**
  String get caseStudyAppBarPanel;

  /// No description provided for @caseStudyNoMethodParams.
  ///
  /// In uz, this message translates to:
  /// **'Metod parametrlari yo\'q'**
  String get caseStudyNoMethodParams;

  /// No description provided for @caseStudyAppBarDashboard.
  ///
  /// In uz, this message translates to:
  /// **'Case-study · boshqaruv paneli'**
  String get caseStudyAppBarDashboard;

  /// No description provided for @caseStudyNavMonitoring.
  ///
  /// In uz, this message translates to:
  /// **'Monitoring'**
  String get caseStudyNavMonitoring;

  /// No description provided for @caseStudyNavConstructor.
  ///
  /// In uz, this message translates to:
  /// **'Konstruktor'**
  String get caseStudyNavConstructor;

  /// No description provided for @caseStudyNavAnalysis.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil'**
  String get caseStudyNavAnalysis;

  /// No description provided for @csvColDisplayName.
  ///
  /// In uz, this message translates to:
  /// **'display_name'**
  String get csvColDisplayName;

  /// No description provided for @csvColStudentId.
  ///
  /// In uz, this message translates to:
  /// **'student_id'**
  String get csvColStudentId;

  /// No description provided for @csvColSubmittedAt.
  ///
  /// In uz, this message translates to:
  /// **'submitted_at'**
  String get csvColSubmittedAt;

  /// No description provided for @csvColScore.
  ///
  /// In uz, this message translates to:
  /// **'score'**
  String get csvColScore;

  /// No description provided for @csvColGrade10.
  ///
  /// In uz, this message translates to:
  /// **'grade10'**
  String get csvColGrade10;

  /// No description provided for @csvColReviewStatus.
  ///
  /// In uz, this message translates to:
  /// **'review_status'**
  String get csvColReviewStatus;

  /// No description provided for @csvColTeacherComment.
  ///
  /// In uz, this message translates to:
  /// **'teacher_comment'**
  String get csvColTeacherComment;

  /// No description provided for @csvColAiFeedback.
  ///
  /// In uz, this message translates to:
  /// **'ai_feedback'**
  String get csvColAiFeedback;

  /// No description provided for @csvColAnswerText.
  ///
  /// In uz, this message translates to:
  /// **'answer_text'**
  String get csvColAnswerText;

  /// No description provided for @actionRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get actionRetry;

  /// No description provided for @joinSnackLoginForAssignment.
  ///
  /// In uz, this message translates to:
  /// **'Avval «Kirish» — topshiriq kodi tizimda ishlatiladi.'**
  String get joinSnackLoginForAssignment;

  /// No description provided for @joinSnackEnterCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod kiriting'**
  String get joinSnackEnterCode;

  /// No description provided for @joinSnackCodeInvalid.
  ///
  /// In uz, this message translates to:
  /// **'Kod topilmadi yoki noto\'g\'ri'**
  String get joinSnackCodeInvalid;

  /// No description provided for @joinSnackLoginForGroup.
  ///
  /// In uz, this message translates to:
  /// **'Guruhga qo\'shilish uchun tizimga kiring.'**
  String get joinSnackLoginForGroup;

  /// No description provided for @joinSnackGroupStudentOnly.
  ///
  /// In uz, this message translates to:
  /// **'Guruh a\'zoligi o\'quvchilar uchun.'**
  String get joinSnackGroupStudentOnly;

  /// No description provided for @joinSnackEnterGroupCode.
  ///
  /// In uz, this message translates to:
  /// **'Guruh kodini kiriting'**
  String get joinSnackEnterGroupCode;

  /// No description provided for @joinSnackGroupJoined.
  ///
  /// In uz, this message translates to:
  /// **'Guruhga qo\'shildingiz. «Mening topshiriqlarim» ni oching.'**
  String get joinSnackGroupJoined;

  /// No description provided for @joinTabAssignmentCode.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq kodi'**
  String get joinTabAssignmentCode;

  /// No description provided for @joinTabGroupCode.
  ///
  /// In uz, this message translates to:
  /// **'Guruh kodi'**
  String get joinTabGroupCode;

  /// No description provided for @joinLoginCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tizimga kiring'**
  String get joinLoginCardTitle;

  /// No description provided for @joinLoginCardSubtitleAssignment.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq kodi yuborilgach ochiladi.'**
  String get joinLoginCardSubtitleAssignment;

  /// No description provided for @joinAssignmentIntro.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi bergan topshiriq kodini kiriting (masalan: XK7F2). Kod nusxalanganda oraliq bo\'shliqlar e\'tiborsiz yechiladi.'**
  String get joinAssignmentIntro;

  /// No description provided for @joinTeacherPreviewTitle.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi rejimi'**
  String get joinTeacherPreviewTitle;

  /// No description provided for @joinTeacherPreviewSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Kod orqali topshiriqni ko\'rush mumkin. Javob yuborish o\'quvchilar uchun.'**
  String get joinTeacherPreviewSubtitle;

  /// No description provided for @joinFieldAssignmentCode.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriq kodi'**
  String get joinFieldAssignmentCode;

  /// No description provided for @joinFieldAssignmentHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: XK7F2'**
  String get joinFieldAssignmentHint;

  /// No description provided for @joinOpenAssignment.
  ///
  /// In uz, this message translates to:
  /// **'Topshiriqqa o\'tish'**
  String get joinOpenAssignment;

  /// No description provided for @joinGroupIntro.
  ///
  /// In uz, this message translates to:
  /// **'O\'qituvchi bergan guruh kirish kodini kiriting. Keyin sizga shu guruh orqali topshiriqlar «Mening topshiriqlarim» da ko\'rinadi.'**
  String get joinGroupIntro;

  /// No description provided for @joinStudentOnlyCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Avval o\'quvchi sifatida kiring'**
  String get joinStudentOnlyCardTitle;

  /// No description provided for @joinFieldGroupCode.
  ///
  /// In uz, this message translates to:
  /// **'Guruh kodi'**
  String get joinFieldGroupCode;

  /// No description provided for @joinFieldGroupHint.
  ///
  /// In uz, this message translates to:
  /// **'6 belgi'**
  String get joinFieldGroupHint;

  /// No description provided for @joinGroupSubmit.
  ///
  /// In uz, this message translates to:
  /// **'Guruhga qo\'shilish'**
  String get joinGroupSubmit;

  /// No description provided for @firebaseErrorIndexBuilding.
  ///
  /// In uz, this message translates to:
  /// **'Firestore so\'rovi uchun indeks yaratilmoqda yoki kerak. Bir necha daqiqadan so\'ng qayta urinib ko\'ring; o\'qituvchidan `firebase deploy --only firestore:indexes` bajarilganini tekshiring.'**
  String get firebaseErrorIndexBuilding;

  /// No description provided for @firebaseErrorPermissionStudent.
  ///
  /// In uz, this message translates to:
  /// **'Ruxsat rad etildi. Avval o\'quvchi sifatida tizimga kiring.'**
  String get firebaseErrorPermissionStudent;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tiklash'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In uz, this message translates to:
  /// **'Loginni kiriting. Tizim Firebase orqali tiklash havolasini yuborishga harakat qiladi (pochta sozlamalari qarab).'**
  String get forgotPasswordBody;

  /// No description provided for @forgotPasswordLoginField.
  ///
  /// In uz, this message translates to:
  /// **'Login'**
  String get forgotPasswordLoginField;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In uz, this message translates to:
  /// **'So\'rov yuborildi. Agar xat kelmasa, Firebase Console va email domenini tekshiring.'**
  String get forgotPasswordSent;

  /// No description provided for @teacherClassDeleteTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sinfni o\'chirish'**
  String get teacherClassDeleteTitle;

  /// No description provided for @teacherClassDeleteMessage.
  ///
  /// In uz, this message translates to:
  /// **'\"{name}\" va uning ostidagi mavzular, metodlar va topshiriqlar butunlay o\'chiriladi.'**
  String teacherClassDeleteMessage(String name);

  /// No description provided for @teacherClassDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Sinf o\'chirildi'**
  String get teacherClassDeleted;

  /// No description provided for @teacherMethodDeleteTitle.
  ///
  /// In uz, this message translates to:
  /// **'Metodni o\'chirish'**
  String get teacherMethodDeleteTitle;

  /// No description provided for @teacherMethodDeleteMessage.
  ///
  /// In uz, this message translates to:
  /// **'\"{name}\" va unga bog\'langan topshiriqlar butunlay o\'chiriladi.'**
  String teacherMethodDeleteMessage(String name);

  /// No description provided for @teacherMethodDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Metod o\'chirildi'**
  String get teacherMethodDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
