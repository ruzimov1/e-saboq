import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/localized_review_status.dart';
import '../../../../core/services/assignment_draft_store.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../teacher/assignments/data/assignment_lookup.dart';
import '../../../teacher/groups/data/groups_repository.dart';
import '../data/submission_repository.dart';

/// Guruh inbox + yuborilgan topshiriqlar.
class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedPaths = <String>{};
  bool _bulkBusy = false;

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedPaths.clear();
    });
  }

  void _startSelection() {
    setState(() {
      _selectionMode = true;
      _selectedPaths.clear();
    });
  }

  void _togglePath(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _scaffoldSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteSelected(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingInbox,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> subDocs,
    String studentId,
    GroupsRepository groupsRepo,
    SubmissionRepository subRepo,
  ) async {
    if (_selectedPaths.isEmpty) return;
    final n = _selectedPaths.length;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDeleteDialog(
      context,
      title: l10n.studentBulkDeleteSelectedTitle,
      message: l10n.studentBulkDeleteSelectedMessage(n),
    );
    if (!ok || !mounted) return;
    setState(() => _bulkBusy = true);
    var failed = 0;
    try {
      for (final path in _selectedPaths.toList()) {
        if (!mounted) return;
        final inboxMatch = pendingInbox.where((d) => d.reference.path == path);
        if (inboxMatch.isNotEmpty) {
          try {
            await groupsRepo.deleteStudentInboxItem(inboxMatch.first.reference);
          } catch (_) {
            failed++;
          }
          continue;
        }
        final subMatch = subDocs.where((d) => d.reference.path == path);
        if (subMatch.isNotEmpty) {
          try {
            final doc = subMatch.first;
            final lookup = AssignmentLookup.fromSubmissionDocument(doc);
            await subRepo.deleteMySubmission(
              ref: doc.reference,
              studentId: studentId,
            );
            if (lookup != null) {
              await AssignmentDraftStore.clear(lookup, studentId);
            }
          } catch (_) {
            failed++;
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _bulkBusy = false);
      }
    }
    if (mounted) {
      setState(() {
        _selectedPaths.clear();
        _selectionMode = false;
      });
      if (failed > 0) {
        _scaffoldSuccess(l10n.studentBulkDeletedPartial(failed));
      } else {
        _scaffoldSuccess(l10n.studentBulkDeletedOk);
      }
    }
  }

  Future<void> _deleteAll(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingInbox,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> subDocs,
    String studentId,
    GroupsRepository groupsRepo,
    SubmissionRepository subRepo,
  ) async {
    final total = pendingInbox.length + subDocs.length;
    final l10n = AppLocalizations.of(context)!;
    if (total == 0) {
      _scaffoldSuccess(l10n.studentBulkDeleteNothingToRemove);
      return;
    }
    final ok = await showConfirmDeleteDialog(
      context,
      title: l10n.studentBulkDeleteAllTitle,
      message: l10n.studentBulkDeleteAllMessage(total),
    );
    if (!ok || !mounted) return;
    setState(() => _bulkBusy = true);
    var failed = 0;
    try {
      for (final doc in pendingInbox) {
        if (!mounted) return;
        try {
          await groupsRepo.deleteStudentInboxItem(doc.reference);
        } catch (_) {
          failed++;
        }
      }
      for (final doc in subDocs) {
        if (!mounted) return;
        try {
          final lookup = AssignmentLookup.fromSubmissionDocument(doc);
          await subRepo.deleteMySubmission(
            ref: doc.reference,
            studentId: studentId,
          );
          if (lookup != null) {
            await AssignmentDraftStore.clear(lookup, studentId);
          }
        } catch (_) {
          failed++;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _bulkBusy = false);
      }
    }
    if (mounted) {
      if (failed > 0) {
        _scaffoldSuccess(l10n.studentBulkDeleteAllError(failed));
      } else {
        _scaffoldSuccess(l10n.studentBulkDeletedAllOk);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(l10n.myAssignments),
          actions: const [AppProfileIcon()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.studentListLoginPrompt),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(l10n.loginTitle),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final uid = auth.user.id;
    final subRepo = context.read<SubmissionRepository>();
    final groupsRepo = context.read<GroupsRepository>();

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _selectionMode) {
          _clearSelection();
        }
      },
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: groupsRepo.watchStudentGroupInbox(uid),
        builder: (context, inboxSnap) {
          if (inboxSnap.hasError) {
            return Scaffold(
              appBar: _bar(
                context,
                l10n,
                uid: uid,
                subRepo: subRepo,
                groupsRepo: groupsRepo,
                pendingInbox: const [],
                subDocs: const [],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${inboxSnap.error}', textAlign: TextAlign.center),
                ),
              ),
            );
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: subRepo.watchMySubmissions(uid),
            builder: (context, subSnap) {
              if (subSnap.hasError) {
                return Scaffold(
                  appBar: _bar(
                    context,
                    l10n,
                    uid: uid,
                    subRepo: subRepo,
                    groupsRepo: groupsRepo,
                    pendingInbox: const [],
                    subDocs: const [],
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child:
                          Text('${subSnap.error}', textAlign: TextAlign.center),
                    ),
                  ),
                );
              }
              if (!inboxSnap.hasData || !subSnap.hasData) {
                return Scaffold(
                  appBar: _bar(
                    context,
                    l10n,
                    uid: uid,
                    subRepo: subRepo,
                    groupsRepo: groupsRepo,
                    pendingInbox: const [],
                    subDocs: const [],
                  ),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }

              final subDocs = subSnap.data!.docs.toList();
              subDocs.sort((a, b) {
                final ta = a.data()['submittedAt'];
                final tb = b.data()['submittedAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });

              final submittedKeys = <String>{};
              for (final doc in subDocs) {
                final k =
                    AssignmentLookup.assignmentPathKeyFromSubmissionDoc(doc);
                if (k != null) submittedKeys.add(k);
              }

              final inboxDocs = inboxSnap.data!.docs.toList();
              inboxDocs.sort((a, b) {
                final ta = a.data()['assignedAt'];
                final tb = b.data()['assignedAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });

              final pendingInbox = inboxDocs.where((doc) {
                final k = AssignmentLookup.assignmentPathKeyFromGroupTaskData(
                  doc.data(),
                );
                return !submittedKeys.contains(k);
              }).toList();

              return Scaffold(
                appBar: _bar(
                  context,
                  l10n,
                  uid: uid,
                  subRepo: subRepo,
                  groupsRepo: groupsRepo,
                  pendingInbox: pendingInbox,
                  subDocs: subDocs,
                ),
                body: _bulkBusy
                    ? const Center(child: CircularProgressIndicator())
                    : (pendingInbox.isEmpty && subDocs.isEmpty)
                        ? _emptyState(context, l10n)
                        : _listBody(
                            context,
                            l10n,
                            uid,
                            subRepo,
                            groupsRepo,
                            pendingInbox,
                            subDocs,
                          ),
              );
            },
          );
        },
      ),
    );
  }

  AppBar _bar(
    BuildContext context,
    AppLocalizations l10n, {
    required String uid,
    required SubmissionRepository subRepo,
    required GroupsRepository groupsRepo,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingInbox,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> subDocs,
  }) {
    return AppBar(
      leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
      leading: _selectionMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _clearSelection,
            )
          : const AppBarBackOrHomeLeading(),
      title: Text(
        _selectionMode
            ? (_selectedPaths.isEmpty
                ? l10n.studentSelectItems
                : l10n.studentSelectedCount(_selectedPaths.length))
            : l10n.myAssignments,
      ),
      actions: [
        if (_selectionMode) ...[
          if (_selectedPaths.isNotEmpty)
            TextButton(
              onPressed: _bulkBusy
                  ? null
                  : () => _deleteSelected(
                        pendingInbox,
                        subDocs,
                        uid,
                        groupsRepo,
                        subRepo,
                      ),
              child: Text(l10n.delete),
            ),
        ] else
          IconButton(
            tooltip: l10n.delete,
            onPressed: _bulkBusy
                ? null
                : () async {
                    final choice = await showDialog<String>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: Text(l10n.studentDeleteDialogTitle),
                        children: [
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, 'select'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(l10n.studentDeleteViaSelection),
                            ),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(ctx, 'all'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(l10n.studentDeleteEverything),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (choice == 'select') {
                      _startSelection();
                    } else if (choice == 'all') {
                      await _deleteAll(
                        pendingInbox,
                        subDocs,
                        uid,
                        groupsRepo,
                        subRepo,
                      );
                    }
                  },
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        const AppProfileIcon(),
      ],
    );
  }

  Widget _emptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.studentAssignmentsEmptyHint,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go(AppRoutes.studentJoin),
              child: Text(l10n.joinByCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listBody(
    BuildContext context,
    AppLocalizations l10n,
    String uid,
    SubmissionRepository subRepo,
    GroupsRepository groupsRepo,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingInbox,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> subDocs,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingInbox.isNotEmpty) ...[
          Text(
            l10n.studentGroupInboxSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...pendingInbox.map((doc) {
            final d = doc.data();
            final title = '${d['title'] ?? l10n.assignmentUntitled}';
            final code = '${d['code'] ?? '—'}';
            final gn = '${d['groupName'] ?? ''}';
            final lookup = AssignmentLookup.fromStudentGroupTask(doc);
            final path = doc.reference.path;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _selectionMode
                    ? Checkbox(
                        value: _selectedPaths.contains(path),
                        onChanged: _bulkBusy
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedPaths.add(path);
                                  } else {
                                    _selectedPaths.remove(path);
                                  }
                                });
                              },
                      )
                    : null,
                title: Text(title),
                subtitle: Text(
                  '${l10n.studentCodeLine(code)}${gn.isNotEmpty ? ' · $gn' : ''}',
                ),
                onTap: _bulkBusy
                    ? null
                    : _selectionMode
                        ? () => _togglePath(path)
                        : (lookup == null
                            ? null
                            : () => context.push(
                                  AppRoutes.studentSolve,
                                  extra: lookup,
                                )),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
        if (subDocs.isNotEmpty) ...[
          Text(
            l10n.studentSubmittedSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...subDocs.map((doc) {
            final d = doc.data();
            final lookup = AssignmentLookup.fromSubmissionDocument(doc);
            final title = d['assignmentTitle'] as String? ??
                d['title'] as String? ??
                l10n.assignmentUntitled;
            final code = d['assignmentCode'] ?? d['code'];
            final score = d['score'];
            final at = d['submittedAt'];
            final st = d['reviewStatus'] as String? ?? 'submitted';
            final tc = d['teacherComment'] as String?;
            final g10 = d['grade10'];
            String time = '—';
            if (at is Timestamp) {
              time = DateFormat.yMMMd().add_Hm().format(at.toDate());
            }
            final stLabel = localizedReviewStatus(l10n, st);
            final hasFeedback = (tc != null && tc.isNotEmpty) ||
                (g10 is num) ||
                ((d['aiFeedback'] as String?)?.trim().isNotEmpty ?? false);
            final path = doc.reference.path;
            var subLines = '${l10n.studentCodeLine('${code ?? '—'}')} · ${l10n.studentMetaScore}: ${score ?? '—'}';
            if (g10 is num) {
              subLines += ' · ${l10n.studentMetaTeacherGrade10(g10.round())}';
            }
            subLines += ' · $stLabel\n$time';
            if (hasFeedback) {
              subLines += '\n${l10n.studentSubmissionHasFeedbackNote}';
            }
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _selectionMode
                    ? Checkbox(
                        value: _selectedPaths.contains(path),
                        onChanged: _bulkBusy
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedPaths.add(path);
                                  } else {
                                    _selectedPaths.remove(path);
                                  }
                                });
                              },
                      )
                    : null,
                title: Text(title),
                subtitle: Text(subLines),
                isThreeLine: true,
                onTap: _bulkBusy
                    ? null
                    : _selectionMode
                        ? () => _togglePath(path)
                        : (lookup == null
                            ? null
                            : () => context.push(
                                  AppRoutes.studentSubmission,
                                  extra: lookup,
                                )),
              ),
            );
          }),
        ],
      ],
    );
  }
}
