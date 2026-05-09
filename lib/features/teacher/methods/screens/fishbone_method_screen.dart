// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/t_schema/t_schema_method_config.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../router/method_route_args.dart';
import '../data/method_repository.dart';

const _uuid = Uuid();

/// T-sxema — JSON bankidan mavzu, T-tartibdagi tahrir, interaktiv topshiriq sozlamalari.
class FishboneMethodScreen extends StatefulWidget {
  const FishboneMethodScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<FishboneMethodScreen> createState() => _FishboneMethodScreenState();
}

class _FishboneMethodScreenState extends State<FishboneMethodScreen> {
  final _sxema = TextEditingController();
  final _center = TextEditingController();
  final _leftTitle = TextEditingController();
  final _rightTitle = TextEditingController();

  List<String> _bankTopicNames = [];
  String? _selectedBankTopic;

  List<TSchemaStickerDef> _leftItems = [];
  List<TSchemaStickerDef> _rightItems = [];

  double _durationMinutes = 15;
  double _maxUserStickers = 3;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _sxema.dispose();
    _center.dispose();
    _leftTitle.dispose();
    _rightTitle.dispose();
    super.dispose();
  }

  List<String> _linesFromJson(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _fillFromBankEntry(Map<String, dynamic> entry) {
    _center.text = InformatikaJsonPresets.baseTopicName(
      '${entry['topic'] ?? entry['mavzu'] ?? ''}',
    ).trim().ifEmptyThen(_center.text);
    _leftTitle.text = '${entry['left_title'] ?? 'Afzalliklari'}'.trim();
    _rightTitle.text = '${entry['right_title'] ?? 'Kamchiliklari'}'.trim();
    _leftItems = [
      for (final line in _linesFromJson(entry['left']))
        TSchemaStickerDef(id: _uuid.v4(), text: line),
    ];
    _rightItems = [
      for (final line in _linesFromJson(entry['right']))
        TSchemaStickerDef(id: _uuid.v4(), text: line),
    ];
  }

  Future<void> _load() async {
    final a = widget.args;
    if (a?.methodId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!InformatikaJsonPresets.isReady) {
      await InformatikaJsonPresets.loadFromAssets();
    }
    if (!mounted) {
      return;
    }
    final m = await context.read<MethodRepository>().fetchMethod(
          subjectId: a!.subjectId,
          classId: a.classId,
          topicId: a.topicId,
          methodId: a.methodId!,
        );
    if (!mounted) {
      return;
    }
    final c = m?.config;
    _sxema.text = c?['sxema'] as String? ?? '';
    _bankTopicNames = InformatikaJsonPresets.tSchemaTopicNamesForClass(a.classId);
    _selectedBankTopic = null;

    final topicLabel = CurriculumPresets.topicLabel(a.subjectId, a.classId, a.topicId);

    final parsed = TSchemaMethodConfig.tryParse(
      c == null ? null : Map<String, dynamic>.from(c),
    );
    if (parsed != null) {
      _center.text = parsed.center;
      _leftTitle.text = parsed.leftTitle;
      _rightTitle.text = parsed.rightTitle;
      _leftItems = List<TSchemaStickerDef>.from(parsed.leftItems);
      _rightItems = List<TSchemaStickerDef>.from(parsed.rightItems);
      _durationMinutes = parsed.durationMinutes.toDouble();
      _maxUserStickers = parsed.maxUserStickers.toDouble();
      final bank = InformatikaJsonPresets.tSchemaTopicEntryForClass(
        classId: a.classId,
        topicLabel: topicLabel,
      );
        final bn = '${bank?['topic'] ?? bank?['mavzu'] ?? ''}'.trim();
        if (bn.isNotEmpty && _bankTopicNames.contains(bn)) {
          _selectedBankTopic = bn;
        } else if (_center.text.isNotEmpty) {
          String? match;
          for (final n in _bankTopicNames) {
            if (InformatikaJsonPresets.baseTopicName(n) ==
                InformatikaJsonPresets.baseTopicName(_center.text)) {
              match = n;
              break;
            }
          }
          _selectedBankTopic = match;
        }
    } else {
      _center.text = c?['problem'] as String? ?? '';
      _leftTitle.text = 'Afzalliklari';
      _rightTitle.text = 'Kamchiliklari';
      _leftItems = [];
      _rightItems = [];
      final bank = InformatikaJsonPresets.tSchemaTopicEntryForClass(
        classId: a.classId,
        topicLabel: topicLabel,
      );
      if (bank != null) {
        _fillFromBankEntry(bank);
        final bn = '${bank['topic'] ?? bank['mavzu'] ?? ''}'.trim();
        if (bn.isNotEmpty) {
          _selectedBankTopic = bn;
        }
      }
      _durationMinutes = (c?['tSchemaDurationMinutes'] as num?)?.toDouble() ?? 15;
      _maxUserStickers = (c?['tSchemaMaxUserStickers'] as num?)?.toDouble() ?? 3;
    }

    if (_selectedBankTopic == null && _bankTopicNames.isNotEmpty) {
      _selectedBankTopic = _bankTopicNames.first;
    }

    setState(() => _loading = false);
  }

  void _onBankTopicChanged(String? name) {
    if (name == null) {
      return;
    }
    final a = widget.args;
    if (a == null) {
      return;
    }
    final entry = InformatikaJsonPresets.tSchemaTopicEntryForClass(
      classId: a.classId,
      topicLabel: name,
    );
    if (entry == null) {
      setState(() => _selectedBankTopic = name);
      return;
    }
    setState(() {
      _selectedBankTopic = name;
      _fillFromBankEntry(entry);
    });
  }

  Future<void> _editItem(bool left, int index) async {
    final list = left ? _leftItems : _rightItems;
    if (index < 0 || index >= list.length) {
      return;
    }
    final ctrl = TextEditingController(text: list[index].text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(left ? _leftTitle.text : _rightTitle.text),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    final t = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || !mounted) {
      return;
    }
    setState(() {
      list[index] = list[index].copyWith(text: t);
    });
  }

  void _deleteItem(bool left, int index) {
    setState(() {
      if (left) {
        _leftItems = List.of(_leftItems)..removeAt(index);
      } else {
        _rightItems = List.of(_rightItems)..removeAt(index);
      }
    });
  }

  void _addItem(bool left) {
    setState(() {
      final def = TSchemaStickerDef(id: _uuid.v4(), text: '');
      if (left) {
        _leftItems = [..._leftItems, def];
      } else {
        _rightItems = [..._rightItems, def];
      }
    });
    _editItem(left, left ? _leftItems.length - 1 : _rightItems.length - 1);
  }

  Future<void> _save() async {
    final a = widget.args;
    if (a?.methodId == null) {
      return;
    }
    final leftTexts = _leftItems.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    final rightTexts = _rightItems.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    if (leftTexts.isEmpty && rightTexts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida bitta qator kiriting')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<MethodRepository>();
      final prev = await repo.fetchMethod(
            subjectId: a!.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
          );
      final base = Map<String, dynamic>.from(prev?.config ?? {});

      final leftJson = <Map<String, dynamic>>[];
      for (var i = 0; i < _leftItems.length; i++) {
        final t = _leftItems[i].text.trim();
        if (t.isEmpty) {
          continue;
        }
        leftJson.add({'id': _leftItems[i].id, 'text': t});
      }
      final rightJson = <Map<String, dynamic>>[];
      for (var i = 0; i < _rightItems.length; i++) {
        final t = _rightItems[i].text.trim();
        if (t.isEmpty) {
          continue;
        }
        rightJson.add({'id': _rightItems[i].id, 'text': t});
      }

      final center = _center.text.trim();
      base['sxema'] = _sxema.text.trim();
      base['problem'] = center;
      base['branches'] = [
        '${_leftTitle.text}: ${leftTexts.join('; ')}',
        '${_rightTitle.text}: ${rightTexts.join('; ')}',
      ].join('\n');
      base['tSchemaInteractive'] = true;
      base['tSchemaCenter'] = center.isEmpty ? 'Mavzu' : center;
      base['tSchemaLeftTitle'] = _leftTitle.text.trim().isEmpty ? 'Afzalliklar' : _leftTitle.text.trim();
      base['tSchemaRightTitle'] =
          _rightTitle.text.trim().isEmpty ? 'Kamchiliklar' : _rightTitle.text.trim();
      base['tSchemaLeftItems'] = leftJson;
      base['tSchemaRightItems'] = rightJson;
      base['tSchemaDurationMinutes'] = _durationMinutes.round().clamp(0, 120);
      base['tSchemaMaxUserStickers'] = _maxUserStickers.round().clamp(0, 20);

      await repo.updateMethodConfig(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
            config: base,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saqlandi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _tBar({required List<Widget> children}) {
    return CustomPaint(
      painter: _TBarPainter(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85)),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _columnCard({
    required String sideLabel,
    required List<TSchemaStickerDef> items,
    required bool left,
  }) {
    final titleCtrl = left ? _leftTitle : _rightTitle;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: sideLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Qatorlar (${items.length})', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => _addItem(left),
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Qator',
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (items.isEmpty)
              Text(
                'Hozircha bo‘sh',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...List.generate(items.length, (i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[i].text.isEmpty ? '(boʼsh)' : items[i].text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editItem(left, i),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () => _deleteItem(left, i),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.args?.methodId ?? '—';
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('T-sxema'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.args?.methodId == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('T-sxema'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: Text('Metod tanlanmagan')),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: Text('T-sxema · $id'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'JSON bankidagi mavzulardan tanlang, T-sxema qatorlarini tahrirlang. '
            'O‘quvchi interaktiv stikerlar bilan ishlaydi.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (_bankTopicNames.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: _selectedBankTopic != null && _bankTopicNames.contains(_selectedBankTopic)
                  ? _selectedBankTopic
                  : null,
              decoration: const InputDecoration(
                labelText: 'Mavzu (JSON bank)',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final n in _bankTopicNames)
                  DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: _onBankTopicChanged,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _sxema,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'T-sxema (yordamchi matn)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _center,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Markaz (mavzu / savol)',
                  border: InputBorder.none,
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _tBar(
            children: [
              Expanded(child: _columnCard(sideLabel: 'Chap ustun', items: _leftItems, left: true)),
              const SizedBox(width: 10),
              Expanded(child: _columnCard(sideLabel: 'O‘ng ustun', items: _rightItems, left: false)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Topshiriq sozlamalari', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Vaqt limiti: ${_durationMinutes.round()} daqiqa (0 — cheklovsiz)'),
                  Slider(
                    value: _durationMinutes.clamp(0, 90),
                    min: 0,
                    max: 90,
                    divisions: 90,
                    onChanged: (v) => setState(() => _durationMinutes = v),
                  ),
                  Text('O‘quvchi qo‘shishi mumkin bo‘lgan fikrlar: ${_maxUserStickers.round()}'),
                  Slider(
                    value: _maxUserStickers.clamp(0, 15),
                    min: 0,
                    max: 15,
                    divisions: 15,
                    onChanged: (v) => setState(() => _maxUserStickers = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Saqlash',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmptyThen(String fallback) => trim().isEmpty ? fallback : trim();
}

class _TBarPainter extends CustomPainter {
  _TBarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final midX = size.width / 2;
    final yTop = 0.0;
    final yStem = size.height * 0.45;
    canvas.drawLine(Offset(midX, yTop), Offset(midX, yStem), p);
    canvas.drawLine(Offset(0, yStem), Offset(size.width, yStem), p);
  }

  @override
  bool shouldRepaint(covariant _TBarPainter oldDelegate) => oldDelegate.color != color;
}
