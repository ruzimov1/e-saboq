import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../../../../core/ai/gemini_submission_reviewer.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/utils/localized_review_status.dart';
import '../../../../core/utils/student_display_name.dart';
import '../../../../core/utils/submission_answer_format.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../router/assignment_route_args.dart';
import '../../../student/assignments/data/submission_repository.dart';

enum _SubmissionResultsFilter {
  all,
  submitted,
  reviewed,
  returned,
  noTeacherGrade,
}

class AssignmentResultsScreen extends StatefulWidget {
  const AssignmentResultsScreen({super.key, this.args});

  final AssignmentRouteArgs? args;

  @override
  State<AssignmentResultsScreen> createState() => _AssignmentResultsScreenState();
}

class _AssignmentResultsScreenState extends State<AssignmentResultsScreen>
    with SingleTickerProviderStateMixin {
  String? _nameFutureKey;
  Future<Map<String, String>>? _nameFuture;
  TabController? _tabController;
  _SubmissionResultsFilter _submissionFilter = _SubmissionResultsFilter.all;
  DateTime? _submittedFrom;
  DateTime? _submittedTo;

  @override
  void initState() {
    super.initState();
    if (widget.args?.methodId == CurriculumPresets.brainstormId) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _csvForDocs(
    AppLocalizations l10n,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    Map<String, String>? displayNames,
  }) {
    final b = StringBuffer();
    b.writeln(
      '${l10n.csvColDisplayName},${l10n.csvColStudentId},${l10n.csvColSubmittedAt},'
      '${l10n.csvColScore},${l10n.csvColGrade10},${l10n.csvColReviewStatus},'
      '${l10n.csvColTeacherComment},${l10n.csvColAiFeedback},${l10n.csvColAnswerText}',
    );
    for (final doc in docs) {
      final d = doc.data();
      final at = d['submittedAt'];
      String time = '';
      if (at is Timestamp) {
        time = DateFormat('yyyy-MM-dd HH:mm').format(at.toDate());
      }
      final display =
          (displayNames?[doc.id] ?? doc.id).replaceAll('"', '""');
      final answerText = formatSubmissionAnswerForTeacher(
        d['answer'],
      ).replaceAll('"', '""');
      final comment = '${d['teacherComment'] ?? ''}'.replaceAll('"', '""');
      final ai = '${d['aiFeedback'] ?? ''}'.replaceAll('"', '""');
      final g10 = d['grade10'];
      b.writeln(
        '"$display",${doc.id},$time,${d['score'] ?? ''},'
        '${g10 is num ? g10 : ''},'
        '${d['reviewStatus'] ?? ''},'
        '"$comment","$ai","$answerText"',
      );
    }
    return b.toString();
  }

  Future<void> _copyCsv(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    Map<String, String>? displayNames,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    Map<String, String> names = displayNames ?? {};
    if (names.isEmpty) {
      names = await StudentDisplayNameResolver.forUids(docs.map((d) => d.id));
    }
    if (!context.mounted) {
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: _csvForDocs(l10n, docs, displayNames: names)),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.csvCopied)),
      );
    }
  }

  String? _avgGrade10(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final g = <double>[];
    for (final doc in docs) {
      final v = doc.data()['grade10'];
      if (v is num) {
        g.add(v.toDouble());
      }
    }
    if (g.isEmpty) {
      return null;
    }
    return (g.reduce((a, b) => a + b) / g.length).toStringAsFixed(1);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterSubmissions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    switch (_submissionFilter) {
      case _SubmissionResultsFilter.all:
        return docs;
      case _SubmissionResultsFilter.submitted:
        return docs.where((d) {
          final s = d.data()['reviewStatus'] as String? ?? 'submitted';
          return s == 'submitted';
        }).toList();
      case _SubmissionResultsFilter.reviewed:
        return docs.where((d) {
          final s = d.data()['reviewStatus'] as String? ?? '';
          return s == 'reviewed';
        }).toList();
      case _SubmissionResultsFilter.returned:
        return docs.where((d) {
          final s = d.data()['reviewStatus'] as String? ?? '';
          return s == 'returned';
        }).toList();
      case _SubmissionResultsFilter.noTeacherGrade:
        return docs.where((d) => d.data()['grade10'] is! num).toList();
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocsBySubmittedDateRange(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_submittedFrom == null && _submittedTo == null) return docs;
    return docs.where((d) {
      final at = d.data()['submittedAt'];
      if (at is! Timestamp) return false;
      final dt = at.toDate();
      if (_submittedFrom != null) {
        final from = DateTime(
          _submittedFrom!.year,
          _submittedFrom!.month,
          _submittedFrom!.day,
        );
        if (dt.isBefore(from)) return false;
      }
      if (_submittedTo != null) {
        final toEnd = DateTime(
          _submittedTo!.year,
          _submittedTo!.month,
          _submittedTo!.day,
          23,
          59,
          59,
          999,
        );
        if (dt.isAfter(toEnd)) return false;
      }
      return true;
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyAllSubmissionFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docsAll,
  ) {
    return _filterDocsBySubmittedDateRange(_filterSubmissions(docsAll));
  }

  Future<void> _pickSubmittedDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _submittedFrom != null && _submittedTo != null
          ? DateTimeRange(start: _submittedFrom!, end: _submittedTo!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 14)),
              end: now,
            ),
    );
    if (!mounted || range == null) return;
    setState(() {
      _submittedFrom = range.start;
      _submittedTo = range.end;
    });
  }

  void _clearDateRange() {
    setState(() {
      _submittedFrom = null;
      _submittedTo = null;
    });
  }

  Widget _dateRangeFilterRow(AppLocalizations l10n) {
    final hasRange = _submittedFrom != null && _submittedTo != null;
    final label = hasRange
        ? '${DateFormat.yMMMd().format(_submittedFrom!)} — ${DateFormat.yMMMd().format(_submittedTo!)}'
        : l10n.resultsDateRangePick;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _pickSubmittedDateRange,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(label),
          ),
          if (hasRange)
            TextButton.icon(
              onPressed: _clearDateRange,
              icon: const Icon(Icons.clear, size: 18),
              label: Text(l10n.resultsClearDateRange),
            ),
        ],
      ),
    );
  }

  Widget _submissionFilterChips(AppLocalizations l10n) {
    ChoiceChip chip(_SubmissionResultsFilter f, String label) {
      return ChoiceChip(
        label: Text(label),
        selected: _submissionFilter == f,
        onSelected: (_) => setState(() => _submissionFilter = f),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          chip(_SubmissionResultsFilter.all, l10n.resultsFilterAll),
          const SizedBox(width: 8),
          chip(_SubmissionResultsFilter.submitted, l10n.resultsFilterSubmitted),
          const SizedBox(width: 8),
          chip(_SubmissionResultsFilter.reviewed, l10n.resultsFilterReviewed),
          const SizedBox(width: 8),
          chip(_SubmissionResultsFilter.returned, l10n.resultsFilterReturned),
          const SizedBox(width: 8),
          chip(_SubmissionResultsFilter.noTeacherGrade, l10n.resultsFilterNoGrade),
        ],
      ),
    );
  }

  String? _avgQuizScore(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final scores = <double>[];
    for (final doc in docs) {
      final s = doc.data()['score'];
      if (s is num) scores.add(s.toDouble());
    }
    if (scores.isEmpty) return null;
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return avg.toStringAsFixed(0);
  }

  Future<void> _openAiReview(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.args!;
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiKeyMissing)),
        );
      }
      return;
    }
    final d = doc.data() ?? {};
    final title = '${d['assignmentTitle'] ?? l10n.assignmentUntitled}';
    final answerText = formatSubmissionAnswerForTeacher(d['answer']);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.aiReviewLoading)),
          ],
        ),
      ),
    );

    String? resultText;
    Object? err;
    try {
      resultText = await GeminiSubmissionReviewer.reviewSubmission(
        apiKey: key,
        assignmentTitle: title,
        answerDescription: answerText,
      );
    } catch (e) {
      err = e;
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (err != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
      return;
    }
    final text = resultText ?? '';
    if (text.isEmpty || !context.mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiReviewTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.aiDisclaimer,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(text),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.aiSaveToSubmission),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      try {
        await context.read<SubmissionRepository>().setSubmissionAiFeedback(
              args: a,
              studentId: doc.id,
              aiFeedback: text,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.aiFeedbackSaved)),
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
  }

  String _initialLetter(String s) {
    final t = s.trim();
    if (t.isEmpty) {
      return '?';
    }
    return t[0].toUpperCase();
  }

  String _truncateForList(String s, {int max = 140}) {
    final t = s.trim();
    if (t.length <= max) {
      return t;
    }
    return '${t.substring(0, max)}…';
  }

  Future<void> _openReviewSheet(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? studentLabel,
  }) async {
    final a = widget.args!;
    final l10n = AppLocalizations.of(context)!;
    final d = doc.data() ?? {};
    final who = studentLabel ?? await StudentDisplayNameResolver.forUid(doc.id);
    if (!context.mounted) {
      return;
    }
    final holder = <String>['${d['reviewStatus'] ?? 'submitted'}'];
    if (!['submitted', 'reviewed', 'returned'].contains(holder[0])) {
      holder[0] = 'submitted';
    }
    final commentCtrl = TextEditingController(
      text: '${d['teacherComment'] ?? ''}',
    );
    final g0 = d['grade10'];
    var initialGrade = 0;
    if (g0 is num) {
      initialGrade = g0.round().clamp(0, 10);
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text('$who · ${l10n.reviewSave}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.gradeOutOfTenTitle,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$initialGrade',
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                      const Text('/10'),
                    ],
                  ),
                  Slider(
                    value: initialGrade.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$initialGrade',
                    onChanged: (v) {
                      setSt(() => initialGrade = v.round().clamp(0, 10));
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(holder[0]),
                    initialValue: holder[0],
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
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) {
      commentCtrl.dispose();
      return;
    }
    try {
      await context.read<SubmissionRepository>().updateSubmissionReview(
            args: a,
            studentId: doc.id,
            reviewStatus: holder[0],
            teacherComment: commentCtrl.text.trim().isEmpty
                ? null
                : commentCtrl.text.trim(),
            teacherGrade10: initialGrade,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.save)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      commentCtrl.dispose();
    }
  }

  Widget _resultCard(
    BuildContext context,
    AppLocalizations l10n,
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String displayName,
  }) {
    final theme = Theme.of(context);
    final d = doc.data() ?? {};
    final score = d['score'];
    final g10 = d['grade10'];
    final answerMap = d['answer'];
    final isQuizAnswer =
        answerMap is Map && (answerMap['kind'] as String? ?? '') == 'quiz';
    final at = d['submittedAt'];
    var time = '—';
    if (at is Timestamp) {
      time = DateFormat.yMMMd().add_Hm().format(at.toDate());
    }
    final st = d['reviewStatus'] as String?;
    final tc = d['teacherComment'] as String?;
    final ai = d['aiFeedback'] as String?;
    final answerText = formatSubmissionAnswerForTeacher(d['answer']);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: CircleAvatar(
              child: Text(
                displayName.isNotEmpty
                    ? _initialLetter(displayName)
                    : '?',
              ),
            ),
            title: Text(
              displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              doc.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome_outlined),
                  onPressed: () => _openAiReview(context, doc),
                  tooltip: l10n.aiReviewTooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.rate_review_outlined),
                  onPressed: () => _openReviewSheet(
                    context,
                    doc,
                    studentLabel: displayName,
                  ),
                  tooltip: l10n.reviewSave,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    localizedReviewStatus(l10n, st),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (isQuizAnswer && score is num)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      l10n.resultsQuizPercent(score.toStringAsFixed(0)),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(
                    l10n.resultsGrade10Chip(
                      g10 is num ? g10.toStringAsFixed(0) : '—',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: const Icon(Icons.schedule, size: 16),
                  label: Text(
                    time,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.resultsAnswerHeading,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      answerText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (tc != null && tc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _metaLine(theme, l10n.teacherComment, tc, dense: true),
            ),
          if (ai != null && ai.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _metaLine(
                theme,
                l10n.aiFeedbackLabel,
                _truncateForList(ai, max: 500),
                dense: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaLine(
    ThemeData theme,
    String label,
    String body, {
    bool dense = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!dense) const SizedBox(height: 2),
        SelectableText(
          body,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _confirmDeleteIdea(
    BuildContext context,
    AssignmentRouteArgs a,
    String ideaDocId,
  ) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(loc.brainstormDeleteIdeaTitle),
          content: Text(loc.brainstormDeleteIdeaBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
    if (go != true || !context.mounted) {
      return;
    }
    try {
      await context.read<SubmissionRepository>().deleteIdeaDocument(
            args: a,
            ideaDocumentId: ideaDocId,
          );
      if (context.mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.brainstormIdeaDeleted)),
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

  Widget _submissionsListBody(
    AssignmentRouteArgs a,
    AppLocalizations l10n,
    SubmissionRepository repo,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchSubmissions(a),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docsAll = snap.data!.docs;
        if (docsAll.isEmpty) {
          return Center(child: Text(l10n.noSubmissionsYet));
        }
        final docs = _applyAllSubmissionFilters(docsAll);
        if (docs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _submissionFilterChips(l10n),
                    _dateRangeFilterRow(l10n),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.resultsNoMatchesFilter,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final idsKey =
            '${docs.map((d) => d.id).join('|')}#${_submissionFilter.name}#${_submittedFrom?.millisecondsSinceEpoch ?? 0}#${_submittedTo?.millisecondsSinceEpoch ?? 0}';
        if (idsKey != _nameFutureKey) {
          _nameFutureKey = idsKey;
          _nameFuture = StudentDisplayNameResolver.forUids(
            docs.map((d) => d.id),
          );
        }
        final avg = _avgQuizScore(docs);
        final avgG10 = _avgGrade10(docs);
        final isBrain = a.methodId == CurriculumPresets.brainstormId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _submissionFilterChips(l10n),
                  _dateRangeFilterRow(l10n),
                  const SizedBox(height: 10),
                  Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isBrain)
                    Chip(
                      label: Text(
                        avgG10 != null
                            ? l10n.brainstormAvgGrade(avgG10)
                            : l10n.brainstormAvgGradeNone,
                      ),
                    )
                  else if (avg != null)
                    Chip(
                      label: Text(l10n.avgQuizScore(avg)),
                    )
                  else
                    Chip(label: Text(l10n.noAvgQuiz)),
                  ActionChip(
                    avatar: const Icon(Icons.table_chart_outlined, size: 18),
                    label: Text(l10n.exportCsv),
                    onPressed: () => _copyCsv(context, docs),
                  ),
                ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, String>>(
                future: _nameFuture,
                builder: (context, nameSnap) {
                  if (nameSnap.connectionState == ConnectionState.waiting &&
                      !nameSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final names = nameSnap.data ?? {};
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      return _resultCard(
                        context,
                        l10n,
                        doc,
                        displayName: names[doc.id] ?? doc.id,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openIdeaFeedGradeDialog(
    BuildContext context,
    AssignmentRouteArgs a,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final d0 = doc.data();
    final g0 = d0['grade10'];
    var initialGrade = 0;
    if (g0 is num) {
      initialGrade = g0.round().clamp(0, 10);
    }
    final commentCtrl = TextEditingController(
      text: '${d0['teacherComment'] ?? ''}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text(l10n.brainstormIdeaGradeDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.gradeOutOfTenTitle,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$initialGrade',
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                      const Text('/10'),
                    ],
                  ),
                  Slider(
                    value: initialGrade.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$initialGrade',
                    onChanged: (v) {
                      setSt(() {
                        initialGrade = v.round().clamp(0, 10);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.teacherComment,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted) {
      commentCtrl.dispose();
      return;
    }
    try {
      await context.read<SubmissionRepository>().updateIdeaFeedTeacherFeedback(
            args: a,
            ideaDocumentId: doc.id,
            grade10: initialGrade,
            teacherComment: commentCtrl.text.trim().isEmpty
                ? null
                : commentCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.save)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      commentCtrl.dispose();
    }
  }

  Widget _ideaFeedBody(
    BuildContext context,
    AssignmentRouteArgs a,
    AppLocalizations l10n,
  ) {
    final repo = context.read<SubmissionRepository>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _dateRangeFilterRow(l10n),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: repo.watchIdeaFeed(a),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docsAll = snap.data!.docs.toList();
              docsAll.sort((A, B) {
                final ta = A.data()['submittedAt'];
                final tb = B.data()['submittedAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                return 0;
              });
              final docs = _filterDocsBySubmittedDateRange(docsAll);
              if (docsAll.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.brainstormIdeaFeedEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.resultsNoMatchesFilter,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final uids = <String>{};
              for (final d in docs) {
                final sid = d.data()['studentId'] as String? ?? '';
                if (sid.isNotEmpty) {
                  uids.add(sid);
                }
              }
              return FutureBuilder<Map<String, String>>(
                future: StudentDisplayNameResolver.forUids(uids),
                builder: (context, nameSnap) {
                  final names = nameSnap.data ?? {};
                  final t = Theme.of(context);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data();
                      final text = d['text'] as String? ?? '—';
                      final sid = d['studentId'] as String? ?? '';
                      final who = names[sid] ?? (sid.isEmpty ? '—' : sid);
                      final g10 = d['grade10'];
                      final tc = d['teacherComment'] as String?;
                      final gLabel =
                          g10 is num ? g10.toStringAsFixed(0) : '—';
                      return Card(
                        elevation: 0,
                        color: t.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: t.textTheme.bodyLarge,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.brainstormDeleteIdeaTitle,
                                    onPressed: () => _confirmDeleteIdea(
                                      context,
                                      a,
                                      doc.id,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.brainstormStudentLine(who),
                                style: t.textTheme.labelSmall?.copyWith(
                                  color: t.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    label: Text(l10n.resultsGrade10Chip(gLabel)),
                                  ),
                                  if (tc != null && tc.trim().isNotEmpty)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                          maxWidth: 500),
                                      child: Text(
                                        l10n.brainstormCommentLine(tc),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.textTheme.bodySmall
                                            ?.copyWith(
                                          color: t
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _openIdeaFeedGradeDialog(
                                    context,
                                    a,
                                    doc,
                                  ),
                                  icon: const Icon(
                                      Icons.edit_note_outlined,
                                      size: 20),
                                  label: Text(l10n.brainstormEditGradeComment),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.args;
    if (a == null || a.assignmentId == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(l10n.assignmentResults),
          actions: const [AppProfileIcon()],
        ),
        body: Center(
          child: Text(l10n.resultsAssignmentRouteMissing),
        ),
      );
    }
    final repo = context.read<SubmissionRepository>();
    final isBrain = a.methodId == CurriculumPresets.brainstormId;
    final tab = _tabController;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: Text(l10n.assignmentResults),
        actions: const [AppProfileIcon()],
        bottom: isBrain && tab != null
            ? TabBar(
                controller: tab,
                tabs: [
                  Tab(text: l10n.brainstormTabStudents),
                  Tab(text: l10n.brainstormTabIdeaFeed),
                ],
              )
            : null,
      ),
      body: isBrain && tab != null
          ? TabBarView(
              controller: tab,
              children: [
                _submissionsListBody(a, l10n, repo),
                _ideaFeedBody(context, a, l10n),
              ],
            )
          : _submissionsListBody(a, l10n, repo),
    );
  }
}
