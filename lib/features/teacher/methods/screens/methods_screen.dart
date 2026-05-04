import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/method_types.dart';
import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/services/teacher_last_route_prefs.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../../core/widgets/tablet_constrained_body.dart';
import '../../../../core/widgets/teacher_list_search_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../../router/assignment_route_args.dart';
import '../bloc/method_bloc.dart';
import '../bloc/method_event.dart';
import '../bloc/method_state.dart';
import '../data/method_model.dart';
import '../data/method_repository.dart';
import '../teacher_method_editor_nav.dart';
import '../widgets/teacher_method_grid_card.dart';

class MethodsScreen extends StatefulWidget {
  const MethodsScreen({
    super.key,
    required this.subjectId,
    required this.classId,
    required this.topicId,
  });

  final String subjectId;
  final String classId;
  final String topicId;

  @override
  State<MethodsScreen> createState() => _MethodsScreenState();
}

class _MethodsScreenState extends State<MethodsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      TeacherLastRoutePrefs.save(
        classId: widget.classId,
        subjectId: widget.subjectId,
        topicId: widget.topicId,
        depth: TeacherLastDepth.methods,
      );
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<MethodBloc>().add(
          MethodLoadRequested(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
          ),
        );
  }

  Future<void> _deleteMethod(BuildContext context, MethodModel m) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDeleteDialog(
      context,
      title: l10n.teacherMethodDeleteTitle,
      message: l10n.teacherMethodDeleteMessage(_methodDisplayTitle(m)),
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<MethodRepository>().deleteMethod(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            methodId: m.id,
          );
      if (context.mounted) {
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.teacherMethodDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  /// Tayyor metod: odatda topshiriqlar ro'yxati; klaster (`group`) — asosan tahrir ekrani.
  void _openFromMethodsList(BuildContext context, MethodModel m) {
    if (CurriculumPresets.isPresetMethodId(m.id)) {
      if (m.type == 'group') {
        _openMethod(context, m);
        return;
      }
      context.push(
        AppRoutes.teacherMethodAssignmentsList(
          widget.classId,
          widget.subjectId,
          widget.topicId,
          m.id,
        ),
      );
      return;
    }
    _openMethod(context, m);
  }

  void _openMethod(BuildContext context, MethodModel m) {
    pushTeacherMethodEditorScreen(
      context,
      m,
      subjectId: widget.subjectId,
      classId: widget.classId,
      topicId: widget.topicId,
    );
  }

  /// Aqliy hujum → Muammoli vaziyat → Klaster → Test (Quiz) → T-sxema
  static const List<MethodType> _addableMethodTypes = [
    MethodType.brainstorm,
    MethodType.caseStudy,
    MethodType.groupWork,
    MethodType.quiz,
    MethodType.fishbone,
  ];

  static int _methodGridCrossAxisCount(double width) {
    if (width >= 1000) {
      return 4;
    }
    if (width >= 640) {
      return 3;
    }
    return 2;
  }

  Future<void> _addMethod(BuildContext context) async {
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final mq = MediaQuery.sizeOf(ctx);
        final w = math.min(440.0, mq.width - 48);
        final cross = mq.width < 340 ? 1 : 2;
        return AlertDialog(
          title: const Text('Metod turini tanlang'),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          content: SizedBox(
            width: w,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cross,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: cross == 1 ? 1.34 : 1.22,
              children: [
                for (final mt in _addableMethodTypes)
                  TeacherMethodGridCard(
                    methodType: mt.firestoreValue,
                    methodName: _methodTitle(mt),
                    onOpen: () => Navigator.pop(ctx, mt.firestoreValue),
                    showBoshlash: false,
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (type == null || !context.mounted) return;
    try {
      await context.read<MethodRepository>().createMethod(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: widget.topicId,
            type: type,
          );
      if (context.mounted) _reload();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _createAssignment(BuildContext context) async {
    final state = context.read<MethodBloc>().state;
    final methods = state is MethodLoaded ? state.methods : <MethodModel>[];
    if (methods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval metod yarating')),
      );
      return;
    }
    MethodModel? picked = methods.length == 1 ? methods.first : null;
    if (methods.length > 1 && context.mounted) {
      picked = await showDialog<MethodModel>(
        context: context,
        builder: (ctx) {
          final mq = MediaQuery.sizeOf(ctx);
          final w = math.min(480.0, mq.width - 40);
          return AlertDialog(
            title: const Text('Metodni tanlang'),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            content: SizedBox(
              width: w,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: math.min(3, _methodGridCrossAxisCount(mq.width)),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.22,
                ),
                itemCount: methods.length,
                itemBuilder: (context, i) {
                  final m = methods[i];
                  return TeacherMethodGridCard(
                    methodType: m.type,
                    methodName: _methodCardTitle(m),
                    onOpen: () => Navigator.pop(ctx, m),
                    showBoshlash: false,
                  );
                },
              ),
            ),
          );
        },
      );
    }
    if (picked == null || !context.mounted) return;
    context.push(
      AppRoutes.teacherCreateAssignment,
      extra: AssignmentRouteArgs(
        subjectId: widget.subjectId,
        classId: widget.classId,
        topicId: widget.topicId,
        methodId: picked.id,
      ),
    );
  }

  static String _methodTitle(MethodType mt) {
    switch (mt) {
      case MethodType.quiz:
        return 'Test (Quiz)';
      case MethodType.poll:
        return 'So\'rovnoma';
      case MethodType.brainstorm:
        return 'Aqliy hujum';
      case MethodType.caseStudy:
        return 'Muammoli vaziyat';
      case MethodType.groupWork:
        return 'Klaster';
      case MethodType.rolePlay:
        return 'Rolli o\'yin';
      case MethodType.fishbone:
        return 'T-sxema';
    }
  }

  static String _methodTitleFromType(String type) {
    final parsed = methodTypeFromFirestore(type);
    if (parsed == null) return type;
    return _methodTitle(parsed);
  }

  static String _methodDisplayTitle(MethodModel m) {
    final t = m.config?['title'] as String?;
    if (t != null && t.isNotEmpty) return t;
    return _methodTitleFromType(m.type);
  }

  /// Kartochkada faqat metod nomi (configdagi «Klaster: mavzu» kabi uzun sarlavha emas).
  static String _methodCardTitle(MethodModel m) =>
      _methodTitleFromType(m.type);

  String _topicLabelForNav() {
    for (final t
        in CurriculumCatalog.topicsFor(widget.subjectId, widget.classId)) {
      if (t.id == widget.topicId) {
        return t.name;
      }
    }
    return widget.topicId;
  }

  /// Mavzu nomi ba'zan `6-sinf: Sarlavha` — nav qatorida sinf allaqachon boshda beriladi.
  String _topicForNavStripGrade(String gradeLabel, String raw) {
    final g = gradeLabel.trim();
    if (g.isEmpty) return raw.trim();
    var t = raw.trim();
    final prefix = '$g:';
    while (t.startsWith(prefix)) {
      t = t.substring(prefix.length).trimLeft();
    }
    return t.isEmpty ? raw.trim() : t;
  }

  String _navContextLine() {
    final g = CurriculumCatalog.gradeContextLabel(widget.classId);
    final fan =
        CurriculumCatalog.catalogSubjectName(widget.subjectId) ??
        widget.subjectId;
    final topic = _topicForNavStripGrade(g, _topicLabelForNav());
    return '$g · $fan · $topic';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(
        context,
        'Metodlar',
        actions: [
          IconButton(
            tooltip: 'Topshiriq yaratish',
            icon: const Icon(Icons.assignment_add),
            color: cs.onSurface,
            onPressed: () => _createAssignment(context),
          ),
        ],
      ),
      floatingActionButton: MinimalTeacherList.extendedFab(
        context: context,
        onPressed: () => _addMethod(context),
        icon: Icons.add,
        label: 'Metod',
      ),
      body: TabletConstrainedBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Text(
                _navContextLine(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      fontSize: 13,
                    ),
              ),
            ),
            Expanded(
              child: BlocBuilder<MethodBloc, MethodState>(
        builder: (context, state) {
          if (state is MethodLoading || state is MethodInitial) {
            return MinimalTeacherList.progressIndicator(context);
          }
          if (state is MethodFailure) {
            return MinimalTeacherList.errorWithRetry(
              context,
              state.message,
              onRetry: _reload,
            );
          }
          if (state is MethodLoaded) {
            if (state.methods.isEmpty) {
              return MinimalTeacherList.emptyState(
                context,
                'Metodlar topilmadi.\nPastdagi + tugmasi orqali metod qo\'shing.',
              );
            }
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? state.methods
                : state.methods.where((m) {
                    final title = _methodDisplayTitle(m).toLowerCase();
                    return title.contains(q) || m.id.toLowerCase().contains(q);
                  }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherListSearchBar(
                  controller: _search,
                  hint: 'Metod bo\'yicha qidirish',
                  onChanged: (v) => setState(() => _query = v),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: MinimalTeacherList.accent,
                    onRefresh: () async {
                      _reload();
                      await Future<void>.delayed(
                        const Duration(milliseconds: 350),
                      );
                    },
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 48),
                              MinimalTeacherList.emptyState(
                                context,
                                'Qidiruv bo\'yicha hech narsa topilmadi.',
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cross = _methodGridCrossAxisCount(
                                constraints.maxWidth,
                              );
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  96,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.34,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final m = filtered[i];
                                  final preset = CurriculumPresets.isPresetMethodId(
                                    m.id,
                                  );

                                  List<Widget>? actions;
                                  if (preset && m.type == 'group') {
                                    actions = null;
                                  } else if (!preset) {
                                    actions = [
                                      IconButton(
                                        tooltip: 'O\'chirish',
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: cs.error,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _deleteMethod(context, m),
                                      ),
                                      IconButton(
                                        tooltip: 'Topshiriqlar',
                                        icon: Icon(
                                          Icons.list_alt,
                                          color: Colors.grey.shade600,
                                          size: 22,
                                        ),
                                        onPressed: () => context.push(
                                          AppRoutes.teacherMethodAssignmentsList(
                                            widget.classId,
                                            widget.subjectId,
                                            widget.topicId,
                                            m.id,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Tahrirlash',
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.grey.shade600,
                                          size: 22,
                                        ),
                                        onPressed: () =>
                                            _openMethod(context, m),
                                      ),
                                    ];
                                  }

                                  return TeacherMethodGridCard(
                                    methodType: m.type,
                                    methodName: _methodCardTitle(m),
                                    onOpen: () =>
                                        _openFromMethodsList(context, m),
                                    actions: actions,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
