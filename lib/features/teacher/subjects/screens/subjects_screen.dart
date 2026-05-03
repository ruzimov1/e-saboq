import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/services/teacher_last_route_prefs.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../../core/widgets/tablet_constrained_body.dart';
import '../../../../core/widgets/teacher_list_search_bar.dart';
import '../../../../router/app_router.dart';
import '../data/subjects_repository.dart';
import '../cubit/subjects_cubit.dart';
import '../cubit/subjects_state.dart';

/// Tanlangan sinf uchun "Fanlar" ro'yxati.
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key, required this.classId});

  final String classId;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TeacherLastRoutePrefs.save(
        classId: widget.classId,
        subjectId: null,
        topicId: null,
        depth: TeacherLastDepth.subjects,
      );
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _deleteSubject(
    BuildContext context,
    String id,
    String name,
  ) async {
    final ok = await showConfirmDeleteDialog(
      context,
      title: 'Fanni o\'chirish',
      message: '"$name" va uning ostidagi barcha sinflar, mavzular, '
          'metodlar va topshiriqlar butunlay o\'chiriladi.',
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<SubjectsRepository>().deleteSubject(id);
      if (context.mounted) {
        context.read<SubjectsCubit>().load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fan o\'chirildi')),
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
    final classLabel = CurriculumCatalog.gradeContextLabel(widget.classId);
    final subjectsTitle =
        classLabel.isEmpty ? 'Fanlar' : 'Fanlar · $classLabel';
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(
        context,
        subjectsTitle,
        actions: [
          IconButton(
            tooltip: 'Guruhlar',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => context.push(AppRoutes.teacherGroups),
          ),
        ],
      ),
      floatingActionButton: MinimalTeacherList.extendedFab(
        context: context,
        onPressed: () => context.push(AppRoutes.teacherCreateSubject),
        icon: Icons.add,
        label: 'Qo\'shimcha fan',
      ),
      body: TabletConstrainedBody(
        child: BlocBuilder<SubjectsCubit, SubjectsState>(
          builder: (context, state) {
          if (state.status == SubjectsStatus.loading) {
            return MinimalTeacherList.progressIndicator(context);
          }
          if (state.status == SubjectsStatus.error) {
            return MinimalTeacherList.errorWithRetry(
              context,
              state.errorMessage ?? 'Xato',
              onRetry: () => context.read<SubjectsCubit>().load(),
            );
          }
          if (state.subjects.isEmpty) {
            return MinimalTeacherList.emptyState(
              context,
              'Hozircha fanlar yo\'q.\nPastdagi + tugmasi orqali fan qo\'shing.',
            );
          }

          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? state.subjects
              : state.subjects
                  .where((s) => s.name.toLowerCase().contains(q))
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TeacherListSearchBar(
                controller: _search,
                hint: 'Fan bo\'yicha qidirish',
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: MinimalTeacherList.accent,
                  onRefresh: () async {
                    context.read<SubjectsCubit>().load();
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            return MinimalTeacherListCard(
                              title: s.name,
                              onDelete: CurriculumCatalog.isCurriculumSubject(s.id)
                                  ? null
                                  : () => _deleteSubject(context, s.id, s.name),
                              onTap: () => context.push(
                                AppRoutes.teacherClassTopics(
                                  widget.classId,
                                  s.id,
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
