// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ai/gemini_method_coach.dart';
import '../../../../core/assignments/brainstorm_session_config.dart';
import '../../../../core/case_study/case_study_bank.dart';
import '../../../../core/case_study/case_study_cyber_models.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/services/assignment_draft_store.dart';
import '../../../../core/t_schema/t_schema_method_config.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../teacher/assignments/data/assignment_lookup.dart';
import '../../../teacher/assignments/data/assignment_repository.dart';
import '../../../teacher/methods/data/method_model.dart';
import '../../../teacher/methods/data/method_repository.dart';
import '../data/submission_repository.dart';
import '../widgets/brainstorm_student_experience.dart';
import '../widgets/case_study_cyber_experience.dart';
import '../widgets/cluster_student_experience.dart';
import '../widgets/t_schema_interactive_solver.dart';

/// O‘quvchi ekranida ko‘rsatish tartibi; javoblar asl savol indeksida saqlanadi.
class _QuizSessionLayout {
  const _QuizSessionLayout({
    required this.displayQuestions,
    required this.displayToOriginalQuestionIndex,
    required this.displayOptionToOriginal,
  });

  final List<Map<String, dynamic>> displayQuestions;
  final List<int> displayToOriginalQuestionIndex;
  final List<List<int>> displayOptionToOriginal;
}

_QuizSessionLayout _buildQuizSessionLayout(
  List<dynamic> raw,
  bool shuffle,
  int seed,
) {
  final originals = <Map<String, dynamic>>[];
  for (final r in raw) {
    if (r is Map<String, dynamic>) {
      originals.add(Map<String, dynamic>.from(r));
    } else if (r is Map) {
      originals.add(Map<String, dynamic>.from(r));
    }
  }
  final n = originals.length;
  if (n == 0) {
    return _QuizSessionLayout(
      displayQuestions: [],
      displayToOriginalQuestionIndex: [],
      displayOptionToOriginal: [],
    );
  }
  final rnd = Random(seed);
  final qOrder = List<int>.generate(n, (i) => i);
  if (shuffle) {
    qOrder.shuffle(rnd);
  }
  final displayQuestions = <Map<String, dynamic>>[];
  final displayToOriginalQuestionIndex = <int>[];
  final displayOptionToOriginal = <List<int>>[];

  for (final oi in qOrder) {
    final src = originals[oi];
    final q = Map<String, dynamic>.from(src);
    final opts =
        (q['options'] as List<dynamic>?)?.map((e) => '$e').toList() ?? [];
    final nc = opts.length;
    if (nc == 0) {
      displayQuestions.add(q);
      displayToOriginalQuestionIndex.add(oi);
      displayOptionToOriginal.add(const []);
      continue;
    }
    var optOrder = List<int>.generate(nc, (i) => i);
    if (shuffle) {
      optOrder.shuffle(rnd);
    }
    final newOpts = [for (final i in optOrder) opts[i]];
    q['options'] = newOpts;
    final oldC = (src['correctIndex'] as num?)?.toInt() ?? 0;
    final safeOldC = oldC.clamp(0, nc - 1);
    final newC = optOrder.indexWhere((origIdx) => origIdx == safeOldC);
    q['correctIndex'] = newC >= 0 ? newC : 0;

    displayQuestions.add(q);
    displayToOriginalQuestionIndex.add(oi);
    displayOptionToOriginal.add(optOrder);
  }
  return _QuizSessionLayout(
    displayQuestions: displayQuestions,
    displayToOriginalQuestionIndex: displayToOriginalQuestionIndex,
    displayOptionToOriginal: displayOptionToOriginal,
  );
}

class SolveAssignmentScreen extends StatefulWidget {
  const SolveAssignmentScreen({super.key, this.lookup});

  final AssignmentLookup? lookup;

  @override
  State<SolveAssignmentScreen> createState() => _SolveAssignmentScreenState();
}

class _SolveAssignmentScreenState extends State<SolveAssignmentScreen> {
  /// To‘liq hujjat (masalan, `embeddedMethodConfig` bilan).
  AssignmentLookup? _lookup;
  bool _alreadySubmitted = false;
  MethodModel? _method;
  bool _loading = true;
  bool _submitting = false;

  /// Quiz: har bir savol uchun tanlangan variant indeksi.
  final List<int?> _quizChoices = [];
  /// `true` — teskari hisoblagich tugamidan oldin javob berilgan (aniqlik + tartib).
  final List<bool?> _quizTimeOk = [];

  int? _pollChoice;
  final _textAnswer = TextEditingController();
  final _brainstormInput = TextEditingController();
  final List<String> _brainstormMyIdeas = <String>[];
  Timer? _draftDebounce;
  Timer? _sessionTimer;
  int? _secondsLeft;
  bool _timeExpired = false;
  BrainstormSessionConfig? _brainstormConfig;
  final GlobalKey<ClusterStudentExperienceState> _clusterKey =
      GlobalKey<ClusterStudentExperienceState>();

  _QuizSessionLayout? _quizLayout;

  TSchemaMethodConfig? _tSchemaConfig;
  Map<String, dynamic>? _tSchemaDraftRestore;
  GlobalKey<TSchemaInteractiveSolverState> _tSchemaKey =
      GlobalKey<TSchemaInteractiveSolverState>();
  Timer? _tSchemaTimer;
  int? _tSchemaSecondsLeft;
  bool _tSchemaTimeExpired = false;

  CaseCyberTask? _caseCyberTask;
  final GlobalKey<CaseStudyCyberExperienceState> _caseCyberKey =
      GlobalKey<CaseStudyCyberExperienceState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _sessionTimer?.cancel();
    _tSchemaTimer?.cancel();
    _textAnswer.dispose();
    _brainstormInput.dispose();
    super.dispose();
  }

  void _startBrainstormTimer() {
    _sessionTimer?.cancel();
    final left = _secondsLeft;
    if (left == null || left <= 0) {
      return;
    }
    _timeExpired = false;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      bool justExpired = false;
      setState(() {
        final s = _secondsLeft;
        if (s == null || s <= 1) {
          _secondsLeft = 0;
          _timeExpired = true;
          justExpired = true;
          _sessionTimer?.cancel();
        } else {
          _secondsLeft = s - 1;
        }
      });
      if (justExpired) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && !_submitting && !_alreadySubmitted) {
            _submit(auto: true);
          }
        });
      }
    });
  }

  bool get _blockSubmitByTimer {
    final c = _brainstormConfig;
    if (_method?.type != 'brainstorm' || c == null) {
      if (_method?.type == 'fishbone' && _tSchemaConfig != null) {
        final dm = _tSchemaConfig!.durationMinutes;
        if (dm <= 0) {
          return false;
        }
        return _tSchemaTimeExpired;
      }
      return false;
    }
    if (c.durationMinutes <= 0) {
      return false;
    }
    return _timeExpired;
  }

  void _startTSchemaTimer() {
    _tSchemaTimer?.cancel();
    final left = _tSchemaSecondsLeft;
    if (left == null || left <= 0) {
      return;
    }
    _tSchemaTimeExpired = false;
    _tSchemaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      bool justExpired = false;
      setState(() {
        final s = _tSchemaSecondsLeft;
        if (s == null || s <= 1) {
          _tSchemaSecondsLeft = 0;
          _tSchemaTimeExpired = true;
          justExpired = true;
          _tSchemaTimer?.cancel();
        } else {
          _tSchemaSecondsLeft = s - 1;
        }
      });
      if (justExpired) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && !_submitting && !_alreadySubmitted) {
            _submit(auto: true);
          }
        });
      }
    });
  }

  String _mmSs(int? totalSeconds) {
    if (totalSeconds == null) {
      return '—';
    }
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  List<String> _parseBrainstormLines(String raw) {
    return raw
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool get _isGroupClusterMode {
    if (_method?.type != 'group') {
      return false;
    }
    return _buildStudentClusterBranchList()
        .any((b) => !b.isDistractor);
  }

  String _groupCenterLabel(AssignmentLookup l) {
    final c = _method?.config;
    final x = c?['center'] as String?;
    if (x != null && x.trim().isNotEmpty) {
      return x.trim();
    }
    final t = c?['title'] as String?;
    if (t != null) {
      final s = t.trim();
      if (s.startsWith('Klaster:')) {
        return s.substring('Klaster:'.length).trim();
      }
      if (s.isNotEmpty) {
        return s;
      }
    }
    return (l.data['title'] as String?)?.trim() ?? 'Mavzu';
  }

  List<StudentClusterBranch> _buildStudentClusterBranchList() {
    final c = _method?.config;
    final br = c?['branches'] as List<dynamic>? ?? <dynamic>[];
    final out = <StudentClusterBranch>[];
    for (var i = 0; i < br.length; i++) {
      final raw = br[i];
      if (raw is! Map) {
        continue;
      }
      final text = '${raw['text'] ?? ''}'.trim();
      if (text.isEmpty) {
        continue;
      }
      final dis = raw['isDistractor'] as bool? ?? false;
      int? cv;
      final col = raw['color'];
      if (col is int) {
        cv = col;
      } else if (col is num) {
        cv = col.toInt();
      }
      out.add(
        StudentClusterBranch(
          index: out.length,
          text: text,
          isDistractor: dis,
          colorArgb32: cv,
        ),
      );
    }
    return out;
  }

  void _scheduleDraftSave() {
    final l = _lookup ?? widget.lookup;
    final auth = context.read<AuthBloc>().state;
    if (l == null || auth is! AuthAuthenticated) return;
      _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(seconds: 2), () async {
      final payload = <String, dynamic>{
        'text': _textAnswer.text,
        'poll': _pollChoice,
        'quiz': List<int?>.from(_quizChoices),
        'quizTimeOk': List<bool?>.from(_quizTimeOk),
        'brainstormIdeas': List<String>.from(_brainstormMyIdeas),
        'tSchema': _tSchemaKey.currentState?.captureDraft(),
      };
      await AssignmentDraftStore.save(l, auth.user.id, payload);
    });
  }

  Future<void> _restoreDraft() async {
    final l = _lookup ?? widget.lookup;
    final auth = context.read<AuthBloc>().state;
    if (l == null || auth is! AuthAuthenticated) return;
    final d = await AssignmentDraftStore.load(l, auth.user.id);
    if (d == null || !mounted) return;
    setState(() {
      _textAnswer.text = d['text'] as String? ?? _textAnswer.text;
      final p = d['poll'];
      if (p is num) _pollChoice = p.toInt();
      final q = d['quiz'];
      if (q is List && _method?.type == 'quiz') {
        _quizChoices.clear();
        for (var i = 0; i < q.length; i++) {
          final v = q[i];
          _quizChoices.add(v == null ? null : (v as num).toInt());
        }
        final need = (_method?.config?['questions'] as List<dynamic>?)?.length ?? 0;
        while (_quizChoices.length < need) {
          _quizChoices.add(null);
        }
        final qt = d['quizTimeOk'];
        if (qt is List) {
          _quizTimeOk
            ..clear()
            ..addAll(
              qt.map((e) {
                if (e == null) return null;
                if (e is bool) return e;
                return null;
              }),
            );
        }
        _ensureQuizSidecars(need);
      }
      if (_method?.type == 'brainstorm') {
        final bi = d['brainstormIdeas'];
        if (bi is List) {
          _brainstormMyIdeas
            ..clear()
            ..addAll(bi.map((e) => '$e').map((e) => e.trim()).where((e) => e.isNotEmpty));
        } else {
          _brainstormMyIdeas
            ..clear()
            ..addAll(_parseBrainstormLines(d['text'] as String? ?? ''));
        }
      }
      if (_method?.type == 'fishbone') {
        final ts = d['tSchema'];
        if (ts is Map<String, dynamic>) {
          _tSchemaDraftRestore = Map<String, dynamic>.from(ts);
          _tSchemaKey = GlobalKey<TSchemaInteractiveSolverState>();
        } else if (ts is Map) {
          _tSchemaDraftRestore = Map<String, dynamic>.from(ts);
          _tSchemaKey = GlobalKey<TSchemaInteractiveSolverState>();
        }
      }
    });
  }

  void _ensureQuizSidecars(int n) {
    while (_quizChoices.length < n) {
      _quizChoices.add(null);
    }
    while (_quizChoices.length > n) {
      _quizChoices.removeLast();
    }
    while (_quizTimeOk.length < n) {
      _quizTimeOk.add(null);
    }
    while (_quizTimeOk.length > n) {
      _quizTimeOk.removeLast();
    }
  }

  int? _quizChoiceAtDisplay(int displayIdx) {
    final layout = _quizLayout;
    if (layout == null) {
      return null;
    }
    if (displayIdx < 0 ||
        displayIdx >= layout.displayToOriginalQuestionIndex.length) {
      return null;
    }
    final oi = layout.displayToOriginalQuestionIndex[displayIdx];
    final origPick = oi < _quizChoices.length ? _quizChoices[oi] : null;
    if (origPick == null) {
      return null;
    }
    final back = layout.displayOptionToOriginal[displayIdx];
    for (var v = 0; v < back.length; v++) {
      if (back[v] == origPick) {
        return v;
      }
    }
    return null;
  }

  void _setQuizAnswerFromDisplay(int displayIdx, int displayOpt) {
    final layout = _quizLayout;
    if (layout == null) {
      return;
    }
    if (displayIdx < 0 ||
        displayIdx >= layout.displayToOriginalQuestionIndex.length) {
      return;
    }
    if (_quizSessionResolvedAtDisplay(displayIdx)) {
      return;
    }
    final oi = layout.displayToOriginalQuestionIndex[displayIdx];
    final back = layout.displayOptionToOriginal[displayIdx];
    if (displayOpt < 0 || displayOpt >= back.length) {
      return;
    }
    final origOpt = back[displayOpt];
    setState(() {
      while (_quizChoices.length <= oi) {
        _quizChoices.add(null);
      }
      _quizChoices[oi] = origOpt;
    });
    _scheduleDraftSave();
  }

  void _onQuizAnsweredInTimeForDisplay(int displayIdx) {
    final layout = _quizLayout;
    if (layout == null) {
      return;
    }
    if (displayIdx < 0 ||
        displayIdx >= layout.displayToOriginalQuestionIndex.length) {
      return;
    }
    final oi = layout.displayToOriginalQuestionIndex[displayIdx];
    setState(() {
      while (_quizTimeOk.length <= oi) {
        _quizTimeOk.add(null);
      }
      _quizTimeOk[oi] = true;
    });
    _scheduleDraftSave();
  }

  /// Tanlangan yoki vaqt bo‘yicha yopilgan savol — taymer qayta ishga tushmaydi, variant o‘zgarmaydi.
  bool _quizSessionResolvedAtDisplay(int displayIdx) {
    final layout = _quizLayout;
    if (layout == null) {
      return false;
    }
    if (displayIdx < 0 ||
        displayIdx >= layout.displayToOriginalQuestionIndex.length) {
      return false;
    }
    final oi = layout.displayToOriginalQuestionIndex[displayIdx];
    final hasChoice =
        oi < _quizChoices.length && _quizChoices[oi] != null;
    final timeClosed =
        oi < _quizTimeOk.length && _quizTimeOk[oi] != null;
    return hasChoice || timeClosed;
  }

  void _onQuizTimerExpiredForDisplay(int displayIdx) {
    final layout = _quizLayout;
    if (layout == null) {
      return;
    }
    if (displayIdx < 0 ||
        displayIdx >= layout.displayToOriginalQuestionIndex.length) {
      return;
    }
    final oi = layout.displayToOriginalQuestionIndex[displayIdx];
    setState(() {
      while (_quizTimeOk.length <= oi) {
        _quizTimeOk.add(null);
      }
      if (_quizTimeOk[oi] == null) {
        _quizTimeOk[oi] = false;
      }
    });
    _scheduleDraftSave();
    _checkAndMaybeAutoSubmitQuiz();
  }

  /// Barcha quiz savollari (javob berilgan yoki vaqti tugagan) bo'lganda avtomatik yuboradi.
  void _checkAndMaybeAutoSubmitQuiz() {
    final layout = _quizLayout;
    if (layout == null || _submitting || _alreadySubmitted) return;
    final n = layout.displayQuestions.length;
    if (n == 0) return;
    for (var i = 0; i < n; i++) {
      if (!_quizSessionResolvedAtDisplay(i)) return;
    }
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_submitting && !_alreadySubmitted) {
        _submit(auto: true);
      }
    });
  }

  Future<void> _load() async {
    final l0 = widget.lookup;
    if (l0 == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final full = await context.read<AssignmentRepository>().fetchAssignmentLookup(
            subjectId: l0.subjectId,
            classId: l0.classId,
            topicId: l0.topicId,
            methodId: l0.methodId,
            assignmentId: l0.assignmentId,
          );
      final l = full ?? l0;
      if (!mounted) {
        return;
      }
      var m = await context.read<MethodRepository>().fetchMethod(
            subjectId: l.subjectId,
            classId: l.classId,
            topicId: l.topicId,
            methodId: l.methodId,
          );
      final embedded = l.data['embeddedMethodConfig'] as Map<String, dynamic>?;
      if (embedded != null && m != null) {
        final base = Map<String, dynamic>.from(m.config ?? {});
        embedded.forEach((k, v) {
          if (v != null) {
            base[k] = v;
          }
        });
        m = m.copyWith(config: base);
      }
      if (!mounted) {
        return;
      }
      BrainstormSessionConfig? bcfg;
      int? secLeft;
      if (m?.type == 'brainstorm') {
        bcfg = BrainstormSessionConfig.fromAssignmentData(l.data);
        if (bcfg.durationMinutes > 0) {
          secLeft = bcfg.durationMinutes * 60;
        }
      }
      final authForQuiz = context.read<AuthBloc>().state;
      final sid = authForQuiz is AuthAuthenticated ? authForQuiz.user.id : '';
      _QuizSessionLayout? quizLayout;
      if (m?.type == 'quiz') {
        final raw = m!.config?['questions'] as List<dynamic>? ?? [];
        final shuffle = m.config?['quizShuffle'] == true;
        final seed = Object.hash(l.assignmentId, l.methodId, sid);
        quizLayout = _buildQuizSessionLayout(raw, shuffle, seed);
      }
      TSchemaMethodConfig? tSchemaCfg;
      int? tSchemaSecLeft;
      if (m?.type == 'fishbone') {
        tSchemaCfg = TSchemaMethodConfig.tryParse(m?.config);
        if (tSchemaCfg != null && tSchemaCfg.durationMinutes > 0) {
          tSchemaSecLeft = tSchemaCfg.durationMinutes * 60;
        }
      }
      CaseCyberTask? caseCyber;
      if (m?.type == 'case') {
        final topicLabel =
            CurriculumPresets.topicLabel(l.subjectId, l.classId, l.topicId);
        caseCyber = CaseStudyBank.resolveTask(
          classId: l.classId,
          topicLabel: topicLabel,
          assignmentData: l.data,
          methodConfig: m?.config,
          seed: Object.hash(l.assignmentId, l.methodId),
        );
      }
      setState(() {
        _lookup = l;
        _method = m;
        _brainstormConfig = bcfg;
        _secondsLeft = secLeft;
        _timeExpired = false;
        _quizChoices.clear();
        _quizTimeOk.clear();
        _quizLayout = quizLayout;
        _tSchemaConfig = tSchemaCfg;
        _tSchemaSecondsLeft = tSchemaSecLeft;
        _tSchemaTimeExpired = false;
        _caseCyberTask = caseCyber;
        if (m?.type == 'quiz') {
          final qs = m?.config?['questions'] as List<dynamic>? ?? [];
          _ensureQuizSidecars(qs.length);
        }
        _loading = m?.type == 'quiz';
      });
      if (m?.type == 'brainstorm' && secLeft != null && secLeft > 0) {
        _startBrainstormTimer();
      }
      if (m?.type == 'fishbone' &&
          tSchemaCfg != null &&
          tSchemaSecLeft != null &&
          tSchemaSecLeft > 0) {
        _startTSchemaTimer();
      }
      final auth = context.read<AuthBloc>().state;
      if (auth is AuthAuthenticated) {
        final done = await context.read<SubmissionRepository>().hasSubmitted(
              lookup: l,
              studentId: auth.user.id,
            );
        if (!mounted) {
          return;
        }
        if (done) {
          setState(() {
            _alreadySubmitted = true;
            _loading = false;
          });
          return;
        }
      }
      await _restoreDraft();
      if (mounted && m?.type == 'quiz') {
        setState(() => _loading = false);
      }
      if (mounted && m?.type == 'brainstorm' && _brainstormMyIdeas.isNotEmpty) {
        final auth0 = context.read<AuthBloc>().state;
        if (auth0 is AuthAuthenticated) {
          final repo = context.read<SubmissionRepository>();
          final n = await repo.countBrainstormIdeasForStudent(
            lookup: l,
            studentId: auth0.user.id,
          );
          if (n == 0) {
            for (var i = 0; i < _brainstormMyIdeas.length; i++) {
              if (!mounted) {
                break;
              }
              await repo.addBrainstormIdeaToFeed(
                lookup: l,
                studentId: auth0.user.id,
                text: _brainstormMyIdeas[i],
                lineIndex: i,
              );
            }
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _computeQuizScore() {
    final m = _method;
    if (m == null || m.type != 'quiz') return null;
    final qs = m.config?['questions'] as List<dynamic>? ?? [];
    if (qs.isEmpty) return null;
    var ok = 0;
    var inTime = 0;
    for (var i = 0; i < qs.length; i++) {
      final q = qs[i] as Map<String, dynamic>?;
      if (q == null) continue;
      final correct = (q['correctIndex'] as num?)?.toInt();
      final picked = i < _quizChoices.length ? _quizChoices[i] : null;
      if (correct != null && picked != null && correct == picked) {
        ok++;
      }
      final tOk = i < _quizTimeOk.length ? _quizTimeOk[i] : null;
      if (tOk == true) {
        inTime++;
      }
    }
    final acc = ok / qs.length;
    final timeRatio = inTime / qs.length;
    // Aniqlik ~72%, vaqt/tartib ~28% (9-sinf “Aniqlik va tartib” g‘oyasi).
    return (100 * (0.72 * acc + 0.28 * timeRatio)).clamp(0.0, 100.0);
  }

  Map<String, dynamic> _buildAnswerPayload() {
    if (_method == null) {
      return {
        'kind': 'text',
        'text': _textAnswer.text.trim(),
      };
    }
    final t = _method!.type;
    if (t == 'quiz') {
      return {
        'kind': 'quiz',
        'choices': List<int?>.from(_quizChoices),
        'timeOk': List<bool?>.from(_quizTimeOk),
      };
    }
    if (t == 'poll') {
      return {
        'kind': 'poll',
        'choice': _pollChoice,
      };
    }
    if (t == 'brainstorm') {
      final ideas = List<String>.from(_brainstormMyIdeas);
      return {
        'kind': 'brainstorm',
        'ideas': ideas,
        'text': ideas.join('\n'),
      };
    }
    if (t == 'case') {
      final st = _caseCyberKey.currentState;
      if (st != null && _caseCyberTask != null) {
        return st.buildAnswerPayload();
      }
    }
    if (t == 'fishbone') {
      final st = _tSchemaKey.currentState;
      if (st != null && _tSchemaConfig != null) {
        return st.buildAnswerPayload();
      }
    }
    if (t == 'group' && _isGroupClusterMode) {
      return _clusterKey.currentState?.buildAnswerPayload() ??
          {
            'kind': 'text',
            'text': _textAnswer.text.trim(),
          };
    }
    return {
      'kind': 'text',
      'text': _textAnswer.text.trim(),
    };
  }

  Future<void> _submit({bool auto = false}) async {
    final l = _lookup ?? widget.lookup;
    if (l == null) return;
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avval tizimga kiring (o\'quvchi)')),
        );
      }
      return;
    }
    final m = _method;
    if (m == null) {
      if (!auto && _textAnswer.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Javob yozing')),
        );
        return;
      }
    } else if (m.type == 'quiz') {
      // Javob berilmagan va vaqti hali ochiq savollarni «tuugadi» deb belgilash
      final rawQs = m.config?['questions'] as List<dynamic>? ?? [];
      final n = rawQs.length;
      setState(() {
        _ensureQuizSidecars(n);
        for (var i = 0; i < n; i++) {
          final noAnswer =
              i >= _quizChoices.length || _quizChoices[i] == null;
          final timeStillOpen =
              i >= _quizTimeOk.length || _quizTimeOk[i] == null;
          if (noAnswer && timeStillOpen) {
            while (_quizTimeOk.length <= i) {
              _quizTimeOk.add(null);
            }
            _quizTimeOk[i] = false;
          }
        }
      });
    } else if (m.type == 'poll' && _pollChoice == null) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Variant tanlang')),
        );
      }
      return;
    } else if (m.type == 'group' && _isGroupClusterMode) {
      final st = _clusterKey.currentState;
      if (!auto && (st == null || !st.isSessionComplete)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcha to’g’ri tarmoqlarni markazga ulang'),
          ),
        );
        return;
      }
    } else if (m.type == 'brainstorm') {
      // Vaqt tugagan bo’lsa — auto yoki manual ham qabul qilinadi
      final ideas = _brainstormMyIdeas;
      final cfg = _brainstormConfig ?? BrainstormSessionConfig.fallback;
      if (!auto && ideas.length < cfg.minIdeasPerStudent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kamida ${cfg.minIdeasPerStudent} ta fikr «Doskaga yuborish» orqali doskaga qo’ying',
            ),
          ),
        );
        return;
      }
      if (!auto && ideas.length > cfg.maxIdeasPerStudent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O’quvchi faqat ${cfg.maxIdeasPerStudent} tagacha fikr yuboradi',
            ),
          ),
        );
        return;
      }
    } else if (m.type == 'case' && _caseCyberTask != null) {
      if (!auto && _textAnswer.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O’z tahlilingiz va yechim matnini yozing'),
          ),
        );
        return;
      }
    } else if (m.type == 'fishbone' && _tSchemaConfig != null) {
      // Auto bo’lsa: vaqt tugaganda qisman to’ldirilgan holda ham yuboriladi
      if (!auto) {
        final st = _tSchemaKey.currentState;
        if (st == null || !st.isSessionComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Barcha stikerlarni to’g’ri ustunlarga joylang'),
            ),
          );
          return;
        }
      }
    } else if (!auto &&
        m.type != 'quiz' &&
        m.type != 'poll' &&
        !(m.type == 'group' && _isGroupClusterMode) &&
        !(m.type == 'fishbone' && _tSchemaConfig != null) &&
        !(m.type == 'case' && _caseCyberTask != null) &&
        _textAnswer.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Javob yozing')),
      );
      return;
    }

    // Avtomatik yuborishda tasdiq dialogi ko’rsatilmaydi
    if (!auto) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Javobni yuborish'),
          content: const Text(
            'Yakuniy yuborishdan oldin javobingizni tekshiring. Odatda yuborganingizdan '
            'keyin tahrir qilish mumkin emas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yuborish'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    setState(() => _submitting = true);
    try {
      final answer = _buildAnswerPayload();
      final score = m?.type == 'quiz' ? _computeQuizScore() : null;
      await context.read<SubmissionRepository>().submit(
            lookup: l,
            studentId: auth.user.id,
            answer: answer,
            score: score,
          );
      await AssignmentDraftStore.clear(l, auth.user.id);
      if (mounted) {
        final isBs = m?.type == 'brainstorm';
        final cfg = _brainstormConfig;
        final showMedal = !auto &&
            isBs &&
            cfg != null &&
            _brainstormMyIdeas.length >= cfg.minIdeasPerStudent &&
            (cfg.durationMinutes <= 0 || !_timeExpired);
        if (showMedal) {
          await _showCreativityRewardDialog(
            filledAllSlots:
                _brainstormMyIdeas.length >= cfg.maxIdeasPerStudent,
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auto
                  ? (score != null
                      ? 'Vaqt tugadi — avtomatik yuborildi. Ball: ${score.toStringAsFixed(0)}'
                      : 'Vaqt tugadi — avtomatik yuborildi')
                  : (score != null
                      ? 'Yuborildi. Ball: ${score.toStringAsFixed(0)}'
                      : 'Yuborildi'),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addBrainstormIdea(String text) async {
    final l = _lookup ?? widget.lookup;
    final auth = context.read<AuthBloc>().state;
    if (l == null || auth is! AuthAuthenticated) {
      return;
    }
    final t = text.trim();
    if (t.isEmpty) {
      return;
    }
    final cfg = _brainstormConfig ?? BrainstormSessionConfig.fallback;
    if (_brainstormMyIdeas.length >= cfg.maxIdeasPerStudent) {
      return;
    }
    if (_blockSubmitByTimer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vaqt tugadi. Yangi stiker qo‘sha olmaysiz'),
          ),
        );
      }
      return;
    }
    try {
      await context.read<SubmissionRepository>().addBrainstormIdeaToFeed(
            lookup: l,
            studentId: auth.user.id,
            text: t,
            lineIndex: _brainstormMyIdeas.length,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _brainstormMyIdeas.add(t);
        _brainstormInput.clear();
      });
      _scheduleDraftSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showCreativityRewardDialog({required bool filledAllSlots}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 72,
                color: Theme.of(ctx).colorScheme.tertiary,
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 12),
              Text(
                'Kreativ fikrlovchi!',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                filledAllSlots
                    ? 'Barcha slotlar to‘lgan va siz o‘qituvchi talab qilgan fikr limitiga yetdingiz. Sinfdoshlaringizdan ilhom oling — doskada o‘qilar va yurakcha bosing.'
                    : 'Siz o‘qituvchi so‘ragan g‘oyalar soniga yetdingiz, va vaqt doirasida bajarib chiqdingiz. Daftar emas, doska sizniki deb his qiling!',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var k = 0; k < 8; k++)
                    Text(
                      '✨',
                      style: const TextStyle(fontSize: 18),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(),
                        )
                        .shimmer(
                          delay: (k * 80).ms,
                          duration: 900.ms,
                        ),
                ],
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zo‘r!'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _aiStudyCompanionActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'AI yordamchi',
        icon: const Icon(Icons.auto_awesome_outlined),
        onPressed: _submitting ? null : () => _openAiStudyCompanion(context),
      ),
      const AppProfileIcon(),
    ];
  }

  int? _currentQuizDisplayIndex() {
    final layout = _quizLayout;
    if (layout == null || layout.displayQuestions.isEmpty) {
      return null;
    }
    final n = layout.displayQuestions.length;
    for (var i = 0; i < n; i++) {
      if (i >= _quizChoices.length || _quizChoices[i] == null) {
        return i;
      }
    }
    return n - 1;
  }

  String _aiSituationBrief() {
    final l = _lookup;
    final m = _method;
    if (l == null || m == null) return '';
    final rubric = (l.data['rubric'] as String?)?.trim();
    final buf = StringBuffer();
    switch (m.type) {
      case 'quiz':
        buf.writeln('Quiz.');
        final layout = _quizLayout;
        if (layout != null && layout.displayQuestions.isNotEmpty) {
          final idx = _currentQuizDisplayIndex() ?? 0;
          final safe = idx.clamp(0, layout.displayQuestions.length - 1);
          final q = layout.displayQuestions[safe];
          buf.writeln('Savol ${safe + 1} / ${layout.displayQuestions.length}.');
          buf.writeln('Matn: ${q['question'] ?? q['text'] ?? '—'}');
          if (safe < _quizChoices.length && _quizChoices[safe] != null) {
            buf.writeln('Tanlangan variant (indeks): ${_quizChoices[safe]}');
          }
        }
        break;
      case 'brainstorm':
        buf.writeln('Aqliy hujum.');
        final p = m.config?['prompt'] as String?;
        if (p != null && p.trim().isNotEmpty) {
          buf.writeln('Mavzu: ${p.trim()}');
        }
        buf.writeln('G\'oyalar: ${_brainstormMyIdeas.length}.');
        if (_brainstormMyIdeas.isNotEmpty) {
          buf.writeln(_brainstormMyIdeas.take(15).join(' | '));
        }
        break;
      case 'fishbone':
        buf.writeln('T-sxema.');
        final cfg = _tSchemaConfig;
        if (cfg != null) {
          buf.writeln('Markaz: ${cfg.center}');
          buf.writeln('Chap: ${cfg.leftTitle}; O\'ng: ${cfg.rightTitle}');
        }
        break;
      case 'group':
        buf.writeln('Klaster.');
        try {
          buf.writeln('Markaz: ${_groupCenterLabel(l)}');
          final b = _buildStudentClusterBranchList();
          buf.writeln('Tarmoqlar: ${b.length}');
        } catch (_) {}
        break;
      case 'case':
        buf.writeln('Case-study.');
        final ct = _caseCyberTask;
        if (ct != null) {
          final sn = ct.scenario;
          buf.writeln(sn.length > 280 ? '${sn.substring(0, 280)}…' : sn);
        }
        break;
      case 'poll':
        buf.writeln('So\'rovnoma. Tanlov: $_pollChoice');
        break;
      default:
        buf.writeln('Metod: ${m.type}');
    }
    if (rubric != null && rubric.isNotEmpty) {
      buf.writeln();
      buf.writeln(
        'Mezonlar: ${rubric.length > 500 ? '${rubric.substring(0, 500)}…' : rubric}',
      );
    }
    return buf.toString().trim();
  }

  Future<void> _openBrainstormClusterSheet(
    BuildContext context,
    String apiKey,
    AppLocalizations l10n,
  ) async {
    final l = _lookup;
    final m = _method;
    if (l == null || m?.type != 'brainstorm') return;
    final pRaw = m!.config?['prompt'] as String?;
    final title = l.data['title'] as String? ?? 'Aqliy hujum';
    final prompt = (pRaw != null && pRaw.trim().isNotEmpty)
        ? pRaw.trim()
        : title;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.aiReviewLoading)),
          ],
        ),
      ),
    );

    String? text;
    Object? err;
    try {
      text = await GeminiMethodCoach.brainstormClusterDraft(
        apiKey: apiKey,
        topicPrompt: prompt,
        ideas: List<String>.from(_brainstormMyIdeas),
      );
    } catch (e) {
      err = e;
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (err != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
      }
      return;
    }
    if (!context.mounted || (text ?? '').isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI: g\'oyalarni guruhlash'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(child: SelectableText(text!)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _openAiStudyCompanion(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiKeyMissing)),
      );
      return;
    }
    final l = _lookup;
    final title = (l?.data['title'] as String?) ?? 'Topshiriq';
    final methodType = _method?.type ?? 'noma\'lum';
    final brief = _aiSituationBrief();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'AI yordamchi',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.aiDisclaimer,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: GeminiMethodCoach.studyCompanionNudge(
                    apiKey: key,
                    methodType: methodType,
                    assignmentTitle: title,
                    situationBrief: brief,
                  ),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return SelectableText('${snap.error}');
                    }
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return SelectableText(snap.data ?? '—');
                  },
                ),
                const SizedBox(height: 12),
                if (_method?.type == 'brainstorm' && _brainstormMyIdeas.length >= 2)
                  OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _openBrainstormClusterSheet(context, key, l10n);
                          },
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('G\'oyalarni AI bilan guruhlash'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _lookup ?? widget.lookup;
    if (l == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('Bajarish'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: Text('Topshiriq topilmadi')),
      );
    }
    final title = l.data['title'] as String? ?? 'Topshiriq';
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: Text(title),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_alreadySubmitted) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: Text(title),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Siz ushbu topshiriqni allaqachon yuborgansiz. '
                  'Javobingiz, ball va o\'qituvchi / AI izohlarini quyidagida ko\'rishingiz mumkin.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final loc = _lookup ?? widget.lookup;
                if (loc == null) {
                  return;
                }
                context.push(AppRoutes.studentSubmission, extra: loc);
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Yuborilgan javob va izohlarni ko\'rish'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Orqaga'),
            ),
          ],
        ),
      );
    }
    final auth = context.watch<AuthBloc>().state;
    final loggedIn = auth is AuthAuthenticated;
    final m = _method;
    final isBrainBoard =
        m?.type == 'brainstorm' && _brainstormConfig != null;

    if (isBrainBoard) {
      final mm = m!;
      final cfg = _brainstormConfig!;
      final c = mm.config;
      final pRaw = c?['prompt'] as String?;
      final prompt = (pRaw != null && pRaw.trim().isNotEmpty)
          ? pRaw.trim()
          : (l.data['title'] as String? ?? title);
      final guide = c?['brainstormGuide'] as String?;
      final rubric = (l.data['rubric'] as String?)?.trim() ?? '';
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(
            l.data['title'] as String? ?? 'Aqliy hujum',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: _aiStudyCompanionActions(context),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!loggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const ListTile(
                    title: Text('Topshiriqni bajarish uchun tizimga kiring'),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: BrainstormStudentExperience(
                  lookup: l,
                  config: cfg,
                  mainPrompt: prompt,
                  guide: guide,
                  assignmentCode: l.data['code'] as String?,
                  rubric: rubric,
                  secondsLeft: _secondsLeft,
                  timeExpired: _timeExpired,
                  formatMmSs: _mmSs,
                  blockSession: _blockSubmitByTimer,
                  loggedIn: loggedIn,
                  myIdeas: _brainstormMyIdeas,
                  ideaInput: _brainstormInput,
                  onAddIdea: _addBrainstormIdea,
                  onFinalSubmit: _submit,
                  isSubmitting: _submitting,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: _submitting ? null : () => context.pop(),
                child: const Text('Orqaga'),
              ),
            ),
          ],
        ),
      );
    }

    final tSchemaCfg = _tSchemaConfig;
    if (m?.type == 'fishbone' && tSchemaCfg != null) {
      final seed = Object.hash(l.assignmentId, l.methodId);
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: _aiStudyCompanionActions(context),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!loggedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const ListTile(
                      title: Text('Topshiriqni bajarish uchun tizimga kiring'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Kod: ${l.data['code'] ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if ((l.data['rubric'] as String?)?.trim().isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Card(
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text('Baholash mezonlari'),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          SelectableText('${l.data['rubric']}'),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                  child: TSchemaInteractiveSolver(
                    key: _tSchemaKey,
                    config: tSchemaCfg,
                    shuffleSeed: seed,
                    initialDraft: _tSchemaDraftRestore,
                    onStateChanged: () {
                      setState(() {});
                      _scheduleDraftSave();
                    },
                    secondsLeft: _tSchemaSecondsLeft,
                    timeExpired: _tSchemaTimeExpired,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomButton(
                      label: 'Yuborish',
                      isLoading: _submitting,
                      onPressed: (!loggedIn || _submitting) ? null : _submit,
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        child: const Text('Orqaga'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final caseTask = _caseCyberTask;
    if (m?.type == 'case' && caseTask != null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: _aiStudyCompanionActions(context),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!loggedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const ListTile(
                      title: Text('Topshiriqni bajarish uchun tizimga kiring'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  'Kod: ${l.data['code'] ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if ((l.data['rubric'] as String?)?.trim().isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Card(
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text('Baholash mezonlari'),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          SelectableText('${l.data['rubric']}'),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: CaseStudyCyberExperience(
                    key: _caseCyberKey,
                    task: caseTask,
                    reflectionController: _textAnswer,
                    onChanged: () {
                      setState(() {});
                      _scheduleDraftSave();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomButton(
                      label: 'Yuborish',
                      isLoading: _submitting,
                      onPressed: (!loggedIn || _submitting) ? null : _submit,
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        child: const Text('Orqaga'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (m?.type == 'group' && _isGroupClusterMode) {
      final branches = _buildStudentClusterBranchList();
      final centerLabel = _groupCenterLabel(l);
      final narrow = MediaQuery.sizeOf(context).shortestSide < 600;
      final codeStr = l.data['code']?.toString() ?? '—';
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: _aiStudyCompanionActions(context),
        ),
        body: SafeArea(
          top: true,
          bottom: false,
          left: true,
          right: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!loggedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const ListTile(
                      title: Text('Topshiriqni bajarish uchun tizimga kiring'),
                    ),
                  ),
                ),
              if (!narrow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    'Kod: $codeStr',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if ((l.data['rubric'] as String?)?.trim().isNotEmpty ??
                  false) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        title: const Text('Baholash mezonlari'),
                        initiallyExpanded: false,
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          SelectableText('${l.data['rubric']}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                  child: ClusterStudentExperience(
                    key: _clusterKey,
                    center: centerLabel,
                    branches: branches,
                    assignmentCode: narrow ? codeStr : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.shadow.withValues(
                alpha: 0.12,
              ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomButton(
                    label: 'Yuborish',
                    isLoading: _submitting,
                    onPressed: (!loggedIn || _submitting) ? null : _submit,
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : () => context.pop(),
                      child: const Text('Orqaga'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: Text(title),
        actions: _aiStudyCompanionActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Kod: ${l.data['code'] ?? '—'}'),
          const SizedBox(height: 8),
          if (!loggedIn)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const ListTile(
                title: Text('Topshiriqni yuborish uchun tizimga kiring.'),
              ),
            ),
          const SizedBox(height: 16),
          if ((l.data['rubric'] as String?)?.trim().isNotEmpty ?? false) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baholash mezonlari',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    SelectableText('${l.data['rubric']}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ..._methodContextTiles(context),
          if (_method?.type == 'quiz') _buildQuiz(context),
          if (_method?.type == 'poll') _buildPoll(context),
          if (_method == null ||
              (_method!.type != 'quiz' && _method!.type != 'poll'))
            _buildTextAnswerField(context),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Yuborish',
            isLoading: _submitting,
            onPressed: (!loggedIn || _submitting) ? null : _submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Orqaga'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAnswerField(BuildContext context) {
    return TextField(
      controller: _textAnswer,
      onChanged: (_) => _scheduleDraftSave(),
      decoration: InputDecoration(
        labelText: _textAnswerLabel(),
        border: const OutlineInputBorder(),
      ),
      minLines: 3,
      maxLines: 8,
    );
  }

  String _textAnswerLabel() {
    final m = _method;
    if (m == null) return 'Javob (metod yuklanmagan bo\'lsa)';
    switch (m.type) {
      case 'case':
        return 'Tahlil va yechim (matn)';
      case 'brainstorm':
        return 'Fikrlaringiz (g\'oyalar oqimi)';
      case 'role_play':
        return 'Rol bo\'yicha javob (matn)';
      case 'fishbone':
        return 'T-sxema bo\'yicha javob (matn)';
      case 'group':
        return 'Guruh ishi javobi';
      default:
        return 'Javob';
    }
  }

  /// Klaster: o‘qituvchi `isDistractor` yashiradi — barcha tarmoqlar bir xil chip.
  List<Widget> _groupBranchChipsForRow(Object? raw) {
    if (raw is! Map) return const <Widget>[];
    final t = '${raw['text'] ?? ''}'.trim();
    if (t.isEmpty) return const <Widget>[];
    return [
      Chip(
        label: Text(
          t,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }

  List<Widget> _methodContextTiles(BuildContext context) {
    final m = _method;
    if (m == null) return [];
    final c = m.config;
    final out = <Widget>[];
    final cfgTitle = c?['title'] as String?;
    if (cfgTitle != null && cfgTitle.trim().isNotEmpty) {
      out.add(
        Text(
          cfgTitle.trim(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
      out.add(const SizedBox(height: 12));
    }
    void addBlock(String label, String? text) {
      if (text == null || text.trim().isEmpty) return;
      out.add(Text(label, style: Theme.of(context).textTheme.titleSmall));
      out.add(const SizedBox(height: 6));
      out.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
      out.add(const SizedBox(height: 12));
    }

    switch (m.type) {
      case 'case':
        addBlock('Vaziyat (case-study)', c?['scenario'] as String?);
        break;
      case 'brainstorm':
        addBlock('Savol (aqliy hujum)', c?['prompt'] as String?);
        final bg = c?['brainstormGuide'] as String?;
        if (bg != null && bg.trim().isNotEmpty) {
          addBlock('Yo‘riqnoma', bg.trim());
        }
        break;
      case 'role_play':
        addBlock('Rollar', c?['roles'] as String?);
        addBlock('Vaziyat', c?['scenario'] as String?);
        break;
      case 'fishbone':
        addBlock('T-sxema (yordamchi matn)', c?['sxema'] as String?);
        addBlock(
          'Markaziy muammo',
          (c?['tSchemaCenter'] ?? c?['problem']) as String?,
        );
        final leftList = c?['tSchemaLeftItems'];
        final interactive = c?['tSchemaInteractive'] == true ||
            (leftList is List && leftList.isNotEmpty);
        if (!interactive) {
          addBlock('Yo\'nalishlar va sabablar', c?['branches'] as String?);
        }
        break;
      case 'group':
        addBlock('Ko\'rsatma', c?['instructions'] as String?);
        if (_isGroupClusterMode) {
          break;
        }
        final center = c?['center'] as String?;
        if (center != null && center.trim().isNotEmpty) {
          out.add(
            Text(
              'Markaziy tushuncha',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
          out.add(const SizedBox(height: 6));
          out.add(
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  center.trim(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
          out.add(const SizedBox(height: 12));
        }
        final br = c?['branches'] as List<dynamic>?;
        if (br != null && br.isNotEmpty) {
          out.add(
            Text(
              'Tarmoqlar',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
          out.add(const SizedBox(height: 6));
          out.add(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final raw in br) ..._groupBranchChipsForRow(raw),
              ],
            ),
          );
          out.add(const SizedBox(height: 12));
        }
        break;
      default:
        break;
    }
    return out;
  }

  Widget _buildQuiz(BuildContext context) {
    final layout = _quizLayout;
    final rawQs = _method?.config?['questions'] as List<dynamic>? ?? [];
    if (layout == null || layout.displayQuestions.isEmpty || rawQs.isEmpty) {
      return const Text('O\'qituvchi hali quiz savollarini kiritmagan.');
    }
    final sec = (_method?.config?['quizSecondsPerQuestion'] as num?)?.toInt().clamp(5, 60) ??
        25;
    final sh = _method?.config?['quizShuffle'] == true;
    return _InteractiveQuizHost(
      key: ValueKey(
        'quiz_${layout.displayQuestions.length}_${sec}_${sh}_${_lookup?.assignmentId}',
      ),
      questions: layout.displayQuestions,
      secondsPerQuestion: sec,
      choiceAtDisplay: _quizChoiceAtDisplay,
      quizSessionResolvedAtDisplay: _quizSessionResolvedAtDisplay,
      onChoiceDisplay: _setQuizAnswerFromDisplay,
      onAnsweredInTimeDisplay: _onQuizAnsweredInTimeForDisplay,
      onTimerExpiredDisplay: _onQuizTimerExpiredForDisplay,
    );
  }

  Widget _buildPoll(BuildContext context) {
    final opts = (_method?.config?['options'] as List<dynamic>?)?.map((e) => '$e').toList() ??
        <String>['Ha', 'Yo\'q', 'Bilmayman'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var j = 0; j < opts.length; j++)
          RadioListTile<int>(
            title: Text(opts[j]),
            value: j,
            groupValue: _pollChoice,
            onChanged: (v) {
              setState(() => _pollChoice = v);
              _scheduleDraftSave();
            },
          ),
      ],
    );
  }
}

const _quizLabels = ['A', 'B', 'C', 'D'];

class _InteractiveQuizHost extends StatefulWidget {
  const _InteractiveQuizHost({
    super.key,
    required this.questions,
    required this.secondsPerQuestion,
    required this.choiceAtDisplay,
    required this.quizSessionResolvedAtDisplay,
    required this.onChoiceDisplay,
    required this.onAnsweredInTimeDisplay,
    required this.onTimerExpiredDisplay,
  });

  final List<Map<String, dynamic>> questions;
  final int secondsPerQuestion;
  final int? Function(int displayIndex) choiceAtDisplay;
  final bool Function(int displayIndex) quizSessionResolvedAtDisplay;
  final void Function(int displayIndex, int optionIndex) onChoiceDisplay;
  final void Function(int displayIndex) onAnsweredInTimeDisplay;
  final void Function(int displayIndex) onTimerExpiredDisplay;

  @override
  State<_InteractiveQuizHost> createState() => _InteractiveQuizHostState();
}

class _InteractiveQuizHostState extends State<_InteractiveQuizHost> {
  late final PageController _pageController;
  Timer? _ticker;
  int _armedIndex = 0;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final resolved0 = widget.quizSessionResolvedAtDisplay(0);
    _armedIndex = 0;
    _remaining = resolved0 ? 0 : widget.secondsPerQuestion;
    if (!resolved0 && _remaining > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTickerForArmedIndex();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTickerForArmedIndex() {
    _ticker?.cancel();
    final idx = _armedIndex;
    if (widget.quizSessionResolvedAtDisplay(idx) || _remaining <= 0) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (_remaining <= 1) {
        _ticker?.cancel();
        setState(() => _remaining = 0);
        final picked = widget.choiceAtDisplay(idx);
        if (picked == null) {
          widget.onTimerExpiredDisplay(idx);
        }
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _armTimerForIndex(int i) {
    _ticker?.cancel();
    if (!mounted) {
      return;
    }
    final resolved = widget.quizSessionResolvedAtDisplay(i);
    setState(() {
      _armedIndex = i;
      _remaining = resolved ? 0 : widget.secondsPerQuestion;
    });
    if (!resolved) {
      _startTickerForArmedIndex();
    }
  }

  void _onPageChanged(int newIndex) {
    if (newIndex == _armedIndex) {
      return;
    }
    _ticker?.cancel();
    final old = _armedIndex;
    if (old >= 0 && old < widget.questions.length) {
      final picked = widget.choiceAtDisplay(old);
      if (picked == null && !widget.quizSessionResolvedAtDisplay(old)) {
        widget.onTimerExpiredDisplay(old);
      }
    }
    _armTimerForIndex(newIndex);
  }

  void _onOptionSelected(int qIndex, int optIndex) {
    if (widget.quizSessionResolvedAtDisplay(qIndex)) {
      return;
    }
    widget.onChoiceDisplay(qIndex, optIndex);
    if (_remaining > 0 && qIndex == _armedIndex) {
      widget.onAnsweredInTimeDisplay(qIndex);
      _ticker?.cancel();
      setState(() => _remaining = 0);
    }
    final n = widget.questions.length;
    if (qIndex < n - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final n = widget.questions.length;
    final resolvedHere = widget.quizSessionResolvedAtDisplay(_armedIndex);
    final showElapsed = resolvedHere || _remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${_armedIndex + 1} / $n',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    showElapsed ? l10n.studentQuizTimeElapsed : '${_remaining}s',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: _armedIndex > 0
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: Text(l10n.studentQuizPrevious),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _armedIndex < n - 1
                  ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: Text(l10n.studentQuizNext),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.54).clamp(320.0, 480.0),
          child: PageView.builder(
            controller: _pageController,
            itemCount: n,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, qi) {
              final q = widget.questions[qi];
              final prompt = '${q['question'] ?? ''}'.trim();
              final optsDyn = q['options'] as List<dynamic>?;
              final opts = optsDyn == null
                  ? <String>[]
                  : optsDyn.map((e) => '$e').toList();
              final picked = widget.choiceAtDisplay(qi);
              final locked = widget.quizSessionResolvedAtDisplay(qi);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: _QuizGlassQuestionCard(
                  prompt: prompt.isEmpty ? 'Savol' : prompt,
                  options: opts,
                  selected: picked,
                  optionsLocked: locked,
                  onSelect: (v) => _onOptionSelected(qi, v),
                ),
              )
                  .animate(key: ValueKey('qcard_$qi'))
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOutCubic);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < n; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == _armedIndex ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _armedIndex
                        ? scheme.primary
                        : scheme.outline.withValues(alpha: 0.35),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuizGlassQuestionCard extends StatelessWidget {
  const _QuizGlassQuestionCard({
    required this.prompt,
    required this.options,
    required this.selected,
    required this.optionsLocked,
    required this.onSelect,
  });

  final String prompt;
  final List<String> options;
  final int? selected;
  final bool optionsLocked;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerLow,
              Color.lerp(
                    scheme.surfaceContainerLow,
                    scheme.primaryContainer,
                    0.35,
                  ) ??
                  scheme.primaryContainer,
              scheme.surface,
            ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              prompt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: options.length.clamp(0, 4),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, j) {
                  if (j >= options.length) {
                    return const SizedBox.shrink();
                  }
                  final sel = selected == j;
                  final letter =
                      j < _quizLabels.length ? _quizLabels[j] : '${j + 1}';
                  final t = options[j].trim();
                  final dim = optionsLocked && !sel;
                  return Opacity(
                    opacity: dim ? 0.48 : 1.0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: optionsLocked ? null : () => onSelect(j),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? scheme.primary
                                  : scheme.outline.withValues(alpha: 0.28),
                              width: sel ? 2 : 1,
                            ),
                            color: sel
                                ? scheme.primary.withValues(alpha: 0.16)
                                : scheme.surface,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: sel
                                    ? scheme.primary
                                    : scheme.secondary.withValues(alpha: 0.28),
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: sel
                                        ? scheme.onPrimary
                                        : scheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t.isEmpty ? '—' : t,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        height: 1.3,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
