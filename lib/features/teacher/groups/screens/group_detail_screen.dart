import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../assignments/data/assignment_repository.dart';
import '../../assignments/data/teacher_assignment_item.dart';
import '../data/groups_repository.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _username = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _copyCode(String? code) async {
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod buferga nusxalandi')),
      );
    }
  }

  Future<void> _addMember(String teacherId) async {
    final u = _username.text.trim();
    final err = validateUsername(u);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _adding = true);
    try {
      final repo = context.read<GroupsRepository>();
      final uid = await repo.resolveUsernameToUid(u);
      if (!mounted) return;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bunday login topilmadi')),
        );
        return;
      }
      await repo.addMemberByUid(
        teacherId: teacherId,
        groupId: widget.groupId,
        studentUid: uid,
      );
      if (mounted) {
        _username.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O\'quvchi qo\'shildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeMember(String teacherId, String studentUid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('A\'zoni chiqarish'),
        content: const Text(
          'Bu o\'quvchini guruhdan olib tashlaysizmi? Inbox dagi '
          'biriktirilgan topshiriqlar qolishi mumkin.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Yo\'q')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ha')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<GroupsRepository>().removeMember(
            teacherId: teacherId,
            groupId: widget.groupId,
            studentUid: studentUid,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chiqarildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _pickAssignment(
    BuildContext context,
    String teacherId,
    List<TeacherAssignmentItem> items,
  ) async {
    final chosen = await showModalBottomSheet<TeacherAssignmentItem>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Guruhga ulash',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: items.length,
                itemBuilder: (c, i) {
                  final e = items[i];
                  return ListTile(
                    title: Text(e.title),
                    subtitle: Text('Kod: ${e.code}'),
                    onTap: () => Navigator.pop(ctx, e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    try {
      await context.read<GroupsRepository>().assignTeacherItemToGroup(
            teacherId: teacherId,
            groupId: widget.groupId,
            item: chosen,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '«${chosen.title}» barcha a\'zolarga yuborildi (inbox).',
            ),
          ),
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
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated || auth.user.role != 'teacher') {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: const Text('Guruh'),
        ),
        body: const Center(child: Text('Ruxsat yo\'q')),
      );
    }
    final tid = auth.user.id;
    final repo = context.read<GroupsRepository>();

    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('Guruh'),
        actions: const [AppProfileIcon()],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: repo.watchGroup(widget.groupId),
        builder: (context, snap) {
          if (snap.hasError) {
            return MinimalTeacherList.errorText(context, '${snap.error}');
          }
          if (!snap.hasData || !snap.data!.exists) {
            return MinimalTeacherList.progressIndicator(context);
          }
          final d = snap.data!.data() ?? {};
          if (d['teacherId'] != tid) {
            return const Center(child: Text('Bu sizning guruhingiz emas.'));
          }
          final name = '${d['name'] ?? 'Guruh'}';
          final code = d['joinCode'] as String?;
          final members = List<String>.from(d['memberIds'] ?? const []);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Guruhga kirish kodi'),
                  subtitle: Text(code ?? '—'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () => _copyCode(code),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _pickAssignmentFromTeacher(
                  context,
                  tid,
                ),
                icon: const Icon(Icons.link_outlined),
                label: const Text('Topshiriqni guruhga ulash'),
              ),
              const SizedBox(height: 24),
              Text(
                'O\'quvchi qo\'shish (login)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _username,
                      label: 'O\'quvchi logini',
                      hint: 'masalan: ali2025',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton(
                      onPressed: _adding ? null : () => _addMember(tid),
                      child: _adding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Qo\'shish'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'A\'zolar (${members.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              if (members.isEmpty)
                Text(
                  'Hozircha hech kim yo\'q. Login yoki o\'quvchi «Kod bilan kirish» '
                  '→ Guruh kodi orqali qo\'shiladi.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...members.map(
                  (uid) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      uid,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _removeMember(tid, uid),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAssignmentFromTeacher(
    BuildContext context,
    String teacherId,
  ) async {
    final assignRepo = context.read<AssignmentRepository>();
    final snap = await assignRepo.watchAssignmentsForTeacher(teacherId).first;
    if (!context.mounted) return;
    if (snap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avval topshiriq yarating (fan → metod → topshiriq).'),
        ),
      );
      return;
    }
    await _pickAssignment(context, teacherId, snap);
  }
}
