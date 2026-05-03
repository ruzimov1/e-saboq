import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/assignment_deadline_picker.dart';
import '../../../../core/utils/code_generator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../router/assignment_route_args.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../data/assignment_repository.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key, this.args});

  final AssignmentRouteArgs? args;

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _rubric = TextEditingController();
  final _teacherNotes = TextEditingController();
  bool _loading = false;
  bool _allowGroup = false;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose();
    _rubric.dispose();
    _teacherNotes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await pickAssignmentDeadline(
      context,
      initial: _deadline,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final a = widget.args;
    if (a == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marshrut parametrlari yo\'q')),
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
    setState(() => _loading = true);
    try {
      final id = const Uuid().v4();
      final code = generateAssignmentCode();
      await context.read<AssignmentRepository>().createAssignment(
            subjectId: a.subjectId,
            classId: a.classId,
            topicId: a.topicId,
            methodId: a.methodId,
            assignmentId: id,
            data: {
              'code': code,
              'title': _title.text.trim(),
              'deadline': Timestamp.fromDate(_deadline),
              'createdAt': FieldValue.serverTimestamp(),
              'teacherId': auth.user.id,
              if (_rubric.text.trim().isNotEmpty) 'rubric': _rubric.text.trim(),
              if (_teacherNotes.text.trim().isNotEmpty)
                'teacherNotes': _teacherNotes.text.trim(),
              'allowGroupSubmissions': _allowGroup,
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Topshiriq kodi: $code'),
            action: SnackBarAction(
              label: 'Nusxa',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kod buferga nusxalandi')),
                );
              },
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('Topshiriq yaratish'),
        actions: const [AppProfileIcon()],
      ),
      body: a == null
          ? const Center(child: Text('Marshrut noto\'g\'ri'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _title,
                      label: 'Sarlavha',
                      validator: (v) => validateRequired(v, 'Sarlavha'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Muddat (sana va vaqt)'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatAssignmentDeadlineDateTime(_deadline)),
                          const SizedBox(height: 4),
                          Text(
                            'Yaratilgan vaqt saqlanganda avtomatik yoziladi.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rubric,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText:
                            'Baholash mezonlari (o\'quvchiga ko\'rinadi, ixtiyoriy)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _teacherNotes,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText:
                            'Ichki eslatma (faqat sizga, o\'quvchi kod orqali ko\'rmaydi)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Guruh topshirig\'i (keyingi bosqich)'),
                      subtitle: const Text(
                        'Hozircha belgi; keyinroq bir nechta o\'quvchi.',
                      ),
                      value: _allowGroup,
                      onChanged: (v) => setState(() => _allowGroup = v),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'Saqlash va kod olish',
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
