import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../../core/widgets/tablet_constrained_body.dart';
import '../../../../core/widgets/teacher_list_search_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../subjects/data/subjects_repository.dart';
import '../data/classes_repository.dart';
import '../cubit/classes_cubit.dart';
import '../cubit/classes_state.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _subjectDisplayName;

  @override
  void initState() {
    super.initState();
    _subjectDisplayName =
        CurriculumCatalog.catalogSubjectName(widget.subjectId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_subjectDisplayName == null) {
        _loadCustomSubjectName();
      }
    });
  }

  Future<void> _loadCustomSubjectName() async {
    try {
      final name = await context
          .read<SubjectsRepository>()
          .displayNameForSubject(widget.subjectId);
      if (mounted) setState(() => _subjectDisplayName = name);
    } catch (_) {
      if (mounted) setState(() => _subjectDisplayName = widget.subjectId);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _deleteClass(
    BuildContext context,
    String classId,
    String className,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDeleteDialog(
      context,
      title: l10n.teacherClassDeleteTitle,
      message: l10n.teacherClassDeleteMessage(className),
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<ClassesRepository>().deleteClass(
            subjectId: widget.subjectId,
            classId: classId,
          );
      if (context.mounted) {
        context.read<ClassesCubit>().load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.teacherClassDeleted)),
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

  @override
  Widget build(BuildContext context) {
    final fan = _subjectDisplayName;
    final sinflarTitle =
        (fan == null || fan.isEmpty) ? 'Sinflar' : 'Sinflar · $fan';
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(
        context,
        sinflarTitle,
      ),
      body: TabletConstrainedBody(
        child: BlocBuilder<ClassesCubit, ClassesState>(
          builder: (context, state) {
          if (state.status == ClassesStatus.loading) {
            return MinimalTeacherList.progressIndicator(context);
          }
          if (state.status == ClassesStatus.error) {
            return MinimalTeacherList.errorWithRetry(
              context,
              state.errorMessage ?? 'Xato',
              onRetry: () => context.read<ClassesCubit>().load(),
            );
          }
          if (state.classes.isEmpty) {
            return MinimalTeacherList.emptyState(
              context,
              'Sinf topilmadi.\nYuqoridagi menyudan sinf qo\'shish yo\'lini tanlang.',
            );
          }

          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? state.classes
              : state.classes
                  .where((c) => c.name.toLowerCase().contains(q))
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TeacherListSearchBar(
                controller: _search,
                hint: 'Sinf bo\'yicha qidirish',
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: MinimalTeacherList.accent,
                  onRefresh: () async {
                    context.read<ClassesCubit>().load();
                    await Future<void>.delayed(const Duration(milliseconds: 400));
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
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final c = filtered[i];
                            return MinimalTeacherListCard(
                              title: c.name,
                              onDelete: CurriculumCatalog.isCurriculumSubject(
                                    widget.subjectId,
                                  )
                                  ? null
                                  : () => _deleteClass(context, c.id, c.name),
                              onTap: () => context.push(
                                AppRoutes.teacherClassTopics(
                                  c.id,
                                  widget.subjectId,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}
