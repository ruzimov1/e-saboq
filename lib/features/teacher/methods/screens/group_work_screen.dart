import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/curriculum/cluster_distractor_suggestions.dart';
import '../../../../core/curriculum/cluster_json_service.dart';
import '../../../../core/curriculum/cluster_template.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../router/app_router.dart';
import '../../../../router/method_route_args.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../assignments/data/assignment_repository.dart';
import '../data/method_repository.dart';
import '../widgets/cluster_mind_map_preview.dart';
import '../widgets/cluster_template_picker_sheet.dart';

const _kClusterPalette = <Color>[
  Color(0xFF6750A4),
  Color(0xFF006A6B),
  Color(0xFF7C4DFF),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFF57C00),
  Color(0xFFC2185B),
  Color(0xFF5D4037),
];

int _colorToInt(Color c) => c.toARGB32();

Color _intToColor(int? v) {
  if (v == null) return _kClusterPalette[0];
  return Color(v);
}

class _BranchEdit {
  _BranchEdit({
    required this.id,
    required this.controller,
    required this.isDistractor,
    required this.color,
    this.expectedKeyword,
  });

  final int id;
  final TextEditingController controller;
  bool isDistractor;
  Color color;
  /// JSONdagi [kalit_sozlar] matni; validatsiya uchun.
  final String? expectedKeyword;
}

class GroupWorkScreen extends StatefulWidget {
  const GroupWorkScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<GroupWorkScreen> createState() => _GroupWorkScreenState();
}

class _GroupWorkScreenState extends State<GroupWorkScreen> {
  final _center = TextEditingController();
  final _instructions = TextEditingController();
  final List<_BranchEdit> _branches = [];
  /// JSON shablonidan yuklanganda: markaz matni (solishtirish).
  String? _expectedCenter;
  bool _loading = true;
  bool _creatingAssignment = false;
  int _idSeq = 0;
  /// 0: markaz + shablon, 1: tarmoqlar, 2: ko‘rsatma va yakuniy tekshiruv
  int _wizardStep = 0;
  bool _templateSectionExpanded = true;
  /// To‘liq matn maydoni ochiq tarmoq id-lari
  final Set<int> _branchEditorExpanded = {};
  /// Shablon blokini qayta qurish (ExpansionTile `initiallyExpanded` ni yangilash uchun).
  int _templateExpansionKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _center.dispose();
    _instructions.dispose();
    for (final b in _branches) {
      b.controller.dispose();
    }
    super.dispose();
  }

  _BranchEdit _newBranch({String text = ''}) {
    final c = _colorForIndex(_branches.length);
    return _BranchEdit(
      id: _idSeq++,
      controller: TextEditingController(text: text),
      isDistractor: false,
      color: c,
      expectedKeyword: null,
    );
  }

  Color _colorForIndex(int i) {
    return _kClusterPalette[i % _kClusterPalette.length];
  }

  Future<void> _load() async {
    final a = widget.args;
    if (a?.methodId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final m = await context.read<MethodRepository>().fetchMethod(
          subjectId: a!.subjectId,
          classId: a.classId,
          topicId: a.topicId,
          methodId: a.methodId!,
        );
    if (!mounted) return;
    final c = m?.config;
    _expectedCenter = null;
    _center.text = c?['center'] as String? ?? '';
    _instructions.text = c?['instructions'] as String? ?? '';
    for (final b in _branches) {
      b.controller.dispose();
    }
    _branches.clear();
    final raw = c?['branches'];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final m = raw[i];
        if (m is! Map) continue;
        final text = '${m['text'] ?? ''}';
        final dis = m['isDistractor'] as bool? ?? false;
        final cv = m['color'];
        int? ci;
        if (cv is int) ci = cv;
        if (cv is num) ci = cv.toInt();
        _branches.add(
          _BranchEdit(
            id: _idSeq++,
            controller: TextEditingController(text: text),
            isDistractor: dis,
            color: ci != null ? _intToColor(ci) : _colorForIndex(i),
            expectedKeyword: null,
          ),
        );
      }
    }
    if (_branches.isEmpty) {
      _branches.add(_newBranch());
    }
    _branchEditorExpanded.clear();
    if (_center.text.isEmpty) {
      final t = c?['title'] as String? ?? '';
      if (t.startsWith('Klaster:')) {
        _center.text = t.substring('Klaster:'.length).trim();
      }
    }
    setState(() => _loading = false);
    _maybeAutoApplyInformatikaClusterTemplate();
  }

  /// `5_sinf_cluster_fixed.json` — markaz, tarmoqlar, umumiy ko‘rsatma.
  Map<String, dynamic>? _clusterTemplateForCurrentTopic() {
    final a = widget.args;
    if (a == null || a.subjectId != 'informatika') {
      return null;
    }
    if (!InformatikaJsonPresets.isReady) {
      return null;
    }
    final label = CurriculumPresets.topicLabel(
      a.subjectId,
      a.classId,
      a.topicId,
    );
    return InformatikaJsonPresets.clusterEditorDefaultsForTopic(
      classId: a.classId,
      topicLabel: label,
    );
  }

  /// Birinchi ochilganda metod bo‘sh bo‘lsa — shablonni avtomatik qo‘llaydi.
  void _maybeAutoApplyInformatikaClusterTemplate() {
    final a = widget.args;
    if (a == null || a.subjectId != 'informatika') {
      return;
    }
    if (!InformatikaJsonPresets.isReady) {
      return;
    }
    if (_center.text.trim().isNotEmpty) {
      return;
    }
    final hasAnyBranchText = _branches.any(
      (b) => b.controller.text.trim().isNotEmpty,
    );
    if (hasAnyBranchText) {
      return;
    }
    final data = _clusterTemplateForCurrentTopic();
    if (data == null) {
      return;
    }
    final list = (data['branchLabels'] as List<dynamic>?)
            ?.map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];
    if (list.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _applyClusterTemplateFromFile(silent: true);
    });
  }

  /// JSONdagi klaster shablonini forma maydonlariga yozadi.
  void _applyClusterTemplateFromFile({bool silent = false}) {
    final a = widget.args;
    if (a == null) {
      return;
    }
    if (a.subjectId != 'informatika') {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu funksiya hozircha faqat Informatika uchun'),
          ),
        );
      }
      return;
    }
    if (!InformatikaJsonPresets.isReady) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tayyor fayllar yuklanmadi — ilovani qayta ishga tushiring'),
          ),
        );
      }
      return;
    }
    final data = _clusterTemplateForCurrentTopic();
    if (data == null) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ushbu sinf/mavzu uchun klaster shablon topilmadi'),
          ),
        );
      }
      return;
    }
    final c = (data['center'] as String?)?.trim() ?? '';
    final list = (data['branchLabels'] as List<dynamic>?)
            ?.map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];
    if (c.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shablonda markaziy tushuncha topilmadi'),
          ),
        );
      }
      return;
    }
    for (final b in _branches) {
      b.controller.dispose();
    }
    setState(() {
      _expectedCenter = c;
      _branches.clear();
      _center.text = c;
      for (var i = 0; i < list.length; i++) {
        _branches.add(
          _BranchEdit(
            id: _idSeq++,
            controller: TextEditingController(text: list[i]),
            isDistractor: false,
            color: _colorForIndex(i),
            expectedKeyword: list[i],
          ),
        );
      }
      if (_branches.isEmpty) {
        _branches.add(_newBranch());
      }
      final u = (data['umumiy_markaziy_goya'] as String?)?.trim() ?? '';
      final m = (data['mavzu_nomi'] as String?)?.trim() ?? '';
      if (_instructions.text.trim().isEmpty) {
        final buf = StringBuffer();
        if (u.isNotEmpty) {
          buf.writeln('Fan yo‘nalishi: $u');
        }
        if (m.isNotEmpty) {
          buf.writeln('Mavzu: $m');
        }
        buf.write(
          'O‘quvchi kalit so‘zlarni (tarmoqlar) markaziy tushunchaga to‘g‘ri '
          'bog‘lashi kerak. Chalg‘ituvchi tarmoqlarni faqat siz belgilaysiz.',
        );
        _instructions.text = buf.toString();
      }
      _templateSectionExpanded = false;
      _templateExpansionKey++;
    });
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shablon qo‘llandi: "$c" · ${list.length} ta tarmoq',
          ),
        ),
      );
    }
  }

  String? _centerValidationError() {
    final ex = _expectedCenter;
    if (ex == null) {
      return null;
    }
    final t = _center.text.trim();
    if (t.isEmpty) {
      return null;
    }
    if (clusterStringsMatchEtalon(t, ex)) {
      return null;
    }
    return 'JSON dagi markaz matni bilan mos emas (yashil: mos kelganda).';
  }

  Future<void> _openClusterFromJsonPicker() async {
    if (!mounted) {
      return;
    }
    if (widget.args?.subjectId != 'informatika') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hozircha faqat Informatika uchun')),
      );
      return;
    }
    if (!InformatikaJsonPresets.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tayyor fayllar yuklanmadi — ilovani qayta ishga tushiring'),
        ),
      );
      return;
    }
    var initial = ClusterJsonService.pickerClassKeys.first;
    final cid = widget.args?.classId;
    if (cid != null) {
      final m = RegExp(r'\d+').firstMatch(cid)?.group(0);
      if (m == '10' || m == '11') {
        initial = '10_11';
      } else if (m != null && ClusterJsonService.pickerClassKeys.contains(m)) {
        initial = m;
      }
    }
    final r = await showClusterTemplatePickerSheet(
      context,
      initialPickerKey: initial,
    );
    if (!mounted || r == null) {
      return;
    }
    _applyClusterTemplatePickerResult(r);
  }

  void _applyClusterTemplatePickerResult(ClusterTemplatePickerResult r) {
    for (final b in _branches) {
      b.controller.dispose();
    }
    final t = r.template;
    setState(() {
      _branches.clear();
      _expectedCenter = t.centerForEditor;
      _center.text = t.centerForEditor;
      for (var i = 0; i < t.kalitSozlar.length; i++) {
        _branches.add(
          _BranchEdit(
            id: _idSeq++,
            controller: TextEditingController(text: t.kalitSozlar[i]),
            isDistractor: false,
            color: _colorForIndex(i),
            expectedKeyword: t.kalitSozlar[i],
          ),
        );
      }
      if (r.addDistractors) {
        final extra = suggestClusterDistractorsHeuristic(
          current: t,
          allTopicsInFile: r.templatesInSameFile,
          count: 3,
        );
        for (var j = 0; j < extra.length; j++) {
          final i = _branches.length;
          _branches.add(
            _BranchEdit(
              id: _idSeq++,
              controller: TextEditingController(text: extra[j]),
              isDistractor: true,
              color: _colorForIndex(i),
              expectedKeyword: null,
            ),
          );
        }
      }
      if (_branches.isEmpty) {
        _branches.add(_newBranch());
      }
      if (_instructions.text.trim().isEmpty) {
        final buf = StringBuffer();
        final u = r.umbrellaGoya;
        if (u != null && u.isNotEmpty) {
          buf.writeln('Fan yo‘nalishi: $u');
        }
        if (t.mavzuNomi.isNotEmpty) {
          buf.writeln('Mavzu: ${t.mavzuNomi}');
        }
        buf.write(
          'O‘quvchi kalit so‘zlarni (tarmoqlar) markaziy tushunchaga to‘g‘ri '
          'bog‘lashi kerak. Chalg‘ituvchi tarmoqlarni faqat siz belgilaysiz.',
        );
        _instructions.text = buf.toString();
      }
      _templateSectionExpanded = false;
      _templateExpansionKey++;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shablon yuklandi: ${t.centerForEditor}'),
        ),
      );
    }
  }

  /// Hozirgi formadan metod [config] xaritasi (masalan, o‘quvchi topshiriq snapshot).
  Future<Map<String, dynamic>> _composeClusterConfigMap() async {
    final a = widget.args;
    if (a?.methodId == null) {
      return <String, dynamic>{};
    }
    final methodRepo = context.read<MethodRepository>();
    final prev = await methodRepo.fetchMethod(
          subjectId: a!.subjectId,
          classId: a.classId,
          topicId: a.topicId,
          methodId: a.methodId!,
        );
    final base = Map<String, dynamic>.from(prev?.config ?? {});
    final centerText = _center.text.trim();
    final branchMaps = <Map<String, dynamic>>[];
    for (final b in _branches) {
      final t = b.controller.text.trim();
      if (t.isEmpty) continue;
      branchMaps.add({
        'text': t,
        'isDistractor': b.isDistractor,
        'color': _colorToInt(b.color),
      });
    }
    base['center'] = centerText;
    base['branches'] = branchMaps;
    base['instructions'] = _instructions.text.trim();
    final oldTitle = prev?.config?['title'] as String?;
    if (centerText.isNotEmpty) {
      base['title'] = 'Klaster: $centerText';
    } else if (oldTitle != null && oldTitle.trim().isNotEmpty) {
      base['title'] = oldTitle.trim();
    }
    return base;
  }

  void _openMethodAssignmentsList() {
    final a = widget.args;
    if (a?.methodId == null) return;
    context.push(
      AppRoutes.teacherMethodAssignmentsList(
        a!.classId,
        a.subjectId,
        a.topicId,
        a.methodId!,
      ),
    );
  }

  Future<void> _createAssignmentWithCode() async {
    final a = widget.args;
    if (a == null || a.methodId == null) return;
    if (Firebase.apps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topshiriq yaratish uchun Firebase ulangan bo‘lishi kerak'),
          ),
        );
      }
      return;
    }
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kirish talab qilinadi')),
        );
      }
      return;
    }
    final methodRepo = context.read<MethodRepository>();
    final assignmentRepo = context.read<AssignmentRepository>();
    setState(() => _creatingAssignment = true);
    try {
      final cfg = await _composeClusterConfigMap();
      if (!mounted) return;
      await methodRepo.updateMethodConfig(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
            config: cfg,
          );
      if (!mounted) return;
      final id = const Uuid().v4();
      final code = generateAssignmentCode();
      final title = CurriculumPresets.readyPresetRowTitle(
        methodId: a.methodId!,
        classId: a.classId,
        subjectId: a.subjectId,
        topicId: a.topicId,
        taskNumber1Based: 1,
      );
      await assignmentRepo.createAssignment(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId!,
            assignmentId: id,
            data: {
              'code': code,
              'title': title,
              'deadline': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 7)),
              ),
              'createdAt': FieldValue.serverTimestamp(),
              'fromClusterEditor': true,
              'teacherId': auth.user.id,
              'embeddedMethodConfig': Map<String, dynamic>.from(cfg),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Topshiriq yaratildi. O‘quvchi kodi: $code (7 kun). '
              'Kod nusxalang yoki «Topshiriqlar»da ko‘ring.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingAssignment = false);
    }
  }

  void _addBranch() {
    setState(() {
      final nb = _newBranch();
      _branches.add(nb);
      _branchEditorExpanded.add(nb.id);
    });
  }

  void _removeAt(int i) {
    if (_branches.length <= 1) {
      return;
    }
    final removed = _branches[i];
    setState(() {
      _branchEditorExpanded.remove(removed.id);
      removed.controller.dispose();
      _branches.removeAt(i);
    });
  }

  void _onReorder(int oldI, int newI) {
    setState(() {
      if (newI > oldI) {
        newI -= 1;
      }
      final x = _branches.removeAt(oldI);
      _branches.insert(newI, x);
    });
  }

  Widget _buildInformatikaTemplateCard(BuildContext context) {
    final a = widget.args;
    if (a == null || a.subjectId != 'informatika') {
      return const SizedBox.shrink();
    }
    final th = Theme.of(context);
    final topicTitle = CurriculumPresets.topicLabel(
      a.subjectId,
      a.classId,
      a.topicId,
    );
    if (!InformatikaJsonPresets.isReady) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: th.colorScheme.primary,
                  strokeWidth: 2.2,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Informatika klaster shablonlari yuklanmoqda…',
                  style: th.textTheme.bodySmall?.copyWith(
                    color: th.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final data = _clusterTemplateForCurrentTopic();
    if (data == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Klaster JSON shabloni',
                style: th.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ushbu sinf yoki mavzu uchun maxsus klaster yozuvi topilmadi '
                '(JSON). Markaz va tarmoqlarni qo‘lda kiriting.',
                style: th.textTheme.bodySmall?.copyWith(
                  color: th.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final u = (data['umumiy_markaziy_goya'] as String?)?.trim() ?? '';
    final m = (data['mavzu_nomi'] as String?)?.trim() ?? '';
    final centerPreview = (data['center'] as String?)?.trim() ?? '';
    final list = (data['branchLabels'] as List<dynamic>?)
            ?.map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      color: th.colorScheme.secondaryContainer.withValues(alpha: 0.4),
      child: ExpansionTile(
        key: ValueKey(_templateExpansionKey),
        initiallyExpanded: _templateSectionExpanded,
        onExpansionChanged: (open) {
          setState(() => _templateSectionExpanded = open);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          Icons.auto_awesome,
          size: 22,
          color: th.colorScheme.primary,
        ),
        title: Text(
          'Informatika klaster shabloni (JSON)',
          style: th.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Dars mavzusi: $topicTitle',
          style: th.textTheme.labelMedium?.copyWith(
            color: th.colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          if (u.isNotEmpty) ...[
            Text(
              u,
              style: th.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (m.isNotEmpty) ...[
            Text('Shablon: $m', style: th.textTheme.bodySmall),
            const SizedBox(height: 6),
          ],
          if (centerPreview.isNotEmpty) ...[
            Text(
              'Markaz: $centerPreview',
              style: th.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (list.isNotEmpty) ...[
            Text(
              'Tarmoqlar (${list.length}):',
              style: th.textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < list.length; i++)
                  Chip(
                    label: Text(
                      list[i],
                      style: th.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openClusterFromJsonPicker,
                  icon: const Icon(Icons.folder_open, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('Tayyor fayldan olish'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _applyClusterTemplateFromFile(silent: false),
                  icon: const Icon(Icons.auto_fix_high, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('Hozirgi mavzuga shablon'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Birinchi marta ochilganda, forma bo‘sh bo‘lsa, shu shablon '
            'avtomatik qo‘yiladi. «Umumiy ko‘rsatma» maydoni bo‘sh bo‘lsa, '
            'qisqa yo‘riqnama yoziladi.',
            style: th.textTheme.bodySmall?.copyWith(
              color: th.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static const double _kSplitBreakpoint = 1000;

  Widget _sectionCard({
    required String title,
    IconData? icon,
    required Widget child,
  }) {
    final th = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: th.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: th.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStepper() {
    final th = Theme.of(context);
    return Card(
      elevation: 0,
      color: th.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                label: Text('1. Asos'),
                icon: Icon(Icons.hub_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('2. Tarmoqlar'),
                icon: Icon(Icons.account_tree_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 2,
                label: Text('3. Yakunlash'),
                icon: Icon(Icons.fact_check_outlined, size: 18),
              ),
            ],
            selected: {_wizardStep},
            onSelectionChanged: (s) => setState(() => _wizardStep = s.first),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview({required double height}) {
    final h = math.max(180.0, math.min(height, 560.0));
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: ClusterMindMapPreview(
          center: _center.text,
          branches: [
            for (final b in _branches)
              (
                text: b.controller.text,
                color: b.color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitPreviewPanel() {
    final th = Theme.of(context);
    return ColoredBox(
      color: th.colorScheme.surfaceContainerLowest.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview_outlined,
                  size: 22,
                  color: th.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O‘quvchi ko‘rinishi (jonli)',
                    style: th.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Chap tomondagi maydonlar o‘zgarsa, sxema shu zahoti yangilanadi.',
              style: th.textTheme.bodySmall?.copyWith(
                color: th.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  return _buildLivePreview(height: c.maxHeight);
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tarmoq tartibini chap panelda tutqichdan ushlab o‘zgartirasiz.',
              style: th.textTheme.bodySmall?.copyWith(
                color: th.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWizardFormChildren({required bool splitLayout}) {
    final th = Theme.of(context);
    final a = widget.args;
    final isInf = a?.subjectId == 'informatika';
    final children = <Widget>[
      _buildWizardStepper(),
      const SizedBox(height: 16),
    ];

    if (_wizardStep == 0) {
      children.add(
        Text(
          'Guruh / klaster metodi: markaziy tushuncha va tarmoqlar. '
          'O‘quvchi tomonida barcha tarmoqlar bir xil ko‘rinadi; '
          'chalg‘ituvchilar faqat sizning nazorat panelida belgilanadi.',
          style: th.textTheme.bodySmall?.copyWith(
            color: th.colorScheme.onSurfaceVariant,
          ),
        ),
      );
      children.add(const SizedBox(height: 16));
      if (isInf) {
        children.add(_buildInformatikaTemplateCard(context));
        children.add(const SizedBox(height: 16));
      }
      children.add(
        _sectionCard(
          title: 'Mavzu va markaziy tushuncha',
          icon: Icons.hub_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _center,
                onChanged: (_) => setState(() {}),
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Markaziy tushuncha (klaster o‘zag\'i)',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  errorText: _centerValidationError(),
                ),
              ),
              if (_expectedCenter != null &&
                  _center.text.trim().isNotEmpty &&
                  clusterStringsMatchEtalon(
                    _center.text,
                    _expectedCenter!,
                  ))
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Text(
                    'JSONdagi markaz matni bilan mos (to‘g‘ri).',
                    style: TextStyle(
                      color: const Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (_wizardStep == 1) {
      children.add(
        Text(
          'Tarmoqlarni belgilang. Chapdagi belgidan ushlab surish tartibni o‘zgartiradi; '
          'qisqa ko‘rinishda tahrir uchun qalam tugmasini bosing.',
          style: th.textTheme.bodySmall?.copyWith(
            color: th.colorScheme.onSurfaceVariant,
          ),
        ),
      );
      children.add(const SizedBox(height: 12));
      children.add(
        _sectionCard(
          title: 'Tarmoqlar',
          icon: Icons.account_tree_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _onReorder,
                buildDefaultDragHandles: false,
                children: [
                  for (var i = 0; i < _branches.length; i++)
                    _buildBranchTile(context, i),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      children.add(
        _sectionCard(
          title: 'Ko‘rsatma va yakuniy tekshiruv',
          icon: Icons.menu_book_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _instructions,
                onChanged: (_) => setState(() {}),
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Umumiy ko‘rsatma (ixtiyoriy)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              if (!splitLayout) ...[
                const SizedBox(height: 16),
                Text(
                  'O‘quvchi grafigi (jonli)',
                  style: th.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, c) {
                    final h = math.min(
                      320.0,
                      math.max(220.0, MediaQuery.sizeOf(context).height * 0.32),
                    );
                    return _buildLivePreview(height: h);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }

    return children;
  }

  Widget _buildStickyBottomBar() {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottom > 0 ? 10 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: _wizardStep > 0
                        ? () => setState(() => _wizardStep--)
                        : null,
                    child: const Text('Oldingi'),
                  ),
                  const Spacer(),
                  if (_wizardStep < 2)
                    FilledButton.tonal(
                      onPressed: () => setState(() => _wizardStep++),
                      child: const Text('Keyingi'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _creatingAssignment ? null : _createAssignmentWithCode,
                      icon: _creatingAssignment
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_2, size: 20),
                      label: Text(
                        _creatingAssignment
                            ? 'Yaratilmoqda…'
                            : 'Kodli topshiriq (7 kun)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed:
                          _creatingAssignment ? null : _openMethodAssignmentsList,
                      icon: const Icon(Icons.assignment_outlined, size: 20),
                      label: const Text('Topshiriqlar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('Klaster yaratish'),
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
          title: const Text('Klaster yaratish'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: Text('Metod tanlanmagan')),
      );
    }
    final mq = MediaQuery.of(context);
    final split = mq.size.width >= _kSplitBreakpoint;
    const pad = 20.0;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        title: const Text('Klaster yaratish'),
        leading: const AppBarBackOrHomeLeading(),
        actions: const [AppProfileIcon()],
      ),
      floatingActionButton: _wizardStep == 1
          ? FloatingActionButton(
              onPressed: _addBranch,
              tooltip: 'Tarmoq qo‘shish',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _buildStickyBottomBar(),
      body: split
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      16,
                      pad,
                      16 + mq.padding.bottom,
                    ),
                    children: _buildWizardFormChildren(splitLayout: true),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 9,
                  child: _buildSplitPreviewPanel(),
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                pad,
                16,
                pad,
                110 + mq.padding.bottom,
              ),
              children: _buildWizardFormChildren(splitLayout: false),
            ),
    );
  }

  Widget _branchStatusIcon(
    _BranchEdit b,
    Color onSurfaceVariant,
  ) {
    if (b.isDistractor) {
      return const Icon(
        Icons.cancel,
        color: Color(0xFFC62828),
        size: 22,
      );
    }
    final e = b.expectedKeyword;
    if (e != null) {
      final t = b.controller.text.trim();
      if (t.isEmpty) {
        return Icon(
          Icons.pending,
          color: onSurfaceVariant,
          size: 22,
        );
      }
      final ok = clusterStringsMatchEtalon(t, e);
      return Icon(
        ok ? Icons.check_circle : Icons.error,
        color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        size: 22,
      );
    }
    return const Icon(
      Icons.check_circle,
      color: Color(0xFF2E7D32),
      size: 22,
    );
  }

  String? _branchFieldError(_BranchEdit b) {
    if (b.isDistractor || b.expectedKeyword == null) {
      return null;
    }
    final t = b.controller.text.trim();
    if (t.isEmpty) {
      return null;
    }
    if (clusterStringsMatchEtalon(t, b.expectedKeyword!)) {
      return null;
    }
    return "JSONdagi so‘z bilan mos emas (to'g'ri: yashil belgi).";
  }

  String _shortBranchLabel(String s, int maxChars) {
    final t = s.trim();
    if (t.isEmpty) {
      return '';
    }
    if (t.length <= maxChars) {
      return t;
    }
    return '${t.substring(0, maxChars)}…';
  }

  Widget _buildBranchTile(BuildContext context, int i) {
    final b = _branches[i];
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    final th = Theme.of(context);
    final raw = b.controller.text.trim();
    final expanded = _branchEditorExpanded.contains(b.id);
    final showField = expanded || raw.isEmpty;

    final colorBtn = PopupMenuButton<Color>(
      tooltip: 'Rang',
      child: Material(
        color: b.color.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(width: 36, height: 36),
      ),
      itemBuilder: (ctx) => [
        for (var pi = 0; pi < _kClusterPalette.length; pi++)
          PopupMenuItem(
            value: _kClusterPalette[pi],
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _kClusterPalette[pi],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Palitra ${pi + 1}'),
              ],
            ),
          ),
      ],
      onSelected: (c) {
        setState(() => b.color = c);
      },
    );

    final dragHandle = Tooltip(
      message: 'Tartibni o‘zgartirish uchun ushlab suring',
      child: ReorderableDragStartListener(
        index: i,
        child: Material(
          color: th.colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Icon(
              Icons.drag_indicator,
              color: th.colorScheme.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );

    return Card(
      key: ValueKey(b.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        child: showField
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: dragHandle,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 4),
                    child: _branchStatusIcon(b, variant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: b.controller,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '${i + 1}-tarmoq',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: _branchFieldError(b),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                  if (raw.isNotEmpty)
                    IconButton(
                      tooltip: 'Qisqa ko‘rinish',
                      onPressed: () => setState(
                        () => _branchEditorExpanded.remove(b.id),
                      ),
                      icon: const Icon(Icons.unfold_less),
                    ),
                  colorBtn,
                  IconButton(
                    onPressed: () {
                      setState(() => b.isDistractor = !b.isDistractor);
                    },
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Chalg‘ituvchi / to‘g‘ri',
                  ),
                  IconButton(
                    onPressed: _branches.length > 1 ? () => _removeAt(i) : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  dragHandle,
                  const SizedBox(width: 6),
                  _branchStatusIcon(b, variant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: b.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(
                          () => _branchEditorExpanded.add(b.id),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _shortBranchLabel(raw, 48),
                                  style: th.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '#${i + 1}',
                                style: th.textTheme.labelSmall?.copyWith(
                                  color: variant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tahrirlash',
                    onPressed: () => setState(
                      () => _branchEditorExpanded.add(b.id),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  colorBtn,
                  IconButton(
                    onPressed: () {
                      setState(() => b.isDistractor = !b.isDistractor);
                    },
                    icon: const Icon(Icons.swap_horiz),
                    tooltip: 'Chalg‘ituvchi / to‘g‘ri',
                  ),
                  IconButton(
                    onPressed: _branches.length > 1 ? () => _removeAt(i) : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
      ),
    );
  }
}
