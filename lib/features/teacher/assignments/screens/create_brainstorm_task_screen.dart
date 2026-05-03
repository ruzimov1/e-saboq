// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assignments/brainstorm_create_payload.dart';
import '../../../../core/assignments/brainstorm_session_config.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../router/assignment_route_args.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../data/assignment_repository.dart';

/// Aqliy hujum: markaziy savol, vaqt, g‘oyalar chegarasi, anonimlik, keyin yaratish.
class CreateBrainstormTaskScreen extends StatefulWidget {
  const CreateBrainstormTaskScreen({super.key, required this.args});

  final CreateBrainstormTaskRouteArgs args;

  @override
  State<CreateBrainstormTaskScreen> createState() =>
      _CreateBrainstormTaskScreenState();
}

class _CreateBrainstormTaskScreenState extends State<CreateBrainstormTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _mainConcept = TextEditingController();
  int _durationMinutes = 3;
  int _minIdeas = 1;
  int _maxIdeas = 5;
  bool _isAnonymous = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.args;
    _title.text = CurriculumPresets.readyPresetRowTitle(
      methodId: a.methodId,
      classId: a.classId,
      subjectId: a.subjectId,
      topicId: a.topicId,
      taskNumber1Based: a.listIndex0 + 1,
    );
    var concept = a.template.subtitle?.trim() ?? '';
    if (a.subjectId == 'informatika' &&
        a.methodId == CurriculumPresets.brainstormId) {
      final j = InformatikaJsonPresets.brainstormJsonQuestionAt(
        classId: a.classId,
        topicLabel: CurriculumPresets.topicLabel(
          a.subjectId,
          a.classId,
          a.topicId,
        ),
        slotIndex0: a.listIndex0,
      );
      if (j != null && j.trim().isNotEmpty) {
        concept = j.trim();
      }
    }
    if (concept.isNotEmpty) {
      _mainConcept.text = concept;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _mainConcept.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_minIdeas > _maxIdeas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal g‘oyalar soni maksimaldan oshmasligi kerak'),
        ),
      );
      return;
    }
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessiya topilmadi')),
      );
      return;
    }
    final a = widget.args;
    setState(() => _saving = true);
    try {
      final session = BrainstormSessionConfig(
        durationMinutes: _durationMinutes,
        minIdeasPerStudent: _minIdeas,
        maxIdeasPerStudent: _maxIdeas,
        isAnonymous: _isAnonymous,
      );
      final built = buildBrainstormAssignmentData(
        teacherId: auth.user.id,
        subjectId: a.subjectId,
        classId: a.classId,
        topicId: a.topicId,
        methodId: a.methodId,
        template: a.template,
        listIndex0: a.listIndex0,
        rowTitle: _title.text,
        mainConcept: _mainConcept.text,
        session: session,
      );
      await context.read<AssignmentRepository>().createAssignment(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId,
            assignmentId: built.assignmentId,
            data: built.data,
          );
      if (mounted) {
        final code = built.data['code'] as String? ?? '—';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yaratildi. Kod: $code')),
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
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        title: const Text('Aqliy hujum · topshiriq'),
        leading: const AppBarBackOrHomeLeading(),
        actions: const [AppProfileIcon()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Asosiy tushuncha (markaziy savol), vaqt, g‘oyalar limiti. '
              'O‘quvchilar bitta fikr uchun bitta qator ishlatadi.',
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Topshiriq nomi',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            Text(
              'Asosiy tushuncha (savol)',
              style: t.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mainConcept,
              minLines: 4,
              maxLines: 10,
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Masalan: Kiberxavfsizlik nima? yoki Internetning foydali jihatlari',
                border: const OutlineInputBorder(),
                fillColor: t.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                filled: true,
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Asosiy tushunchani kiriting';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 22,
                  color: t.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yuborish uchun vaqt (daqiqa)',
                  style: t.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: t.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<int>(
                value: _durationMinutes,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: InputBorder.none,
                ),
                items: <DropdownMenuItem<int>>[
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Cheklanmagan (taymer yo‘q)'),
                  ),
                  ...[2, 3, 4, 5, 6, 7, 8, 9, 10].map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text('$m daqiqa'),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _durationMinutes = v);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.format_list_numbered_outlined,
                  size: 22,
                  color: t.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Har bir o‘quvchi: minimal / maksimal g‘oyalar',
                  style: t.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _countTile(
                    context,
                    label: 'Kamida',
                    value: _minIdeas,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => _minIdeas = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _countTile(
                    context,
                    label: 'Ko‘pi bilan',
                    value: _maxIdeas,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => _maxIdeas = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
              title: const Text('Sinfdoshlar oldida ismni yashirish'),
              subtitle: const Text(
                'O‘qituvchi moderatsiyada o‘quvchini aniqlay oladi',
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Hujumni boshlash',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _countTile(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: value > min
                      ? () => onChanged(value - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: value < max
                      ? () => onChanged(value + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
