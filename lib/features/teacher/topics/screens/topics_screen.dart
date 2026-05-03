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
import '../../subjects/data/subjects_repository.dart';
import '../data/topics_repository.dart';
import '../cubit/topics_cubit.dart';
import '../cubit/topics_state.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({
    super.key,
    required this.subjectId,
    required this.classId,
  });

  final String subjectId;
  final String classId;

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _subjectDisplayName;

  @override
  void initState() {
    super.initState();
    _subjectDisplayName =
        CurriculumCatalog.catalogSubjectName(widget.subjectId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TeacherLastRoutePrefs.save(
        classId: widget.classId,
        subjectId: widget.subjectId,
        topicId: null,
        depth: TeacherLastDepth.topics,
      );
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
      if (mounted) {
        setState(() => _subjectDisplayName = name);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _subjectDisplayName = widget.subjectId);
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _isBuiltinTopic(String topicId) => topicId.startsWith('cur_');

  Future<void> _deleteTopic(
    BuildContext context,
    String topicId,
    String topicName,
  ) async {
    final ok = await showConfirmDeleteDialog(
      context,
      title: 'Mavzuni o\'chirish',
      message: '"$topicName" va uning ostidagi metodlar va topshiriqlar '
          'butunlay o\'chiriladi.',
    );
    if (!ok || !context.mounted) return;
    try {
      await context.read<TopicsRepository>().deleteTopic(
            subjectId: widget.subjectId,
            classId: widget.classId,
            topicId: topicId,
          );
      if (context.mounted) {
        context.read<TopicsCubit>().load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mavzu o\'chirildi')),
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
    final topicsTitle =
        (fan == null || fan.isEmpty) ? 'Mavzular' : 'Mavzular · $fan';
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(
        context,
        topicsTitle,
      ),
      floatingActionButton: MinimalTeacherList.extendedFab(
        context: context,
        onPressed: () => context.push(
          AppRoutes.teacherCreateTopic(widget.classId, widget.subjectId),
        ),
        icon: Icons.add,
        label: 'Qo\'shimcha mavzu',
      ),
      body: TabletConstrainedBody(
        child: BlocBuilder<TopicsCubit, TopicsState>(
          builder: (context, state) {
          if (state.status == TopicsStatus.loading) {
            return MinimalTeacherList.progressIndicator(context);
          }
          if (state.status == TopicsStatus.error) {
            return MinimalTeacherList.errorWithRetry(
              context,
              state.errorMessage ?? 'Xato',
              onRetry: () => context.read<TopicsCubit>().load(),
            );
          }
          if (state.topics.isEmpty) {
            return MinimalTeacherList.emptyState(
              context,
              'Mavzular topilmadi.\nPastdagi + tugmasi orqali mavzu yarating.',
            );
          }

          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? state.topics
              : state.topics
                  .where((t) => t.name.toLowerCase().contains(q))
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TeacherListSearchBar(
                controller: _search,
                hint: 'Mavzu bo\'yicha qidirish',
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: MinimalTeacherList.accent,
                  onRefresh: () async {
                    context.read<TopicsCubit>().load();
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
                            final t = filtered[i];
                            return MinimalTeacherListCard(
                              title: t.name,
                              onDelete: _isBuiltinTopic(t.id)
                                  ? null
                                  : () => _deleteTopic(context, t.id, t.name),
                              onTap: () => context.push(
                                AppRoutes.teacherTopicMethods(
                                  widget.classId,
                                  widget.subjectId,
                                  t.id,
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
