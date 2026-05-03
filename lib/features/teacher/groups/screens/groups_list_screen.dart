import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../../router/app_router.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../data/groups_repository.dart';

/// O'qituvchining guruhlari.
class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated || auth.user.role != 'teacher') {
      return Scaffold(
        backgroundColor: MinimalTeacherList.bgOf(context),
        appBar: MinimalTeacherList.appBar(context, 'Guruhlar'),
        body: const Center(child: Text('Faqat o\'qituvchilar uchun.')),
      );
    }
    final tid = auth.user.id;
    final repo = context.read<GroupsRepository>();
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(context, 'Guruhlar'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.teacherCreateGroup),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Yangi guruh'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.watchTeacherGroups(tid),
        builder: (context, snap) {
          if (snap.hasError) {
            return MinimalTeacherList.errorText(context, '${snap.error}');
          }
          if (!snap.hasData) {
            return MinimalTeacherList.progressIndicator(context);
          }
          final docs = snap.data!.docs.toList();
          if (docs.isEmpty) {
            return MinimalTeacherList.emptyState(
              context,
              'Hozircha guruh yo\'q.\n+ tugmasi bilan yarating — keyin '
              'o\'quvchilarni login yoki guruh kodi bilan qo\'shing.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data();
              final name = '${d['name'] ?? 'Guruh'}';
              final code = '${d['joinCode'] ?? '—'}';
              final n =
                  (d['memberIds'] is List) ? (d['memberIds'] as List).length : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(MinimalTeacherList.cardRadius),
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Kod: $code · A\'zolar: $n'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      AppRoutes.teacherGroupDetail(doc.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
