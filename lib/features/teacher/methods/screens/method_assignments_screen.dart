import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/utils/assignment_deadline_picker.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../router/app_router.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../../router/assignment_route_args.dart';
import '../../assignments/data/assignment_repository.dart';
import '../data/method_model.dart';
import '../data/method_repository.dart';
import '../teacher_method_editor_nav.dart';

/// Ushbu metodga bog'langan topshiriqlar + mavzu bo'yicha tayyor shablonlar.
class MethodAssignmentsScreen extends StatefulWidget {
  const MethodAssignmentsScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.topicId,
    required this.methodId,
  });

  final String subjectId;
  final String classId;
  final String topicId;
  final String methodId;

  @override
  State<MethodAssignmentsScreen> createState() =>
      _MethodAssignmentsScreenState();
}

class _MethodAssignmentsScreenState extends State<MethodAssignmentsScreen> {
  String? _creatingTemplateId;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};
  bool _bulkBusy = false;

  MethodModel? _quizMethodSnapshot;
  bool _quizMethodLoading = false;

  bool get _isInformatikaQuiz =>
      widget.subjectId == 'informatika' &&
      widget.methodId == CurriculumPresets.quizId;

  @override
  void initState() {
    super.initState();
    if (_isInformatikaQuiz) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reloadQuizMethod());
    }
  }

  Future<void> _reloadQuizMethod() async {
    if (!_isInformatikaQuiz || !mounted) return;
    setState(() => _quizMethodLoading = true);
    try {
      final m = await context.read<MethodRepository>().fetchMethod(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            methodId: widget.methodId,
          );
      if (mounted) {
        setState(() {
          _quizMethodSnapshot = m;
          _quizMethodLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quizMethodSnapshot = null;
          _quizMethodLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _teacherExtraQuizQuestions(
    Map<String, dynamic>? cfg,
  ) {
    final raw = cfg?['teacherExtraQuizQuestions'];
    if (raw is! List) {
      return [];
    }
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) {
        final map = Map<String, dynamic>.from(e);
        final n = InformatikaJsonPresets.normalizeQuizQuestionMap(map);
        if (n != null) {
          out.add(n);
        }
      }
    }
    return out;
  }

  (List<Map<String, dynamic>>, List<Map<String, dynamic>>) _quizBankAndExtras() {
    final topicLabel = CurriculumPresets.topicLabel(
      widget.subjectId,
      widget.classId,
      widget.topicId,
    );
    final bank = InformatikaJsonPresets.quizBankQuestionsForTopic(
      classId: widget.classId,
      topicLabel: topicLabel,
    );
    final extras =
        _teacherExtraQuizQuestions(_quizMethodSnapshot?.config);
    return (bank, extras);
  }

  String _quizCombinedCreateButtonLabel() {
    if (_quizMethodLoading) {
      return 'Yuklanmoqda...';
    }
    final (b, e) = _quizBankAndExtras();
    final n = b.length + e.length;
    if (n == 0) {
      return 'Topshiriq yaratish';
    }
    return 'Topshiriq yaratish ($n savol)';
  }

  int _quizTotalQuestionCount() {
    if (_quizMethodLoading) return 0;
    final (b, e) = _quizBankAndExtras();
    return b.length + e.length;
  }

  Future<void> _createCombinedQuizAssignment() async {
    final (bank, extras) = _quizBankAndExtras();
    final questions = [...bank, ...extras];
    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Savollar ro\'yxati bo\'sh.')),
        );
      }
      return;
    }
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessiya topilmadi')),
      );
      return;
    }
    setState(() => _creatingTemplateId = 'quiz_all');
    try {
      final id = const Uuid().v4();
      final code = generateAssignmentCode();
      final topicLabel = CurriculumPresets.topicLabel(
        widget.subjectId,
        widget.classId,
        widget.topicId,
      );
      final catalogBase = InformatikaJsonPresets.baseTopicName(topicLabel);
      final title =
          'Test (Quiz) · ${widget.classId}-sinf · $catalogBase · ${questions.length} ta savol';

      final emb = <String, dynamic>{
        'title': 'Quiz: $catalogBase',
        'questions': questions,
        'preset': true,
      };
      final sec = _quizMethodSnapshot?.config?['quizSecondsPerQuestion'];
      if (sec is num) {
        emb['quizSecondsPerQuestion'] = sec.toInt().clamp(5, 60);
      }
      emb['quizShuffle'] = _quizMethodSnapshot?.config?['quizShuffle'] == true;

      final data = <String, dynamic>{
        'code': code,
        'title': title,
        'deadline': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'fromPreset': true,
        'presetTemplateId': 'quiz_topic_all',
        'teacherId': auth.user.id,
        'fromInfJsonPreset': true,
        'embeddedMethodConfig': emb,
      };
      await context.read<AssignmentRepository>().createAssignment(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            methodId: widget.methodId,
            assignmentId: id,
            data: data,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yaratildi (${questions.length} savol). Kod: $code')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingTemplateId = null);
      }
    }
  }

  Future<void> _showAddQuizQuestionDialog() async {
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase ulanmagan — savol saqlab bo\'lmaydi.'),
        ),
      );
      return;
    }
    final q = TextEditingController();
    final a = TextEditingController();
    final b = TextEditingController();
    final c = TextEditingController();
    final d = TextEditingController();
    var correct = 0;
    try {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                title: const Text('Yangi savol'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: q,
                        decoration: const InputDecoration(
                          labelText: 'Savol matni',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: a,
                        decoration: const InputDecoration(labelText: 'A variant'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      TextField(
                        controller: b,
                        decoration: const InputDecoration(labelText: 'B variant'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      TextField(
                        controller: c,
                        decoration: const InputDecoration(labelText: 'C variant'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      TextField(
                        controller: d,
                        decoration: const InputDecoration(labelText: 'D variant'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              'To\'g\'ri javob',
                              style: Theme.of(ctx).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: correct,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('A')),
                                DropdownMenuItem(value: 1, child: Text('B')),
                                DropdownMenuItem(value: 2, child: Text('C')),
                                DropdownMenuItem(value: 3, child: Text('D')),
                              ],
                              onChanged: (v) => setLocal(() => correct = v ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Bekor qilish'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Saqlash'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (go != true || !mounted) {
        return;
      }
      final qv = q.text.trim();
      final av = a.text.trim();
      final bv = b.text.trim();
      final cv = c.text.trim();
      final dv = d.text.trim();
      if (qv.isEmpty ||
          av.isEmpty ||
          bv.isEmpty ||
          cv.isEmpty ||
          dv.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcha maydonlarni to\'ldiring.'),
          ),
        );
        return;
      }
      final m = await context.read<MethodRepository>().fetchMethod(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            methodId: widget.methodId,
          );
      if (!mounted) {
        return;
      }
      final base = Map<String, dynamic>.from(m?.config ?? {});
      final rawList = base['teacherExtraQuizQuestions'];
      final list = <dynamic>[
        if (rawList is List) ...rawList,
      ];
      list.add({
        'question': qv,
        'options': [av, bv, cv, dv],
        'correctIndex': correct,
      });
      base['teacherExtraQuizQuestions'] = list;
      await context.read<MethodRepository>().updateMethodConfig(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            methodId: widget.methodId,
            config: base,
          );
      await _reloadQuizMethod();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Savol saqlandi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      q.dispose();
      a.dispose();
      b.dispose();
      c.dispose();
      d.dispose();
    }
  }

  List<Widget> _quizAssignmentBankSlivers(BuildContext context) {
    if (_quizMethodLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ];
    }
    final (bank, extras) = _quizBankAndExtras();
    final rows = <_QuizAssignmentRow>[
      for (var i = 0; i < bank.length; i++)
        _QuizAssignmentRow(
          map: bank[i],
          index1Based: i + 1,
          fromBank: true,
        ),
      for (var j = 0; j < extras.length; j++)
        _QuizAssignmentRow(
          map: extras[j],
          index1Based: bank.length + j + 1,
          fromBank: false,
        ),
    ];
    if (rows.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Ushbu mavzu uchun bazada savol topilmadi. «Savol qo\'shish» '
              'orqali o\'zingiz savol kiritishingiz mumkin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Jami ${rows.length} ta savol (bazadan + o\'qituvchi qo\'shganlari) bitta quizda beriladi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final r = rows[i];
            final qt = '${r.map['question'] ?? ''}'.trim();
            final scheme = Theme.of(context).colorScheme;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                isThreeLine: qt.length > 72,
                leading: Icon(
                  r.fromBank ? Icons.quiz_outlined : Icons.edit_note_outlined,
                  color: scheme.primary,
                ),
                title: Text(
                  qt.isEmpty ? 'Savol' : qt,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(r.fromBank ? 'Bazadan' : 'O\'qituvchi'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(
                        '${r.index1Based}-savol',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: rows.length,
        ),
      ),
    ];
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _confirmDeleteMany(
    List<Map<String, dynamic>> list, {
    required String intro,
  }) async {
    if (list.isEmpty) return;
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Topshiriqlarni o\'chirish'),
          content: Text(
            '$intro Barcha o\'quvchi javoblari (va doskadagi fikrlar) ham '
            'o\'chiriladi. Bu amalni qaytarib bo\'lmaydi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('O\'chirish'),
            ),
          ],
        );
      },
    );
    if (go != true || !mounted) return;
    setState(() => _bulkBusy = true);
    final repo = context.read<AssignmentRepository>();
    try {
      for (final row in list) {
        final id = row['id'] as String? ?? '';
        if (id.isEmpty) continue;
        await repo.deleteAssignment(
          subjectId: widget.subjectId,
          classId: widget.classId,
          topicId: widget.topicId,
          methodId: widget.methodId,
          assignmentId: id,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${list.length} ta topshiriq o\'chirildi',
            ),
          ),
        );
        _exitSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _bulkBusy = false);
      }
    }
  }

  void _openEditAssignment(String assignmentId) {
    context.push(
      AppRoutes.teacherEditAssignment,
      extra: AssignmentRouteArgs(
        subjectId: widget.subjectId,
        classId: widget.classId,
        topicId: widget.topicId,
        methodId: widget.methodId,
        assignmentId: assignmentId,
      ),
    );
  }

  Future<void> _openMethodConfig() async {
    final m = await context.read<MethodRepository>().fetchMethod(
          subjectId: widget.subjectId,
          classId: widget.classId,
          topicId: widget.topicId,
          methodId: widget.methodId,
        );
    if (!mounted) return;
    if (m == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metod topilmadi')),
      );
      return;
    }
    await pushTeacherMethodEditorScreen(
      context,
      m,
      subjectId: widget.subjectId,
      classId: widget.classId,
      topicId: widget.topicId,
    );
    if (mounted && _isInformatikaQuiz) {
      await _reloadQuizMethod();
    }
  }

  String _rowTitleForPresetIndex(int i0) {
    return CurriculumPresets.readyPresetRowTitle(
      methodId: widget.methodId,
      classId: widget.classId,
      subjectId: widget.subjectId,
      topicId: widget.topicId,
      taskNumber1Based: i0 + 1,
    );
  }

  /// Aqliy hujum: barcha sinflar uchun aynan JSON `questions[...]` (boshqa hollarda shablon).
  Widget? _presetSubtitle(PresetAssignmentTemplate t, int index0) {
    String? s;
    if (widget.subjectId == 'informatika' &&
        widget.methodId == CurriculumPresets.brainstormId) {
      s = InformatikaJsonPresets.brainstormJsonQuestionAt(
        classId: widget.classId,
        topicLabel: CurriculumPresets.topicLabel(
          widget.subjectId,
          widget.classId,
          widget.topicId,
        ),
        slotIndex0: index0,
      )?.trim();
    }
    s ??= t.subtitle?.trim();
    if (s == null || s.isEmpty) {
      return null;
    }
    return Text(
      s,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _createFromTemplate(
    PresetAssignmentTemplate t,
    int listIndex0,
  ) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessiya topilmadi')),
      );
      return;
    }
    setState(() => _creatingTemplateId = t.id);
    try {
      final id = const Uuid().v4();
      final code = generateAssignmentCode();
      final title = _rowTitleForPresetIndex(listIndex0);
      final data = <String, dynamic>{
        'code': code,
        'title': title,
        'deadline': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
        'fromPreset': true,
        'presetTemplateId': t.id,
        'teacherId': auth.user.id,
        if (t.assignmentDataExtras != null) ...t.assignmentDataExtras!,
      };
      if (widget.subjectId == 'informatika' &&
          widget.methodId == CurriculumPresets.brainstormId) {
        final bySlot = InformatikaJsonPresets.brainstormAssignmentExtrasBySlot(
          classId: widget.classId,
          topicLabel: CurriculumPresets.topicLabel(
            widget.subjectId,
            widget.classId,
            widget.topicId,
          ),
          slotIndex0: listIndex0,
        );
        if (bySlot != null) {
          for (final e in bySlot.entries) {
            data[e.key] = e.value;
          }
        }
        final emb = data['embeddedMethodConfig'];
        final prompt = emb is Map
            ? (emb['prompt'] as String? ?? '').trim()
            : '';
        if (prompt.isEmpty) {
          final sub = t.subtitle?.trim();
          if (sub != null && sub.isNotEmpty) {
            final extra = InformatikaJsonPresets
                .brainstormAssignmentExtrasFromPlainQuestion(
              assignmentConfigTitle: t.title,
              questionText: sub,
            );
            for (final e in extra.entries) {
              data[e.key] = e.value;
            }
          }
        }
      }
      await context.read<AssignmentRepository>().createAssignment(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            methodId: widget.methodId,
            assignmentId: id,
            data: data,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yaratildi. Kod: $code')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingTemplateId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AssignmentRepository>();
    final presets = CurriculumPresets.presetAssignmentTemplatesForMethod(
      subjectId: widget.subjectId,
      classId: widget.classId,
      topicId: widget.topicId,
      methodId: widget.methodId,
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('Topshiriqlar'),
        actions: [
          if (_selectionMode)
            TextButton(
              onPressed: _exitSelection,
              child: const Text('Bekor qilish'),
            ),
          const AppProfileIcon(),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repo.watchAssignmentsForMethod(
          subjectId: widget.subjectId,
          classId: widget.classId,
          topicId: widget.topicId,
          methodId: widget.methodId,
        ),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;

          return CustomScrollView(
            slivers: [
              if (_bulkBusy)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subjectId == 'informatika' &&
                          widget.methodId == CurriculumPresets.brainstormId) ...[
                        Text(
                          'Topshiriq yaratish',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mavzu va savollarni quyidagi bazadan tanlang (yoki o\'z '
                          'savolingizni kiriting, sessiya sozlamalari — u yerda).',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            context.pushNamed(
                              'teacherBrainstormQuestionBank',
                              extra: BrainstormQuestionBankRouteArgs(
                                subjectId: widget.subjectId,
                                classId: widget.classId,
                                topicId: widget.topicId,
                                methodId: widget.methodId,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.library_books_outlined,
                            size: 20,
                          ),
                          label: const Text(
                            'Tayyor savollar bazasi (tanlash · tahrir)',
                          ),
                        ),
                      ] else if (_isInformatikaQuiz) ...[
                        Text(
                          'Mavzu bo\'yicha savollar',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bazadagi va o\'zingiz qo\'shgan barcha savollar bitta kodli '
                          'quiz topshirig\'ida beriladi (muddat: 7 kun).',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _quizMethodLoading ||
                                      _creatingTemplateId == 'quiz_all' ||
                                      _quizTotalQuestionCount() == 0
                                  ? null
                                  : () => _createCombinedQuizAssignment(),
                              icon: _creatingTemplateId == 'quiz_all'
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.assignment_turned_in_outlined),
                              label: Text(_quizCombinedCreateButtonLabel()),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _quizMethodLoading
                                  ? null
                                  : _showAddQuizQuestionDialog,
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              label: const Text('Savol qo\'shish'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openMethodConfig,
                              icon: const Icon(Icons.tune_outlined, size: 20),
                              label: const Text('Quiz sozlamalari'),
                            ),
                          ],
                        ),
                      ] else if (presets.isNotEmpty) ...[
                        Text(
                          'Tayyor topshiriqlar',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bir bosishda kod bilan yaratiladi (muddat: 7 kun)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ] else if (widget.methodId ==
                          CurriculumPresets.groupId) ...[
                        Text(
                          'Klaster topshiriqlari',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kodli topshiriqni «Metodlar → Klaster» ekranidagi '
                          '«Kodli topshiriq yaratish» tugmasi bilan yarating. '
                          'Quyida faol topshiriqlar ro\'yxati.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isInformatikaQuiz) ..._quizAssignmentBankSlivers(context),
              if (presets.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                    final t = presets[i];
                    final busy = _creatingTemplateId == t.id;
                    final ov = Theme.of(context).colorScheme.onSurfaceVariant;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        isThreeLine: _presetSubtitle(t, i) != null,
                        leading: const Icon(Icons.assignment_turned_in_outlined),
                        title: Text(
                          _rowTitleForPresetIndex(i),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: _presetSubtitle(t, i),
                        trailing: busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!(widget.subjectId == 'informatika' &&
                                      widget.methodId ==
                                          CurriculumPresets.brainstormId))
                                    IconButton(
                                      tooltip: 'Metodni tahrirlash',
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: ov,
                                      ),
                                      onPressed: _openMethodConfig,
                                    ),
                                  FilledButton.tonal(
                                    onPressed: () {
                                      if (widget.methodId ==
                                          CurriculumPresets.brainstormId) {
                                        context.push(
                                          AppRoutes.teacherCreateBrainstormTask,
                                          extra: CreateBrainstormTaskRouteArgs(
                                            subjectId: widget.subjectId,
                                            classId: widget.classId,
                                            topicId: widget.topicId,
                                            methodId: widget.methodId,
                                            template: t,
                                            listIndex0: i,
                                          ),
                                        );
                                      } else {
                                        _createFromTemplate(t, i);
                                      }
                                    },
                                    child: const Text('Yaratish'),
                                  ),
                                ],
                              ),
                      ),
                    );
                    },
                    childCount: presets.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'Faol topshiriqlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        (widget.subjectId == 'informatika' &&
                                widget.methodId == CurriculumPresets.quizId)
                            ? 'Hozircha kodli topshiriq yo\'q. Yuqoridagi «Topshiriq yaratish» '
                                'tugmasi bilan bitta quiz yarating.'
                            : (widget.subjectId == 'informatika' &&
                                    widget.methodId == CurriculumPresets.brainstormId)
                                ? 'Hozircha yaratilgan topshiriq yo\'q. «Tayyor '
                                    'savollar bazasi» yoki metodlar ekranidan yangi '
                                    'topshiriq yarating.'
                                : (widget.methodId == CurriculumPresets.groupId)
                                ? 'Hozircha faol topshiriq yo\'q. «Metodlar → Klaster» '
                                    'sahifasida «Kodli topshiriq yaratish» orqali '
                                    'kod bering.'
                                : 'Hozircha yaratilgan topshiriq yo\'q. Yuqoridagi '
                                    'shablonlardan foydalaning yoki metodlar '
                                    'ekranidan qo\'shimcha yarating.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _selectionMode
                        ? Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _bulkBusy ? null : _exitSelection,
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text(
                                  'Tanlab o\'chirishni bekor qilish',
                                ),
                              ),
                              Text(
                                '${_selectedIds.length} ta tanlangan',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              TextButton(
                                onPressed: _bulkBusy
                                    ? null
                                    : () {
                                        setState(() {
                                          for (final r in list) {
                                            final sid =
                                                r['id'] as String? ?? '';
                                            if (sid.isNotEmpty) {
                                              _selectedIds.add(sid);
                                            }
                                          }
                                        });
                                      },
                                child: const Text('Hammasini belgilash'),
                              ),
                              TextButton(
                                onPressed: _bulkBusy
                                    ? null
                                    : () => setState(
                                          _selectedIds.clear,
                                        ),
                                child: const Text('Belgilashni tozalash'),
                              ),
                              FilledButton.tonal(
                                onPressed: _bulkBusy || _selectedIds.isEmpty
                                    ? null
                                    : () {
                                        final sel = list
                                            .where(
                                              (r) => _selectedIds.contains(
                                                r['id'] as String? ?? '',
                                              ),
                                            )
                                            .toList();
                                        _confirmDeleteMany(
                                          sel,
                                          intro:
                                              'Tanlangan topshiriqlar o\'chiriladi.',
                                        );
                                      },
                                child: const Text('Tanlanganlarni o\'chirish'),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _bulkBusy
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectionMode = true;
                                          _selectedIds.clear();
                                        });
                                      },
                                icon: const Icon(
                                  Icons.checklist_outlined,
                                  size: 20,
                                ),
                                label: const Text('Tanlab o\'chirish'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _bulkBusy
                                    ? null
                                    : () => _confirmDeleteMany(
                                          List<Map<String, dynamic>>.from(
                                            list,
                                          ),
                                          intro:
                                              'Ushbu metoddagi barcha topshiriqlar '
                                              '(${list.length} ta) o\'chiriladi.',
                                        ),
                                icon: const Icon(
                                  Icons.delete_sweep_outlined,
                                  size: 20,
                                ),
                                label: const Text('Barchasini o\'chirish'),
                              ),
                            ],
                          ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final row = list[i];
                      final id = row['id'] as String? ?? '';
                      final title = row['title'] as String? ?? '—';
                      final code = row['code'] as String? ?? '—';
                      final deadline = row['deadline'];
                      String deadlineStr = '—';
                      if (deadline is Timestamp) {
                        deadlineStr = formatAssignmentDeadlineDateTime(
                          deadline.toDate(),
                        );
                      }
                      return ListTile(
                        leading: _selectionMode
                            ? SizedBox(
                                width: 32,
                                height: 32,
                                child: Checkbox(
                                  value: _selectedIds.contains(id),
                                  onChanged: _bulkBusy
                                      ? null
                                      : (v) {
                                          setState(() {
                                            if (v == true) {
                                              _selectedIds.add(id);
                                            } else {
                                              _selectedIds.remove(id);
                                            }
                                          });
                                        },
                                ),
                              )
                            : null,
                        title: Text(title),
                        subtitle: Text('Kod: $code · Muddat: $deadlineStr'),
                        trailing: _selectionMode
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Topshiriqni tahrirlash',
                                    onPressed: () => _openEditAssignment(id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_outlined),
                                    tooltip: 'Kodni nusxalash',
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: code),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Kod buferga nusxalandi',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const Icon(Icons.analytics_outlined, size: 20),
                                ],
                              ),
                        onTap: _selectionMode
                            ? () {
                                setState(() {
                                  if (_selectedIds.contains(id)) {
                                    _selectedIds.remove(id);
                                  } else {
                                    _selectedIds.add(id);
                                  }
                                });
                              }
                            : () {
                                context.push(
                                  AppRoutes.teacherAssignmentResults,
                                  extra: AssignmentRouteArgs(
                                    subjectId: widget.subjectId,
                                    classId: widget.classId,
                                    topicId: widget.topicId,
                                    methodId: widget.methodId,
                                    assignmentId: id,
                                  ),
                                );
                              },
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _QuizAssignmentRow {
  const _QuizAssignmentRow({
    required this.map,
    required this.index1Based,
    required this.fromBank,
  });

  final Map<String, dynamic> map;
  final int index1Based;
  final bool fromBank;
}
