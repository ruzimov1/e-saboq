import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/curriculum/curriculum_catalog.dart';
import '../../../../core/services/teacher_last_route_prefs.dart';
import '../data/class_model.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../../core/widgets/tablet_constrained_body.dart';
import '../../../../core/widgets/teacher_list_search_bar.dart';
import '../../../../core/widgets/teacher_resume_banner.dart';
import '../../../../router/app_router.dart';

/// O'qituvchi bosh sahifasi: barcha sinflar (5–11), keyin fanlar oqimi.
class TeacherClassesRootScreen extends StatefulWidget {
  const TeacherClassesRootScreen({super.key});

  @override
  State<TeacherClassesRootScreen> createState() =>
      _TeacherClassesRootScreenState();
}

class _TeacherClassesRootScreenState extends State<TeacherClassesRootScreen> {
  final _search = TextEditingController();
  String _query = '';
  late Future<TeacherLastRoute?> _resumeFuture;

  @override
  void initState() {
    super.initState();
    _resumeFuture = TeacherLastRoutePrefs.read();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openResume(TeacherLastRoute r) {
    switch (r.depth) {
      case TeacherLastDepth.subjects:
        if (r.classId != null) {
          context.push(AppRoutes.teacherClassSubjects(r.classId!));
        }
        return;
      case TeacherLastDepth.topics:
        if (r.classId != null && (r.subjectId != null)) {
          context.push(
            AppRoutes.teacherClassTopics(
              r.classId!,
              r.subjectId!,
            ),
          );
        }
        return;
      case TeacherLastDepth.methods:
        if (r.classId != null &&
            (r.subjectId != null) &&
            (r.topicId != null)) {
          context.push(
            AppRoutes.teacherTopicMethods(
              r.classId!,
              r.subjectId!,
              r.topicId!,
            ),
          );
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = CurriculumCatalog.defaultGrades;
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(
        context,
        'Sinflar',
      ),
      body: TabletConstrainedBody(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<TeacherLastRoute?>(
            future: _resumeFuture,
            builder: (context, snap) {
              final r = snap.data;
              if (r == null) return const SizedBox.shrink();
              return TeacherResumeBanner(
                route: r,
                onOpen: () => _openResume(r),
              );
            },
          ),
          TeacherListSearchBar(
            controller: _search,
            hint: 'Sinf bo\'yicha qidirish',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: RefreshIndicator(
              color: MinimalTeacherList.accent,
              onRefresh: () async {
                if (mounted) {
                  setState(() {
                    _resumeFuture = TeacherLastRoutePrefs.read();
                  });
                }
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: _buildList(context, grades),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ClassModel> grades) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? grades
        : grades
            .where((c) => c.name.toLowerCase().contains(q))
            .toList();
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          MinimalTeacherList.emptyState(
            context,
            'Qidiruv bo\'yicha hech narsa topilmadi.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final c = filtered[i];
        return MinimalTeacherListCard(
          title: c.name,
          onTap: () => context.push(
            AppRoutes.teacherClassSubjects(c.id),
          ),
        );
      },
    );
  }
}
