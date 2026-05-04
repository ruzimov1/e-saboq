// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'e-Saboq';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get registerTitle => 'Register';

  @override
  String get joinByCode => 'Join with code';

  @override
  String get myAssignments => 'My assignments';

  @override
  String get assignments => 'Assignments';

  @override
  String get assignmentResults => 'Results';

  @override
  String get noSubmissionsYet => 'No submissions yet';

  @override
  String get subjects => 'Subjects';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get networkOffline => 'Offline — showing cached data when available';

  @override
  String get networkOnline => 'Back online';

  @override
  String get submissionStatusSubmitted => 'Submitted';

  @override
  String get submissionStatusReviewed => 'Reviewed';

  @override
  String get submissionStatusReturned => 'Returned';

  @override
  String get teacherComment => 'Teacher comment';

  @override
  String get reviewSave => 'Save review';

  @override
  String get exportCsv => 'Copy CSV';

  @override
  String get csvCopied => 'CSV copied to clipboard';

  @override
  String get rubricLabel => 'Rubric (visible to students)';

  @override
  String get teacherNotesLabel => 'Internal notes (teacher only)';

  @override
  String get groupWorkOptional => 'Group submission (coming soon)';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String get viewAnswer => 'View answer';

  @override
  String statsAssignments(int total, int active, int closed) {
    return 'Assignments: $total · Active: $active · Closed: $closed';
  }

  @override
  String avgQuizScore(String score) {
    return 'Quiz average: $score';
  }

  @override
  String get noAvgQuiz => 'No quiz scores yet';

  @override
  String get aiReviewTooltip => 'AI review';

  @override
  String get aiReviewTitle => 'AI assistant';

  @override
  String get aiReviewLoading => 'Analyzing…';

  @override
  String get aiKeyMissing =>
      'Missing Gemini key: add GEMINI_API_KEY= to .env (aistudio.google.com/apikey)';

  @override
  String get aiDisclaimer =>
      'AI is assistive only; final grade is the teacher’s decision.';

  @override
  String get aiSaveToSubmission => 'Save to submission';

  @override
  String get aiFeedbackSaved => 'AI feedback saved';

  @override
  String get aiFeedbackLabel => 'AI feedback';

  @override
  String get registerSubtitle => 'Create a new account';

  @override
  String get resultsFilterAll => 'All';

  @override
  String get resultsFilterSubmitted => 'Submitted';

  @override
  String get resultsFilterReviewed => 'Reviewed';

  @override
  String get resultsFilterReturned => 'Returned';

  @override
  String get resultsFilterNoGrade => 'No grade yet';

  @override
  String get resultsDateRangePick => 'Date range';

  @override
  String get resultsClearDateRange => 'Clear dates';

  @override
  String get resultsNoMatchesFilter => 'No results match the selected filters.';

  @override
  String get brainstormIdeaFeedEmpty =>
      'No ideas yet. When students post, stickers appear here. You can remove inappropriate ideas or add a grade and comment to each.';

  @override
  String get assignmentUntitled => 'Assignment';

  @override
  String get reviewStatusFieldLabel => 'Status';

  @override
  String get resultsAnswerHeading => 'Answer';

  @override
  String resultsQuizPercent(String percent) {
    return 'Quiz: $percent%';
  }

  @override
  String resultsGrade10Chip(String grade) {
    return 'Grade: $grade/10';
  }

  @override
  String get brainstormTabStudents => 'Students';

  @override
  String get brainstormTabIdeaFeed => 'Ideas feed';

  @override
  String get resultsAssignmentRouteMissing => 'No assignment selected (route).';

  @override
  String get brainstormDeleteIdeaTitle => 'Delete idea';

  @override
  String get brainstormDeleteIdeaBody =>
      'Remove this idea from the feed? Submissions in the list are unchanged — only the sticker feed.';

  @override
  String get brainstormIdeaGradeDialogTitle => 'Idea — grade and comment';

  @override
  String get gradeOutOfTenTitle => 'Grade (0–10)';

  @override
  String brainstormAvgGrade(String avg) {
    return 'Average grade: $avg/10';
  }

  @override
  String get brainstormAvgGradeNone => 'Average grade: none yet';

  @override
  String get brainstormEditGradeComment => 'Grade and comment';

  @override
  String brainstormStudentLine(String name) {
    return 'Student: $name';
  }

  @override
  String brainstormCommentLine(String text) {
    return 'Comment: $text';
  }

  @override
  String get brainstormIdeaDeleted => 'Idea removed';

  @override
  String get studentListLoginPrompt => 'Sign in to see your list.';

  @override
  String get studentBulkDeleteSelectedTitle => 'Delete selected';

  @override
  String studentBulkDeleteSelectedMessage(int count) {
    return 'Delete $count item(s)? Group inbox entries will be removed; submitted answers will be fully deleted.';
  }

  @override
  String get studentBulkDeleteAllTitle => 'Delete all';

  @override
  String studentBulkDeleteAllMessage(int total) {
    return 'This will remove all $total items (inbox + every submitted answer). Continue?';
  }

  @override
  String get studentBulkDeleteNothingToRemove => 'Nothing to delete';

  @override
  String studentBulkDeletedPartial(int failed) {
    return 'Some items were not removed ($failed).';
  }

  @override
  String get studentBulkDeletedOk => 'Deleted';

  @override
  String studentBulkDeleteAllError(int failed) {
    return 'Error: $failed item(s) not removed';
  }

  @override
  String get studentBulkDeletedAllOk => 'All deleted';

  @override
  String get studentSelectItems => 'Select';

  @override
  String studentSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get studentDeleteViaSelection => 'Delete via selection';

  @override
  String get studentDeleteEverything => 'Delete everything';

  @override
  String get studentDeleteDialogTitle => 'Delete';

  @override
  String get studentAssignmentsEmptyHint =>
      'No assignments yet. Join with a task or group code.';

  @override
  String get studentGroupInboxSection => 'From group (to do)';

  @override
  String get studentSubmittedSection => 'Submitted';

  @override
  String studentCodeLine(String code) {
    return 'Code: $code';
  }

  @override
  String get studentMetaScore => 'Score';

  @override
  String studentMetaTeacherGrade10(int n) {
    return 'Teacher: $n/10';
  }

  @override
  String get studentSubmissionHasFeedbackNote =>
      '(grade, comment, or analysis present)';

  @override
  String get studentSubmissionScreenTitle => 'Submitted answer';

  @override
  String get studentDetailLoginForAnswer => 'Sign in to view your answer.';

  @override
  String get studentSubmissionMissing =>
      'Submission not found (it may have been deleted).';

  @override
  String studentDetailSubmittedAt(String when) {
    return 'Submitted: $when';
  }

  @override
  String get studentDetailStatusLabel => 'Status';

  @override
  String studentDetailQuizPointsSuffix(String points) {
    return ' · $points pts';
  }

  @override
  String get studentYourAnswer => 'Your answer';

  @override
  String get studentYourAnswers => 'Your answers';

  @override
  String get studentMethodLoadError => 'Could not load method details.';

  @override
  String get studentQuizNotConfigured => 'Quiz questions are not stored.';

  @override
  String get studentPollAnswerHeading => 'Survey response';

  @override
  String get studentAssignmentSectionTitle => 'Assignment';

  @override
  String studentTeacherOverallGrade10(int n) {
    return 'Teacher overall grade: $n/10';
  }

  @override
  String get studentBrainstormTeacherPerIdea => 'Teacher: each idea';

  @override
  String get studentBrainstormTeacherPerIdeaHint =>
      'In brainstorming, each idea can have its own grade and comment here (once the teacher adds them).';

  @override
  String get studentBrainstormIdeasMissingNote =>
      'No idea notes found (older submission or system). Your saved answer is shown above.';

  @override
  String get studentBrainstormNoTeacherGradeYet => 'No teacher grade yet.';

  @override
  String get studentAnswerShownAbove => '(Shown above)';

  @override
  String get studentQuizCorrect => 'Correct';

  @override
  String studentQuizCorrectOption(String answer) {
    return 'Correct option: $answer';
  }

  @override
  String get studentQuizPrevious => 'Previous';

  @override
  String get studentQuizNext => 'Next';

  @override
  String get studentQuizTimeElapsed => 'Done';

  @override
  String get studentMethodCaseScenario => 'Situation (case study)';

  @override
  String get studentMethodBrainstormPrompt => 'Prompt';

  @override
  String get studentMethodBrainstormGuide => 'Guide';

  @override
  String get studentMethodRoleRoles => 'Roles';

  @override
  String get studentMethodRoleScenario => 'Scenario';

  @override
  String get studentMethodFishboneDiagram => 'Fishbone diagram';

  @override
  String get studentMethodFishboneCenter => 'Center';

  @override
  String get studentMethodFishboneBranches => 'Analysis';

  @override
  String get studentMethodGroupInstructions => 'Instructions';

  @override
  String get caseStudyScenarioSavedSnack => 'Scenario saved to method';

  @override
  String get caseStudySolutionKeySavedSnack => 'Solution key saved';

  @override
  String get caseStudyReviewCompareSubtitle =>
      'Side by side: learner answer · model solution';

  @override
  String get caseStudyPanelStudent => 'Learner';

  @override
  String get caseStudyPanelReference => 'Model (solution key)';

  @override
  String get caseStudyQuickGrade => 'Quick grade';

  @override
  String caseStudyStarTooltipPoints(int points) {
    return '$points pts';
  }

  @override
  String caseStudyExactScore(int n) {
    return 'Score: $n / 10';
  }

  @override
  String get caseStudyCommentHint =>
      'Text comment (voice input — coming later)';

  @override
  String get caseStudyNoProbeSelections => 'No selections yet';

  @override
  String get caseStudyHeatmapEmpty =>
      'No choice statistics yet (or no scenario selections in responses).';

  @override
  String get caseStudyHeatmapTitle => 'Choice heatmap';

  @override
  String get caseStudyMethodNotSelected => 'No method selected';

  @override
  String get caseStudyNoAssignments => 'No assignments for this method';

  @override
  String get caseStudyAssignmentPickerLabel => 'Assignment';

  @override
  String get caseStudyVisualAnalysisTitle => 'Visual analytics';

  @override
  String get caseStudyVisualAnalysisSubtitle =>
      'The metrics below update in real time for the selected assignment (heatmap, safe-path share, alerts).';

  @override
  String caseStudyDeadEndWarning(int count) {
    return 'Warning: $count response(s) end with an incorrect last choice (possible logic dead end)';
  }

  @override
  String get caseStudyAllProbesCorrectTitle =>
      'Class-wide: all choices correct';

  @override
  String caseStudyScenarioAnswerShare(String percent) {
    return '$percent% · scenario-based answers';
  }

  @override
  String get caseStudyNoSubmissionsYet => 'No submissions yet';

  @override
  String get caseStudyColTime => 'Time';

  @override
  String get caseStudyColStages => 'Stages';

  @override
  String get caseStudyColWarning => 'Alert';

  @override
  String get caseStudyColGrade => 'Grade';

  @override
  String get caseStudyColActions => ' ';

  @override
  String get caseStudyCatalogSearchLabel => 'Topic search (all classes)';

  @override
  String get caseStudyJsonBankHint =>
      'Pick from JSON bank · reorder via drag-and-drop';

  @override
  String get caseStudyEditOrderTitle => 'Edit (order)';

  @override
  String get caseStudyClear => 'Clear';

  @override
  String get caseStudySaveFirstBandScenario => 'Save first block as scenario';

  @override
  String get caseStudySaveAllBandsScenario => 'Save all blocks as one scenario';

  @override
  String get caseStudyInteractiveScenarioMissing =>
      'No interactive scenario for this topic';

  @override
  String get caseStudySaveInteractiveScenario => 'Save interactive scenario';

  @override
  String get caseStudySaveSolutionOrder => 'Order — solution key (sequence)';

  @override
  String get caseStudyAppBarPanel => 'Case study panel';

  @override
  String get caseStudyNoMethodParams => 'No method parameters';

  @override
  String get caseStudyAppBarDashboard => 'Case study · dashboard';

  @override
  String get caseStudyNavMonitoring => 'Monitoring';

  @override
  String get caseStudyNavConstructor => 'Builder';

  @override
  String get caseStudyNavAnalysis => 'Analytics';

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
  String get actionRetry => 'Retry';

  @override
  String get joinSnackLoginForAssignment =>
      'Sign in first — assignment codes work when logged in.';

  @override
  String get joinSnackEnterCode => 'Enter a code';

  @override
  String get joinSnackCodeInvalid => 'Code not found or invalid';

  @override
  String get joinSnackLoginForGroup => 'Sign in to join a group.';

  @override
  String get joinSnackGroupStudentOnly => 'Group membership is for students.';

  @override
  String get joinSnackEnterGroupCode => 'Enter the group code';

  @override
  String get joinSnackGroupJoined =>
      'You joined the group. Open “My assignments”.';

  @override
  String get joinTabAssignmentCode => 'Assignment code';

  @override
  String get joinTabGroupCode => 'Group code';

  @override
  String get joinLoginCardTitle => 'Sign in';

  @override
  String get joinLoginCardSubtitleAssignment =>
      'Opens after you send the assignment code flow.';

  @override
  String get joinAssignmentIntro =>
      'Enter the assignment code from your teacher (e.g. XK7F2). Extra spaces are ignored when pasting.';

  @override
  String get joinTeacherPreviewTitle => 'Teacher mode';

  @override
  String get joinTeacherPreviewSubtitle =>
      'You can preview the task by code. Submitting answers is for students.';

  @override
  String get joinFieldAssignmentCode => 'Assignment code';

  @override
  String get joinFieldAssignmentHint => 'e.g. XK7F2';

  @override
  String get joinOpenAssignment => 'Open assignment';

  @override
  String get joinGroupIntro =>
      'Enter the group join code from your teacher. Then group assignments appear under “My assignments”.';

  @override
  String get joinStudentOnlyCardTitle => 'Sign in as a student first';

  @override
  String get joinFieldGroupCode => 'Group code';

  @override
  String get joinFieldGroupHint => '6 characters';

  @override
  String get joinGroupSubmit => 'Join group';

  @override
  String get firebaseErrorIndexBuilding =>
      'A Firestore index may be building or missing. Try again in a few minutes; ask your teacher if `firebase deploy --only firestore:indexes` was run.';

  @override
  String get firebaseErrorPermissionStudent =>
      'Permission denied. Sign in as a student first.';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordBody =>
      'Enter your username/login. The app will try to send a reset link via Firebase (depends on email setup).';

  @override
  String get forgotPasswordLoginField => 'Login';

  @override
  String get forgotPasswordSubmit => 'Send';

  @override
  String get forgotPasswordSent =>
      'Request sent. If no email arrives, check Firebase Console and your domain.';

  @override
  String get teacherClassDeleteTitle => 'Delete class';

  @override
  String teacherClassDeleteMessage(String name) {
    return '\"$name\" and all topics, methods, and assignments under it will be permanently removed.';
  }

  @override
  String get teacherClassDeleted => 'Class deleted';

  @override
  String get teacherMethodDeleteTitle => 'Delete method';

  @override
  String teacherMethodDeleteMessage(String name) {
    return '\"$name\" and all linked assignments will be permanently removed.';
  }

  @override
  String get teacherMethodDeleted => 'Method deleted';
}
