// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/case_study/case_study_dashboard_analytics.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/utils/student_display_name.dart';
import '../../../../core/utils/submission_answer_format.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/assignment_route_args.dart';
import '../../../../router/method_route_args.dart';
import '../../../student/assignments/data/submission_repository.dart';
import '../../assignments/data/assignment_repository.dart';
import '../data/method_repository.dart';

/// Muammoli vaziyat: jonli monitoring, ssenariy konstruktori, sinf tahlili.
class CaseStudyTeacherDashboardScreen extends StatefulWidget {
  const CaseStudyTeacherDashboardScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<CaseStudyTeacherDashboardScreen> createState() =>
      _CaseStudyTeacherDashboardScreenState();
}

class _CaseStudyTeacherDashboardScreenState extends State<CaseStudyTeacherDashboardScreen> {
  int _section = 0;
  String? _selectedAssignmentId;
  String _catalogQuery = '';
  final _searchCtrl = TextEditingController();
  List<String> _builderLines = [];
  CaseStudyCatalogRow? _selectedCatalogRow;
  String? _refSolution;
  final Map<String, Future<Map<String, String>>> _nameBatchCache = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!InformatikaJsonPresets.isReady) {
      await InformatikaJsonPresets.loadFromAssets();
      if (mounted) setState(() {});
    }
    await _loadMethodReference();
  }

  Future<void> _loadMethodReference() async {
    final a = widget.args;
    if (a?.methodId == null || a!.methodId!.isEmpty) return;
    final m = await context.read<MethodRepository>().fetchMethod(
          subjectId: a.subjectId,
          classId: a.classId,
          topicId: a.topicId,
          methodId: a.methodId!,
        );
    if (!mounted) return;
    final path = m?.config?['caseSolutionPath'] as String? ?? '';
    setState(() {
      _refSolution = path.trim().isEmpty ? null : path.trim();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  MethodRouteArgs? get _a => widget.args;

  AssignmentRouteArgs? _assignmentArgs() {
    final a = _a;
    if (a?.methodId == null || a!.methodId!.isEmpty) return null;
    if (_selectedAssignmentId == null || _selectedAssignmentId!.isEmpty) return null;
    return AssignmentRouteArgs(
      subjectId: a.subjectId,
      classId: a.classId,
      topicId: a.topicId,
      methodId: a.methodId!,
      assignmentId: _selectedAssignmentId,
    );
  }

  Future<Map<String, String>> _resolveNames(Iterable<String> uids) {
    final key = uids.join('|');
    return _nameBatchCache.putIfAbsent(
      key,
      () => StudentDisplayNameResolver.forUids(uids),
    );
  }

  List<CaseStudyCatalogRow> get _filteredCatalog {
    final all = InformatikaJsonPresets.caseStudyCatalogRows();
    final q = _catalogQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((r) => r.searchBlob.contains(q)).toList();
  }

  Future<void> _saveScenarioFromBuilder(String text) async {
    final a = _a;
    if (a?.methodId == null || a!.methodId!.isEmpty) return;
    final repo = context.read<MethodRepository>();
    final prev = await repo.fetchMethod(
          subjectId: a.subjectId,
          classId: a.classId,
          topicId: a.topicId,
          methodId: a.methodId!,
        );
    final base = Map<String, dynamic>.from(prev?.config ?? {});
    base['scenario'] = text.trim();
    try {
      await repo.updateMethodConfig(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
            config: base,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.caseStudyScenarioSavedSnack)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _saveSolutionPathDraft(String text) async {
    final a = _a;
    if (a?.methodId == null || a!.methodId!.isEmpty) return;
    final repo = context.read<MethodRepository>();
    final prev = await repo.fetchMethod(
          subjectId: a.subjectId,
          classId: a.classId,
          topicId: a.topicId,
          methodId: a.methodId!,
        );
    final base = Map<String, dynamic>.from(prev?.config ?? {});
    base['caseSolutionPath'] = text.trim();
    try {
      await repo.updateMethodConfig(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
            config: base,
          );
      if (mounted) {
        _refSolution = text.trim().isEmpty ? null : text.trim();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.caseStudySolutionKeySavedSnack)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openReviewSheet(
    DocumentSnapshot<Map<String, dynamic>> doc,
    AssignmentRouteArgs args,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final d = doc.data() ?? {};
    final who = await StudentDisplayNameResolver.forUid(doc.id);
    if (!mounted) return;

    final holder = <String>['${d['reviewStatus'] ?? 'submitted'}'];
    if (!['submitted', 'reviewed', 'returned'].contains(holder[0])) {
      holder[0] = 'submitted';
    }
    final commentCtrl = TextEditingController(text: '${d['teacherComment'] ?? ''}');
    final g0 = d['grade10'];
    var initialGrade = 0;
    if (g0 is num) {
      initialGrade = g0.round().clamp(0, 10);
    }
    final studentText = formatSubmissionAnswerForTeacher(d['answer']);
    final ref = _refSolution ?? '—';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              int starsToGrade(int s) => (s * 2).clamp(0, 10);
              final starCount = (initialGrade / 2).ceil().clamp(0, 5);

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.92,
                minChildSize: 0.55,
                maxChildSize: 0.95,
                builder: (ctx, scrollCtrl) {
                  return SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          who,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          l10n.caseStudyReviewCompareSubtitle,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (ctx, c) {
                            if (c.maxWidth < 560) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _comparePanel(
                                    ctx,
                                    title: l10n.caseStudyPanelStudent,
                                    body: studentText,
                                    color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 12),
                                  _comparePanel(
                                    ctx,
                                    title: l10n.caseStudyPanelReference,
                                    body: ref,
                                    color: Theme.of(ctx).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _comparePanel(
                                    ctx,
                                    title: l10n.caseStudyPanelStudent,
                                    body: studentText,
                                    color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.35),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _comparePanel(
                                    ctx,
                                    title: l10n.caseStudyPanelReference,
                                    body: ref,
                                    color: Theme.of(ctx).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.caseStudyQuickGrade, style: Theme.of(ctx).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (i) {
                            final filled = i < starCount;
                            return IconButton(
                              tooltip: l10n.caseStudyStarTooltipPoints((i + 1) * 2),
                              onPressed: () {
                                setSt(() => initialGrade = starsToGrade(i + 1));
                              },
                              icon: Icon(
                                filled ? Icons.star : Icons.star_border,
                                color: filled ? Colors.amber.shade700 : null,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                        Text(
                          l10n.caseStudyExactScore(initialGrade),
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        Slider(
                          value: initialGrade.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: '$initialGrade',
                          onChanged: (v) => setSt(() => initialGrade = v.round().clamp(0, 10)),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: holder[0],
                          decoration: InputDecoration(
                            labelText: l10n.reviewStatusFieldLabel,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'submitted',
                              child: Text(l10n.submissionStatusSubmitted),
                            ),
                            DropdownMenuItem(
                              value: 'reviewed',
                              child: Text(l10n.submissionStatusReviewed),
                            ),
                            DropdownMenuItem(
                              value: 'returned',
                              child: Text(l10n.submissionStatusReturned),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setSt(() => holder[0] = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: commentCtrl,
                          minLines: 2,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: l10n.teacherComment,
                            hintText: l10n.caseStudyCommentHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.save),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    if (ok != true || !mounted) {
      commentCtrl.dispose();
      return;
    }
    try {
      await context.read<SubmissionRepository>().updateSubmissionReview(
            args: args,
            studentId: doc.id,
            reviewStatus: holder[0],
            teacherComment:
                commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
            teacherGrade10: initialGrade,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.save)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      commentCtrl.dispose();
    }
  }

  Widget _comparePanel(
    BuildContext ctx, {
    required String title,
    required String body,
    required Color color,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.labelLarge),
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _probeChips(Map<String, dynamic> d, AppLocalizations l10n) {
    final probes = CaseStudyDashboardAnalytics.probesFromSubmissionData(d);
    if (probes.isEmpty) {
      return Text(
        l10n.caseStudyNoProbeSelections,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(probes.length, (i) {
        final p = probes[i];
        final ok = p['correct'] != false;
        final short = _truncate('${p['label'] ?? ''}', 24);
        return Chip(
          label: Text('${i + 1}. $short', style: const TextStyle(fontSize: 12)),
          backgroundColor: ok
              ? Colors.green.shade50
              : Colors.red.shade50,
          side: BorderSide(color: ok ? Colors.green.shade200 : Colors.red.shade200),
        );
      }),
    );
  }

  String _truncate(String s, int max) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  Widget _heatmapCard(Map<String, int> heat, AppLocalizations l10n) {
    if (heat.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.caseStudyHeatmapEmpty,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    final maxC = heat.values.reduce((a, b) => a > b ? a : b);
    final entries = heat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.caseStudyHeatmapTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...entries.map((e) {
              final frac = maxC == 0 ? 0.0 : e.value / maxC;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.key}  ·  ${e.value}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _liveCasePanel({
    required bool showLearnerTable,
    required AppLocalizations l10n,
  }) {
    final a = _a;
    if (a?.methodId == null || a!.methodId!.isEmpty) {
      return Center(child: Text(l10n.caseStudyMethodNotSelected));
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<AssignmentRepository>().watchAssignmentsForMethod(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
          ),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return Center(child: Text(l10n.caseStudyNoAssignments));
        }
        if (_selectedAssignmentId == null ||
            !list.any((e) => e['id'] == _selectedAssignmentId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedAssignmentId = '${list.first['id']}');
          });
        }
        final args = _assignmentArgs();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DropdownButtonFormField<String>(
                value: _selectedAssignmentId != null &&
                        list.any((e) => e['id'] == _selectedAssignmentId)
                    ? _selectedAssignmentId
                    : '${list.first['id']}',
                decoration: InputDecoration(
                  labelText: l10n.caseStudyAssignmentPickerLabel,
                  border: const OutlineInputBorder(),
                ),
                items: list
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: '${e['id']}',
                        child: Text('${e['title'] ?? e['id']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAssignmentId = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: args == null
                  ? const SizedBox.shrink()
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream:
                          context.read<SubmissionRepository>().watchSubmissions(args),
                      builder: (context, subSnap) {
                        if (subSnap.hasError) {
                          return Center(child: Text('${subSnap.error}'));
                        }
                        if (!subSnap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = subSnap.data!.docs;
                        final heat =
                            CaseStudyDashboardAnalytics.heatmapFromDocs(docs);
                        final pct =
                            CaseStudyDashboardAnalytics.percentAllCorrect(docs);
                        final dead =
                            CaseStudyDashboardAnalytics.deadEndCount(docs);

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (!showLearnerTable)
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.insights_outlined),
                                  title: Text(l10n.caseStudyVisualAnalysisTitle),
                                  subtitle: Text(
                                    l10n.caseStudyVisualAnalysisSubtitle,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            if (dead > 0)
                              Card(
                                color: Colors.orange.shade50,
                                child: ListTile(
                                  leading: const Icon(Icons.warning_amber_rounded),
                                  title: Text(
                                    l10n.caseStudyDeadEndWarning(dead),
                                  ),
                                ),
                              ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.caseStudyAllProbesCorrectTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(value: pct),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.caseStudyScenarioAnswerShare(
                                        '${(pct * 100).round()}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _heatmapCard(heat, l10n),
                            if (showLearnerTable) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.brainstormTabStudents,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<Map<String, String>>(
                                future: _resolveNames(docs.map((d) => d.id)),
                                builder: (context, nameSnap) {
                                  final names = nameSnap.data ?? {};
                                  if (docs.isEmpty) {
                                    return Text(l10n.caseStudyNoSubmissionsYet);
                                  }
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                      ),
                                      columns: [
                                        DataColumn(label: Text(l10n.caseStudyPanelStudent)),
                                        DataColumn(label: Text(l10n.caseStudyColTime)),
                                        DataColumn(label: Text(l10n.caseStudyColStages)),
                                        DataColumn(label: Text(l10n.caseStudyColWarning)),
                                        DataColumn(label: Text(l10n.caseStudyColGrade)),
                                        DataColumn(label: Text(l10n.caseStudyColActions)),
                                      ],
                                      rows: docs.map((doc) {
                                        final dd = doc.data();
                                        final at = dd['submittedAt'];
                                        var time = '—';
                                        if (at is Timestamp) {
                                          time = DateFormat.yMMMd()
                                              .add_Hm()
                                              .format(at.toDate());
                                        }
                                        final g = dd['grade10'];
                                        final gStr = g is num ? '${g.round()}' : '—';
                                        final warn =
                                            CaseStudyDashboardAnalytics.lastProbeIncorrect(dd)
                                                ? '!'
                                                : '';
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(names[doc.id] ?? doc.id)),
                                            DataCell(Text(time)),
                                            DataCell(SizedBox(
                                              width: 220,
                                              child: _probeChips(dd, l10n),
                                            )),
                                            DataCell(Text(warn)),
                                            DataCell(Text(gStr)),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.rate_review_outlined),
                                                onPressed: () => _openReviewSheet(doc, args),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _scenarioBody(AppLocalizations l10n) {
    final rows = _filteredCatalog;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            labelText: l10n.caseStudyCatalogSearchLabel,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _catalogQuery = v),
        ),

        const SizedBox(height: 16),
        Text(
          l10n.caseStudyJsonBankHint,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...rows.take(80).map(
              (r) => ListTile(
                dense: true,
                title: Text(r.topicName),
                subtitle: Text(r.gradeLabel),
                onTap: () {
                  setState(() {
                    _selectedCatalogRow = r;
                    _builderLines = caseStudyTaskLinesForEditor(r.topicEntry);
                  });
                },
              ),
            ),
        if (_builderLines.isNotEmpty) ...[
          const Divider(height: 32),
          Row(
            children: [
              Text(
                l10n.caseStudyEditOrderTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(_builderLines.clear),
                icon: const Icon(Icons.clear),
                label: Text(l10n.caseStudyClear),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _builderLines.length,
            onReorder: (o, n) {
              setState(() {
                if (n > o) n -= 1;
                final x = _builderLines.removeAt(o);
                _builderLines.insert(n, x);
              });
            },
            itemBuilder: (ctx, i) {
              return ListTile(
                key: ValueKey('line_$i/${ _builderLines[i] }'),
                leading: const Icon(Icons.drag_handle),
                title: Text(_builderLines[i], maxLines: 3, overflow: TextOverflow.ellipsis),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final first = _builderLines.isNotEmpty ? _builderLines.first : '';
                  await _saveScenarioFromBuilder(first);
                },
                icon: const Icon(Icons.text_snippet_outlined),
                label: Text(l10n.caseStudySaveFirstBandScenario),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final joined = _builderLines.join('\n\n');
                  await _saveScenarioFromBuilder(joined);
                },
                icon: const Icon(Icons.view_agenda_outlined),
                label: Text(l10n.caseStudySaveAllBandsScenario),
              ),
              OutlinedButton.icon(
                onPressed: _selectedCatalogRow == null
                    ? null
                    : () async {
                        final s =
                            caseStudyFirstInteractiveScenario(_selectedCatalogRow!.topicEntry);
                        if (s == null || s.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.caseStudyInteractiveScenarioMissing),
                              ),
                            );
                          }
                          return;
                        }
                        await _saveScenarioFromBuilder(s);
                      },
                icon: const Icon(Icons.security),
                label: Text(l10n.caseStudySaveInteractiveScenario),
              ),
              FilledButton.tonalIcon(
                onPressed: _builderLines.isEmpty
                    ? null
                    : () async {
                        final path = _builderLines.join('\n→ ');
                        await _saveSolutionPathDraft(path);
                      },
                icon: const Icon(Icons.route_outlined),
                label: Text(l10n.caseStudySaveSolutionOrder),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = _a;
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0));
    final adminTheme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
    if (a?.methodId == null || a!.methodId!.isEmpty) {
      return Theme(
        data: adminTheme,
        child: Scaffold(
          appBar: AppBar(
            leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
            leading: const AppBarBackOrHomeLeading(),
            title: Text(l10n.caseStudyAppBarPanel),
            actions: const [AppProfileIcon()],
          ),
          body: Center(child: Text(l10n.caseStudyNoMethodParams)),
        ),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Theme(
      data: adminTheme,
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(l10n.caseStudyAppBarDashboard),
          actions: const [AppProfileIcon()],
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: _section,
                onDestinationSelected: (i) => setState(() => _section = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: scheme.surfaceContainerLow,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard),
                    label: Text(l10n.caseStudyNavMonitoring),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.construction_outlined),
                    selectedIcon: const Icon(Icons.construction),
                    label: Text(l10n.caseStudyNavConstructor),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.pie_chart_outline),
                    selectedIcon: const Icon(Icons.pie_chart),
                    label: Text(l10n.caseStudyNavAnalysis),
                  ),
                ],
              ),
            if (wide) const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  if (!wide)
                    NavigationBar(
                      selectedIndex: _section,
                      onDestinationSelected: (i) => setState(() => _section = i),
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.dashboard_outlined),
                          label: l10n.caseStudyNavMonitoring,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.construction_outlined),
                          label: l10n.caseStudyNavConstructor,
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.pie_chart_outline),
                          label: l10n.caseStudyNavAnalysis,
                        ),
                      ],
                    ),
                  Expanded(
                    child: switch (_section) {
                      0 => _liveCasePanel(showLearnerTable: true, l10n: l10n),
                      1 => _scenarioBody(l10n),
                      2 => _liveCasePanel(showLearnerTable: false, l10n: l10n),
                      _ => _liveCasePanel(showLearnerTable: true, l10n: l10n),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
