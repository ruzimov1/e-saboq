// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assignments/brainstorm_create_payload.dart';
import '../../../../core/assignments/brainstorm_session_config.dart';
import '../../../../core/curriculum/brainstorm_topic_model.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../router/app_router.dart';
import '../../../../router/assignment_route_args.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../data/assignment_repository.dart';

/// JSON banki: accordion, ko'p tanlov, tasodifiy 3, tahrir, batch yaratish.
class BrainstormQuestionBankScreen extends StatefulWidget {
  const BrainstormQuestionBankScreen({super.key, required this.args});

  final BrainstormQuestionBankRouteArgs args;

  @override
  State<BrainstormQuestionBankScreen> createState() =>
      _BrainstormQuestionBankScreenState();
}

class _BrainstormQuestionBankScreenState extends State<BrainstormQuestionBankScreen> {
  bool _useBank = true;
  int _step = 0;
  final Set<String> _selectedKeys = {};
  final List<TextEditingController> _editControllers = [];
  List<BrainstormTopicModel> _topics = const [];
  bool _loading = true;
  int _duration = 3;
  int _minIdeas = 1;
  int _maxIdeas = 5;
  bool _anonymous = false;
  bool _creating = false;

  BrainstormQuestionBankRouteArgs get _a => widget.args;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _loadTopics() {
    final list = InformatikaJsonPresets.brainstormTopicBankForSelectedTopic(
      classId: _a.classId,
      topicLabel: CurriculumPresets.topicLabel(
        _a.subjectId,
        _a.classId,
        _a.topicId,
      ),
    );
    setState(() {
      _topics = list;
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _editControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _k(int topicIndex, int qIndex) => '$topicIndex:$qIndex';

  void _parseKey(String k, void Function(int t, int q) fn) {
    final p = k.split(':');
    if (p.length != 2) {
      return;
    }
    final t = int.tryParse(p[0]);
    final q = int.tryParse(p[1]);
    if (t == null || q == null) {
      return;
    }
    fn(t, q);
  }

  void _selectAll() {
    setState(() {
      for (final top in _topics) {
        for (var i = 0; i < top.questions.length; i++) {
          _selectedKeys.add(_k(top.index, i));
        }
      }
    });
  }

  void _clearSelection() {
    setState(_selectedKeys.clear);
  }

  void _randomThreeForTopic(BrainstormTopicModel t) {
    if (t.questions.isEmpty) {
      return;
    }
    final n = math.min(3, t.questions.length);
    final order = List<int>.generate(t.questions.length, (i) => i)..shuffle(math.Random());
    setState(() {
      for (var i = 0; i < n; i++) {
        _selectedKeys.add(_k(t.index, order[i]));
      }
    });
  }

  void _goToEditStep() {
    if (_selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida bitta savolni tanlang')),
      );
      return;
    }
    for (final c in _editControllers) {
      c.dispose();
    }
    _editControllers.clear();
    final keys = _selectedKeys.toList()..sort();
    for (final k in keys) {
      _parseKey(k, (ti, qi) {
        String text = '';
        for (final t in _topics) {
          if (t.index == ti && qi < t.questions.length) {
            text = t.questions[qi];
            break;
          }
        }
        _editControllers.add(TextEditingController(text: text));
      });
    }
    setState(() => _step = 1);
  }

  void _backToSelect() {
    setState(() => _step = 0);
  }

  String _classLabel() {
    final m = RegExp(r'\d+').firstMatch(_a.classId);
    if (m == null) {
      return _a.classId;
    }
    final n = m.group(0);
    if (n == '10' || n == '11') {
      return '10–11-sinf';
    }
    return '$n-sinf';
  }

  Future<void> _openOwnQuestionFlow() async {
    final presets = CurriculumPresets.presetAssignmentTemplatesForMethod(
      subjectId: _a.subjectId,
      classId: _a.classId,
      topicId: _a.topicId,
      methodId: _a.methodId,
    );
    final template = presets.isNotEmpty
        ? presets.first
        : const PresetAssignmentTemplate(
            id: 'own_brainstorm',
            title: 'Aqliy hujum',
            subtitle: '',
          );
    if (!context.mounted) {
      return;
    }
    await context.push(
      AppRoutes.teacherCreateBrainstormTask,
      extra: CreateBrainstormTaskRouteArgs(
        subjectId: _a.subjectId,
        classId: _a.classId,
        topicId: _a.topicId,
        methodId: _a.methodId,
        template: template,
        listIndex0: 0,
      ),
    );
  }

  Future<void> _createBatch() async {
    if (_editControllers.isEmpty) {
      return;
    }
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      return;
    }
    final keys = _selectedKeys.toList()..sort();
    if (keys.length != _editControllers.length) {
      return;
    }

    setState(() => _creating = true);
    final session = BrainstormSessionConfig(
      durationMinutes: _duration,
      minIdeasPerStudent: _minIdeas,
      maxIdeasPerStudent: _maxIdeas,
      isAnonymous: _anonymous,
    );
    var created = 0;
    try {
      final repo = context.read<AssignmentRepository>();
      for (var i = 0; i < keys.length; i++) {
        final k = keys[i];
        var topicName = '';
        _parseKey(k, (ti, _) {
          for (final t in _topics) {
            if (t.index == ti) {
              topicName = t.name;
              break;
            }
          }
        });
        final text = _editControllers[i].text.trim();
        if (text.isEmpty) {
          continue;
        }
        final title =
            'Aqliy hujum · $topicName · ${i + 1}/${keys.length}';
        final built = buildBrainstormAssignmentData(
          teacherId: auth.user.id,
          subjectId: _a.subjectId,
          classId: _a.classId,
          topicId: _a.topicId,
          methodId: _a.methodId,
          template: const PresetAssignmentTemplate(
            id: 'question_bank',
            title: 'Aqliy hujum',
            subtitle: '',
          ),
          listIndex0: 0,
          rowTitle: title,
          mainConcept: text,
          session: session,
          applyInformatikaJsonSlot: false,
        );
        final data = Map<String, dynamic>.from(built.data);
        data['title'] = title;
        data['fromQuestionBank'] = true;
        final rawEmb = data['embeddedMethodConfig'];
        if (rawEmb is Map) {
          final emb = Map<String, dynamic>.from(rawEmb);
          emb['title'] = title;
          emb['prompt'] = text;
          data['embeddedMethodConfig'] = emb;
        }

        await repo.createAssignment(
          subjectId: _a.subjectId,
          classId: _a.classId,
          topicId: _a.topicId,
          methodId: _a.methodId,
          assignmentId: built.assignmentId,
          data: data,
        );
        created++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$created ta topshiriq yaratildi')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final band = brainstormBandForClassId(_a.classId);
    final t = Theme.of(context);
    final bandColor = band == BrainstormGradeBand.lower
        ? t.colorScheme.tertiaryContainer.withValues(alpha: 0.7)
        : t.colorScheme.secondaryContainer.withValues(alpha: 0.7);
    final bandIcon = band == BrainstormGradeBand.lower
        ? Icons.draw_outlined
        : Icons.engineering_outlined;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_step == 1) {
      return _buildEditStep(t, bandColor, bandIcon);
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('Aqliy hujum · savollar'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _bandHeader(t, bandColor, bandIcon),
          const SizedBox(height: 12),
          Text(
            'Sinf: ${_classLabel()} · Mavzu: ${CurriculumPresets.topicLabel(
              _a.subjectId,
              _a.classId,
              _a.topicId,
            )}',
            style: t.textTheme.bodySmall?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('O‘z savolim'),
                icon: Icon(Icons.edit_outlined, size: 18),
              ),
              ButtonSegment(
                value: true,
                label: Text('Tayyor savollar'),
                icon: Icon(Icons.library_books_outlined, size: 18),
              ),
            ],
            selected: {_useBank},
            onSelectionChanged: (s) {
              setState(() {
                _useBank = s.first;
              });
            },
          ),
          const SizedBox(height: 20),
          if (!_useBank) ...[
            Text(
              'Boshqa ekranda savol, taymer va g‘oyalar chegarasini to‘ldirasiz.',
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openOwnQuestionFlow,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('O‘z savolimni yaratish'),
            ),
          ] else if (_topics.isEmpty) ...[
            Text(
              'Ushbu mavzu uchun aqliy-hujum JSON faylida mos yozuv topilmadi '
              'yoki bank bo‘sh. Sinf/mavzuni tekshiring.',
              style: t.textTheme.bodyMedium,
            ),
          ] else ...[
            if (_topics.length == 1)
              Text(
                'Savollar (tanlang)',
                style: t.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_topics.length == 1) const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Barcha savollarni belgilash'),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Tozalash'),
                ),
                if (_topics.length == 1) ...[
                  TextButton.icon(
                    onPressed: () => _randomThreeForTopic(_topics[0]),
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('Tasodifiy 3'),
                  ),
                ],
                const Spacer(),
                Text(
                  '${_selectedKeys.length} ta tanlangan',
                  style: t.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (_topics.length == 1)
              for (var qi = 0; qi < _topics[0].questions.length; qi++)
                CheckboxListTile(
                  value: _selectedKeys.contains(
                    _k(_topics[0].index, qi),
                  ),
                  onChanged: (v) {
                    setState(() {
                      final key = _k(_topics[0].index, qi);
                      if (v == true) {
                        _selectedKeys.add(key);
                      } else {
                        _selectedKeys.remove(key);
                      }
                    });
                  },
                  title: Text(
                    _topics[0].questions[qi],
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                )
            else
              for (var ti = 0; ti < _topics.length; ti++) ...[
                _topicAccordion(
                  t,
                  _topics[ti],
                  band,
                ),
                if (ti < _topics.length - 1) const SizedBox(height: 4),
              ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Sessiya (barcha tanlanganlar uchun bir xil)', style: t.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _duration,
              decoration: const InputDecoration(
                labelText: 'Taymer (daqiqa)',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<int>>[
                const DropdownMenuItem(value: 0, child: Text('Cheksiz (0)')),
                ...[2, 3, 4, 5, 6, 7, 8, 9, 10]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m'))),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _duration = v);
                }
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '$_minIdeas',
                    decoration: const InputDecoration(
                      labelText: 'Min. fikr',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (s) {
                      _minIdeas = int.tryParse(s) ?? 1;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: '$_maxIdeas',
                    decoration: const InputDecoration(
                      labelText: 'Maks. fikr',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (s) {
                      _maxIdeas = int.tryParse(s) ?? 1;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Anonim doska'),
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _goToEditStep,
              child: const Text('Tanlovlarni tahrirlash'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bandHeader(ThemeData t, Color bandColor, IconData bandIcon) {
    return Material(
      color: bandColor,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(bandIcon, size: 32, color: t.colorScheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                brainstormBandForClassId(_a.classId) == BrainstormGradeBand.lower
                    ? '5–7-sinflar: sodda, ko‘p vizual'
                    : '8–11-sinflar: chuqurroq, professional savollar',
                style: t.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicAccordion(
    ThemeData theme,
    BrainstormTopicModel topic,
    BrainstormGradeBand band,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      color: band == BrainstormGradeBand.lower
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            topic.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _randomThreeForTopic(topic),
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text('Tasodifiy 3 ta (bu mavzu)'),
              ),
            ),
            for (var qi = 0; qi < topic.questions.length; qi++)
              CheckboxListTile(
                value: _selectedKeys.contains(_k(topic.index, qi)),
                onChanged: (v) {
                  setState(() {
                    final k = _k(topic.index, qi);
                    if (v == true) {
                      _selectedKeys.add(k);
                    } else {
                      _selectedKeys.remove(k);
                    }
                  });
                },
                title: Text(
                  topic.questions[qi],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditStep(ThemeData t, Color bandColor, IconData bandIcon) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _creating ? null : _backToSelect,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Savollarni tahrirlash'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _bandHeader(t, bandColor, bandIcon),
          const SizedBox(height: 12),
          Text(
            'Har bir savolni o‘z darsingizga moslab o‘zgartiring, keyin bitta bosishda '
            '${_editControllers.length} ta alohida topshiriq yaratiladi.',
            style: t.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _editControllers.length; i++) ...[
            Text('Topshiriq ${i + 1}', style: t.textTheme.labelLarge),
            const SizedBox(height: 4),
            TextFormField(
              controller: _editControllers[i],
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: _creating ? null : _backToSelect,
                child: const Text('Orqaga'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _creating ? null : _createBatch,
                  child: _creating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('${_editControllers.length} ta topshiriq yaratish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
