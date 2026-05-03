// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/localized_review_status.dart';
import '../../../../core/utils/submission_answer_format.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../teacher/assignments/data/assignment_lookup.dart';
import '../../../teacher/assignments/data/assignment_repository.dart';
import '../../../teacher/methods/data/method_model.dart';
import '../../../teacher/methods/data/method_repository.dart';
import '../data/submission_repository.dart';

/// Topshiriq yuborilgach: mavzu, o'z javobi, ball, o'qituvchi va (bo'lsa) AI izohi.
class StudentSubmissionDetailScreen extends StatefulWidget {
  const StudentSubmissionDetailScreen({
    super.key,
    required this.initialLookup,
  });

  final AssignmentLookup initialLookup;

  @override
  State<StudentSubmissionDetailScreen> createState() =>
      _StudentSubmissionDetailScreenState();
}

class _StudentSubmissionDetailScreenState
    extends State<StudentSubmissionDetailScreen> {
  AssignmentLookup? _lookup;
  MethodModel? _method;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssignment());
  }

  Future<void> _loadAssignment() async {
    final l0 = widget.initialLookup;
    try {
      final full = await context.read<AssignmentRepository>().fetchAssignmentLookup(
            subjectId: l0.subjectId,
            classId: l0.classId,
            topicId: l0.topicId,
            methodId: l0.methodId,
            assignmentId: l0.assignmentId,
          );
      final lookup = full ?? l0;
      if (!mounted) return;
      var m = await context.read<MethodRepository>().fetchMethod(
            subjectId: lookup.subjectId,
            classId: lookup.classId,
            topicId: lookup.topicId,
            methodId: lookup.methodId,
          );
      final embedded = lookup.data['embeddedMethodConfig'] as Map<String, dynamic>?;
      if (embedded != null && m != null) {
        final base = Map<String, dynamic>.from(m.config ?? {});
        embedded.forEach((k, v) {
          if (v != null) {
            base[k] = v;
          }
        });
        m = m.copyWith(config: base);
      }
      if (!mounted) return;
      setState(() {
        _lookup = lookup;
        _method = m;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _lookup = l0;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _lookup;
    final l10n = AppLocalizations.of(context)!;
    if (_loading || l == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          leading: const AppBarBackOrHomeLeading(),
          title: Text(AppLocalizations.of(context)!.studentSubmissionScreenTitle),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final title = l.data['title'] as String? ?? AppLocalizations.of(context)!.assignmentUntitled;
    final auth = context.watch<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: Text(title),
          leading: const AppBarBackOrHomeLeading(),
        ),
        body: Center(
          child: Text(l10n.studentDetailLoginForAnswer),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: Text(title),
        actions: const [AppProfileIcon()],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: context.read<SubmissionRepository>().watchSubmissionForStudent(
              lookup: l,
              studentId: auth.user.id,
            ),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(
              child: Text(l10n.studentSubmissionMissing),
            );
          }
          final d = snap.data!.data() ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: _content(
              context,
              d,
              l10n,
              auth.user.id,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    Map<String, dynamic> d,
    AppLocalizations l10n,
    String studentId,
  ) {
    final l = _lookup;
    final m = _method;
    if (l == null) {
      return [const Text('—')];
    }
    final review = d['reviewStatus'] as String? ?? 'submitted';
    final score = d['score'];
    final g10 = d['grade10'];
    final tc = d['teacherComment'] as String?;
    final ai = d['aiFeedback'] as String?;
    final at = d['submittedAt'];
    String timeStr = '—';
    if (at is Timestamp) {
      timeStr = DateFormat.yMMMd().add_Hm().format(at.toDate());
    }
    final statusLabel = localizedReviewStatus(l10n, review);

    final quizSuffix = (score != null && m?.type == 'quiz')
        ? l10n.studentDetailQuizPointsSuffix(
            (score is num) ? score.toStringAsFixed(0) : '$score',
          )
        : '';
    final statusChipLabel =
        '${l10n.studentDetailStatusLabel}: $statusLabel$quizSuffix';

    return [
      Text(l10n.studentCodeLine('${l.data['code'] ?? '—'}'), style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 8),
      Text(l10n.studentDetailSubmittedAt(timeStr), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 6),
      Chip(
        label: Text(statusChipLabel),
      ),
      if (g10 is num) ...[
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: 0.45,
              ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.studentTeacherOverallGrade10(g10.round()),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      if (tc != null && tc.trim().isNotEmpty) ...[
        Text(
          l10n.teacherComment,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(tc.trim()),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (ai != null && ai.trim().isNotEmpty) ...[
        Text(
          l10n.aiFeedbackLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(ai.trim()),
          ),
        ),
        const SizedBox(height: 16),
      ],
      const Divider(),
      const SizedBox(height: 8),
      Text(l10n.studentAssignmentSectionTitle, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ..._methodContextTiles(context, m, l10n),
      if (m?.type == 'quiz') _buildQuizReadOnly(context, m!, d, l10n),
      if (m?.type == 'poll') _buildPollReadOnly(context, m!, d, l10n),
      if (m != null && m.type == 'brainstorm') ...[
        _buildBrainstormAnswerSection(context, d, m, l, studentId, l10n),
      ] else if (m == null || (m.type != 'quiz' && m.type != 'poll')) ...[
        const SizedBox(height: 8),
        Text(l10n.studentYourAnswer, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              _textAnswerFrom(d['answer'], m, l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
      const SizedBox(height: 32),
    ];
  }

  String _textAnswerFrom(dynamic answer, MethodModel? m, AppLocalizations l10n) {
    if (answer is Map) {
      final k = answer['kind'];
      if (k == 'text') {
        return '${answer['text'] ?? ''}';
      }
      if (k == 'quiz' || k == 'poll') {
        return l10n.studentAnswerShownAbove;
      }
      if (k == 'fishbone') {
        return formatSubmissionAnswerForTeacher(answer);
      }
      if (k == 'case') {
        return formatSubmissionAnswerForTeacher(answer);
      }
    }
    return formatSubmissionAnswerForTeacher(answer);
  }

  Widget _buildBrainstormAnswerSection(
    BuildContext context,
    Map<String, dynamic> d,
    MethodModel m,
    AssignmentLookup lookup,
    String studentId,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final body = formatSubmissionAnswerForTeacher(d['answer']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.studentYourAnswer, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              body.isNotEmpty ? body : '—',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.studentBrainstormTeacherPerIdea,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.studentBrainstormTeacherPerIdeaHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: context.read<SubmissionRepository>().watchIdeaFeedForStudent(
                lookup: lookup,
                studentId: studentId,
              ),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('${snap.error}', style: theme.textTheme.bodySmall);
            }
            if (!snap.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            var docs = snap.data!.docs.toList();
            docs.sort((a, b) {
              final la = a.data()['lineIndex'];
              final lb = b.data()['lineIndex'];
              if (la is num && lb is num) {
                return la.compareTo(lb);
              }
              final ta = a.data()['submittedAt'];
              final tb = b.data()['submittedAt'];
              if (ta is Timestamp && tb is Timestamp) {
                return ta.compareTo(tb);
              }
              return 0;
            });
            if (docs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.studentBrainstormIdeasMissingNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < docs.length; i++) ...[
                  _brainstormIdeaFeedbackCard(
                    context,
                    l10n,
                    docs[i].data(),
                    i + 1,
                  ),
                  if (i < docs.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _brainstormIdeaFeedbackCard(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> data,
    int number1Based,
  ) {
    final theme = Theme.of(context);
    final text = (data['text'] as String? ?? '').trim();
    final g = data['grade10'];
    final gi = g is num ? g.round().clamp(0, 10) : null;
    final c = (data['teacherComment'] as String?)?.trim();
    final hasFeedback =
        gi != null || (c != null && c.isNotEmpty);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$number1Based. ${text.isEmpty ? '—' : text}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            if (hasFeedback) ...[
              const SizedBox(height: 8),
              if (gi != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: Icon(
                      Icons.star_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(l10n.resultsGrade10Chip('$gi')),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (c != null && c.isNotEmpty) ...[
                if (gi != null) const SizedBox(height: 4),
                Text(
                  c,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.studentBrainstormNoTeacherGradeYet,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _methodContextTiles(
    BuildContext context,
    MethodModel? m,
    AppLocalizations l10n,
  ) {
    if (m == null) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.studentMethodLoadError),
          ),
        ),
      ];
    }
    final c = m.config;
    final out = <Widget>[];
    final cfgTitle = c?['title'] as String?;
    if (cfgTitle != null && cfgTitle.trim().isNotEmpty) {
      out.add(Text(cfgTitle.trim(), style: Theme.of(context).textTheme.titleSmall));
      out.add(const SizedBox(height: 8));
    }
    void addBlock(String label, String? text) {
      if (text == null || text.trim().isEmpty) {
        return;
      }
      out.add(Text(label, style: Theme.of(context).textTheme.labelLarge));
      out.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SelectableText(text.trim()),
          ),
        ),
      );
      out.add(const SizedBox(height: 8));
    }

    switch (m.type) {
      case 'case':
        addBlock(l10n.studentMethodCaseScenario, c?['scenario'] as String?);
        break;
      case 'brainstorm':
        addBlock(l10n.studentMethodBrainstormPrompt, c?['prompt'] as String?);
        final bg2 = c?['brainstormGuide'] as String?;
        if (bg2 != null && bg2.trim().isNotEmpty) {
          addBlock(l10n.studentMethodBrainstormGuide, bg2.trim());
        }
        break;
      case 'role_play':
        addBlock(l10n.studentMethodRoleRoles, c?['roles'] as String?);
        addBlock(l10n.studentMethodRoleScenario, c?['scenario'] as String?);
        break;
      case 'fishbone':
        addBlock(l10n.studentMethodFishboneDiagram, c?['sxema'] as String?);
        addBlock(l10n.studentMethodFishboneCenter, c?['problem'] as String?);
        addBlock(l10n.studentMethodFishboneBranches, c?['branches'] as String?);
        break;
      case 'group':
        addBlock(l10n.studentMethodGroupInstructions, c?['instructions'] as String?);
        break;
      default:
        break;
    }
    if (out.isEmpty) {
      return [const SizedBox.shrink()];
    }
    return out;
  }

  Widget _buildQuizReadOnly(
    BuildContext context,
    MethodModel m,
    Map<String, dynamic> d,
    AppLocalizations l10n,
  ) {
    final qs = m.config?['questions'] as List<dynamic>? ?? [];
    if (qs.isEmpty) {
      return Text(l10n.studentQuizNotConfigured);
    }
    final answer = d['answer'];
    final choices = <int?>[];
    if (answer is Map && answer['kind'] == 'quiz') {
      final raw = answer['choices'];
      if (raw is List) {
        for (final e in raw) {
          if (e == null) {
            choices.add(null);
          } else if (e is num) {
            choices.add(e.toInt());
          } else {
            choices.add(int.tryParse('$e'));
          }
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.studentYourAnswers, style: Theme.of(context).textTheme.titleSmall),
        for (var i = 0; i < qs.length; i++) _buildQuizQ(context, l10n, i, qs[i], choices),
      ],
    );
  }

  Widget _buildQuizQ(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    dynamic raw,
    List<int?> choices,
  ) {
    final q = raw as Map<String, dynamic>?;
    if (q == null) {
      return const SizedBox.shrink();
    }
    final text = q['question'] as String? ?? '';
    final opts = (q['options'] as List<dynamic>?)?.map((e) => '$e').toList() ?? [];
    final picked = index < choices.length ? choices[index] : null;
    final correct = (q['correctIndex'] as num?)?.toInt();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${index + 1}. $text',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (var j = 0; j < opts.length; j++) ...[
              ListTile(
                dense: true,
                title: Text(
                  opts[j],
                  style: TextStyle(
                    fontWeight: j == picked ? FontWeight.w600 : null,
                    color: j == correct
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                leading: Icon(
                  j == picked ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: j == picked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            if (picked != null &&
                correct != null &&
                picked == correct) ...[
              const SizedBox(height: 4),
              Text(
                l10n.studentQuizCorrect,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
            ] else if (correct != null && picked != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.studentQuizCorrectOption(
                  opts.length > correct ? opts[correct] : '${correct + 1}',
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPollReadOnly(
    BuildContext context,
    MethodModel m,
    Map<String, dynamic> d,
    AppLocalizations l10n,
  ) {
    final opts = (m.config?['options'] as List<dynamic>?)?.map((e) => '$e').toList() ??
        <String>['Ha', 'Yo\'q', 'Bilmayman'];
    int? choice;
    final answer = d['answer'];
    if (answer is Map && answer['kind'] == 'poll') {
      final c = answer['choice'];
      if (c is num) {
        choice = c.toInt();
      } else if (c != null) {
        choice = int.tryParse('$c');
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.studentPollAnswerHeading, style: Theme.of(context).textTheme.titleSmall),
        for (var j = 0; j < opts.length; j++)
          ListTile(
            dense: true,
            title: Text(
              opts[j],
              style: TextStyle(
                fontWeight: j == choice ? FontWeight.w600 : null,
              ),
            ),
            leading: Icon(
              j == choice ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
            ),
          ),
      ],
    );
  }
}
