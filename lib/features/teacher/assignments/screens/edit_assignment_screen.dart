// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/assignments/brainstorm_session_config.dart';
import '../../../../core/utils/assignment_deadline_picker.dart';
import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../router/assignment_route_args.dart';
import '../data/assignment_repository.dart';

/// Yaratilgan topshiriqni tahrirlash. Informatika · Aqliy hujum: JSON savoli `embeddedMethodConfig`da.
class EditAssignmentScreen extends StatefulWidget {
  const EditAssignmentScreen({super.key, required this.args});

  final AssignmentRouteArgs args;

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _prompt = TextEditingController();
  DateTime? _deadline;
  DateTime? _createdAt;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _raw;
  int _bsDuration = 3;
  final _bsMin = TextEditingController();
  final _bsMax = TextEditingController();
  bool _bsAnonymous = false;

  bool get _isBrainstorm =>
      widget.args.methodId == CurriculumPresets.brainstormId;

  @override
  void dispose() {
    _title.dispose();
    _prompt.dispose();
    _bsMin.dispose();
    _bsMax.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final aid = widget.args.assignmentId;
    if (aid == null || aid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Topshiriq identifikatori yo‘q';
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final raw = await context.read<AssignmentRepository>().getAssignmentDataRaw(
            subjectId: widget.args.subjectId,
            classId: widget.args.classId,
            topicId: widget.args.topicId,
            methodId: widget.args.methodId,
            assignmentId: aid,
          );
      if (!mounted) {
        return;
      }
      if (raw == null) {
        setState(() {
          _loading = false;
          _error = 'Topshiriq topilmadi';
        });
        return;
      }
      _raw = raw;
      _title.text = (raw['title'] as String? ?? '').trim();
      final dl = raw['deadline'];
      if (dl is Timestamp) {
        _deadline = dl.toDate();
      } else {
        _deadline = DateTime.now().add(const Duration(days: 7));
      }
      final cr = raw['createdAt'];
      if (cr is Timestamp) {
        _createdAt = cr.toDate();
      } else {
        _createdAt = null;
      }
      if (_isBrainstorm) {
        final emb = raw['embeddedMethodConfig'] as Map<String, dynamic>?;
        if (emb != null) {
          _prompt.text = (emb['prompt'] as String? ?? '').trim();
        }
        final bs = BrainstormSessionConfig.fromAssignmentData(raw);
        _bsDuration = bs.durationMinutes;
        _bsMin.text = '${bs.minIdeasPerStudent}';
        _bsMax.text = '${bs.maxIdeasPerStudent}';
        _bsAnonymous = bs.isAnonymous;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final d = _deadline ?? DateTime.now();
    final start = DateTime.now().subtract(const Duration(days: 1));
    final end = DateTime.now().add(const Duration(days: 365 * 2));
    final picked = await pickAssignmentDeadline(
      context,
      initial: d,
      firstDate: start,
      lastDate: end,
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _save() async {
    final aid = widget.args.assignmentId;
    if (aid == null || aid.isEmpty) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final t = _title.text.trim();
    final deadline = _deadline;
    if (deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Muddatni tanlang')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final raw = _raw;
      if (raw == null) {
        if (mounted) {
          setState(() => _saving = false);
        }
        return;
      }
      final patch = <String, dynamic>{
        'title': t,
        'deadline': Timestamp.fromDate(deadline),
      };

      if (_isBrainstorm) {
        final emb = Map<String, dynamic>.from(
          raw['embeddedMethodConfig'] as Map<dynamic, dynamic>? ?? {},
        );
        emb['prompt'] = _prompt.text.trim();
        patch['embeddedMethodConfig'] = emb;
        if (raw['fromInfJsonPreset'] == true) {
          patch['fromInfJsonPreset'] = true;
        }
        final minI = int.tryParse(_bsMin.text) ?? 1;
        var maxI = int.tryParse(_bsMax.text) ?? minI;
        if (maxI < minI) {
          maxI = minI;
        }
        patch['brainstormSession'] = BrainstormSessionConfig(
          durationMinutes: _bsDuration,
          minIdeasPerStudent: minI.clamp(1, 30),
          maxIdeasPerStudent: maxI.clamp(1, 30),
          isAnonymous: _bsAnonymous,
        ).toFirestoreMap();
      }

      await context.read<AssignmentRepository>().updateAssignment(
            subjectId: widget.args.subjectId,
            classId: widget.args.classId,
            topicId: widget.args.topicId,
            methodId: widget.args.methodId,
            assignmentId: aid,
            data: patch,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saqlandi')),
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('Topshiriqni tahrirlash'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('Topshiriqni tahrirlash'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        title: const Text('Topshiriqni tahrirlash'),
        leading: const AppBarBackOrHomeLeading(),
        actions: const [AppProfileIcon()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_isBrainstorm)
              Text(
                'Aqliy hujum: savol va sessiya (vaqt, g‘oyalar limiti) shu '
                'topshirig‘ga tegishli.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            if (_isBrainstorm) const SizedBox(height: 16),
            CustomTextField(
              controller: _title,
              label: 'Sarlavha',
              validator: (v) => validateRequired(v, 'Sarlavha'),
            ),
            const SizedBox(height: 16),
            if (_createdAt != null) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Yaratilgan'),
                subtitle: Text(formatAssignmentDeadlineDateTime(_createdAt!)),
                leading: const Icon(Icons.schedule),
              ),
              const SizedBox(height: 12),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Muddat (sana va vaqt)'),
              subtitle: Text(
                _deadline == null
                    ? '—'
                    : formatAssignmentDeadlineDateTime(_deadline!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            if (_isBrainstorm) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _prompt,
                minLines: 4,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Savol (o‘quvchiga)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Savolni kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _bsDuration,
                decoration: const InputDecoration(
                  labelText: 'Taymer (daqiqa, 0 = cheksiz)',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<int>>[
                  const DropdownMenuItem(value: 0, child: Text('Cheksiz (0)')),
                  ...[2, 3, 4, 5, 6, 7, 8, 9, 10].map(
                    (m) => DropdownMenuItem(value: m, child: Text('$m')),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _bsDuration = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bsMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kamida g‘oya',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bsMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ko‘pi bilan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _bsAnonymous,
                onChanged: (v) => setState(() => _bsAnonymous = v),
                title: const Text('Sinfdoshlar oldida anonim'),
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              label: 'Saqlash',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
