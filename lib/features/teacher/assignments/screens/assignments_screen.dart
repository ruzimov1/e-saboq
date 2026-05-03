import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/assignment_deadline_picker.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';
import '../../../../core/widgets/tablet_constrained_body.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../data/assignment_repository.dart';
import '../data/teacher_assignment_item.dart';

enum _AssignmentFilter { all, active, closed }

/// O'qituvchining barcha topshiriqlari (`teacherId` bilan saqlanganlar).
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  _AssignmentFilter _filter = _AssignmentFilter.all;

  String _deletingKey = '';
  bool _selectionMode = false;
  final Set<String> _selectedKeys = <String>{};
  bool _bulkBusy = false;

  String _keyOf(TeacherAssignmentItem e) =>
      '${e.subjectId}/${e.classId}/${e.topicId}/${e.methodId}/${e.assignmentId}';

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedKeys.clear();
    });
  }

  List<TeacherAssignmentItem> _applyFilter(List<TeacherAssignmentItem> list) {
    switch (_filter) {
      case _AssignmentFilter.all:
        return list;
      case _AssignmentFilter.active:
        return list.where((e) => e.isActive).toList();
      case _AssignmentFilter.closed:
        return list.where((e) => !e.isActive).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: MinimalTeacherList.bgOf(context),
        appBar: MinimalTeacherList.appBar(context, 'Topshiriqlar'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Ro\'yxat uchun tizimga kiring.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    if (auth.user.role != 'teacher') {
      return Scaffold(
        backgroundColor: MinimalTeacherList.bgOf(context),
        appBar: MinimalTeacherList.appBar(context, 'Topshiriqlar'),
        body: Center(
          child: Text(
            'Bu sahifa faqat o\'qituvchilar uchun.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final repo = context.read<AssignmentRepository>();
    return Scaffold(
      backgroundColor: MinimalTeacherList.bgOf(context),
      appBar: MinimalTeacherList.appBar(
        context,
        'Topshiriqlar',
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: _exitSelection,
                  child: const Text('Bekor qilish'),
                ),
              ]
            : null,
      ),
      body: StreamBuilder<List<TeacherAssignmentItem>>(
        stream: repo.watchAssignmentsForTeacher(auth.user.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return MinimalTeacherList.errorText(
              context,
              snap.error.toString(),
            );
          }
          if (!snap.hasData) {
            return MinimalTeacherList.progressIndicator(context);
          }
          final all = snap.data!;
          if (all.isEmpty) {
            return MinimalTeacherList.emptyState(
              context,
              'Hozircha topshiriqlar yo\'q.\n'
              'Metod sahifasidan topshiriq yarating — u global ro\'yxatga '
              '(`teacherId` bilan) qo\'shiladi.',
            );
          }
          final filtered = _applyFilter(all);
          final l10n = AppLocalizations.of(context)!;
          final activeN = all.where((e) => e.isActive).length;
          return TabletConstrainedBody(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_bulkBusy)
                const LinearProgressIndicator(minHeight: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  l10n.statsAssignments(all.length, activeN, all.length - activeN),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Barchasi'),
                      selected: _filter == _AssignmentFilter.all,
                      onSelected: (_) {
                        setState(() {
                          _filter = _AssignmentFilter.all;
                          if (_selectionMode) {
                            final vis = _applyFilter(all);
                            final allow = vis.map(_keyOf).toSet();
                            _selectedKeys.removeWhere(
                              (k) => !allow.contains(k),
                            );
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Faol'),
                      selected: _filter == _AssignmentFilter.active,
                      onSelected: (_) {
                        setState(() {
                          _filter = _AssignmentFilter.active;
                          if (_selectionMode) {
                            final vis = _applyFilter(all);
                            final allow = vis.map(_keyOf).toSet();
                            _selectedKeys.removeWhere(
                              (k) => !allow.contains(k),
                            );
                          }
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Yakunlangan'),
                      selected: _filter == _AssignmentFilter.closed,
                      onSelected: (_) {
                        setState(() {
                          _filter = _AssignmentFilter.closed;
                          if (_selectionMode) {
                            final vis = _applyFilter(all);
                            final allow = vis.map(_keyOf).toSet();
                            _selectedKeys.removeWhere(
                              (k) => !allow.contains(k),
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                              '${_selectedKeys.length} ta tanlangan',
                              style: TextStyle(
                                fontSize: 13,
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
                                        for (final e in filtered) {
                                          _selectedKeys.add(_keyOf(e));
                                        }
                                      });
                                    },
                              child: const Text('Hammasini belgilash'),
                            ),
                            TextButton(
                              onPressed: _bulkBusy
                                  ? null
                                  : () => setState(
                                        _selectedKeys.clear,
                                      ),
                              child: const Text('Belgilashni tozalash'),
                            ),
                            FilledButton.tonal(
                              onPressed: _bulkBusy || _selectedKeys.isEmpty
                                  ? null
                                  : () {
                                      _confirmDeleteMany(
                                        context,
                                        filtered
                                            .where(
                                              (e) => _selectedKeys
                                                  .contains(_keyOf(e)),
                                            )
                                            .toList(),
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
                                        _selectedKeys.clear();
                                      });
                                    },
                              icon: const Icon(Icons.checklist_outlined, size: 20),
                              label: const Text('Tanlab o\'chirish'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _bulkBusy
                                  ? null
                                  : () => _confirmDeleteMany(
                                        context,
                                        List<TeacherAssignmentItem>.from(
                                          filtered,
                                        ),
                                        intro:
                                            'Filtr bo\'yicha hozir ko\'rinayotgan '
                                            'barcha topshiriqlar o\'chiriladi '
                                            '(${filtered.length} ta).',
                                      ),
                              icon: const Icon(
                                Icons.delete_sweep_outlined,
                                size: 20,
                              ),
                              label: const Text('Filtrdagi barchasini o\'chirish'),
                            ),
                          ],
                        ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? MinimalTeacherList.emptyState(
                        context,
                        'Bu filtr bo\'yicha topshiriq yo\'q.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final e = filtered[i];
                          final k = _keyOf(e);
                          final delBusy = _deletingKey == k;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(
                                MinimalTeacherList.cardRadius,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  MinimalTeacherList.cardRadius,
                                ),
                                onTap: _selectionMode
                                    ? () {
                                        setState(() {
                                          if (_selectedKeys.contains(k)) {
                                            _selectedKeys.remove(k);
                                          } else {
                                            _selectedKeys.add(k);
                                          }
                                        });
                                      }
                                    : () => context.push(
                                          AppRoutes.teacherMethodAssignmentsList(
                                            e.classId,
                                            e.subjectId,
                                            e.topicId,
                                            e.methodId,
                                          ),
                                        ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (_selectionMode) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Checkbox(
                                                  value: _selectedKeys
                                                      .contains(k),
                                                  onChanged: _bulkBusy
                                                      ? null
                                                      : (v) {
                                                          setState(() {
                                                            if (v == true) {
                                                              _selectedKeys
                                                                  .add(k);
                                                            } else {
                                                              _selectedKeys
                                                                  .remove(k);
                                                            }
                                                          });
                                                        },
                                                ),
                                              ),
                                            ),
                                          ],
                                          Expanded(
                                            child: Text(
                                              e.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (delBusy)
                                            const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            )
                                          else if (!_selectionMode) ...[
                                            IconButton(
                                              tooltip: 'O\'chirish',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              onPressed: () =>
                                                  _confirmDelete(context, e),
                                            ),
                                            IconButton(
                                              tooltip: 'Kodni nusxalash',
                                              icon: const Icon(
                                                Icons.copy_outlined,
                                              ),
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                  ClipboardData(text: e.code),
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
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Kod: ${e.code}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      if (e.deadline != null)
                                        Text(
                                          'Muddat: ${_formatDate(e.deadline!)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        e.isActive
                                            ? 'Holat: faol'
                                            : 'Holat: yakunlangan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: e.isActive
                                              ? Colors.green.shade700
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .outline,
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
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return formatAssignmentDeadlineDateTime(d);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TeacherAssignmentItem e,
  ) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Topshiriqni o\'chirish'),
          content: Text(
            '"${e.title}" ni o\'chirmoqchimisiz? Barcha o\'quvchi javoblari ham '
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
    if (go != true || !context.mounted) return;
    setState(() => _deletingKey = _keyOf(e));
    try {
      await context.read<AssignmentRepository>().deleteAssignment(
            subjectId: e.subjectId,
            classId: e.classId,
            topicId: e.topicId,
            methodId: e.methodId,
            assignmentId: e.assignmentId,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topshiriq o\'chirildi')),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _deletingKey = '');
      }
    }
  }

  Future<void> _confirmDeleteMany(
    BuildContext context,
    List<TeacherAssignmentItem> items, {
    required String intro,
  }) async {
    if (items.isEmpty) return;
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
    if (go != true || !context.mounted) return;
    setState(() => _bulkBusy = true);
    final repo = context.read<AssignmentRepository>();
    try {
      for (final e in items) {
        await repo.deleteAssignment(
          subjectId: e.subjectId,
          classId: e.classId,
          topicId: e.topicId,
          methodId: e.methodId,
          assignmentId: e.assignmentId,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${items.length} ta topshiriq o\'chirildi',
            ),
          ),
        );
      }
      if (mounted) {
        _exitSelection();
      }
    } catch (e) {
      if (context.mounted) {
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
}
