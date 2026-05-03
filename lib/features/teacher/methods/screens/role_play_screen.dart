// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../router/method_route_args.dart';
import '../data/method_repository.dart';

/// Rolli o'yin — rollar va ssenariy matni (Firestore `config`).
class RolePlayScreen extends StatefulWidget {
  const RolePlayScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<RolePlayScreen> createState() => _RolePlayScreenState();
}

class _RolePlayScreenState extends State<RolePlayScreen> {
  final _roles = TextEditingController();
  final _scenario = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _roles.dispose();
    _scenario.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final a = widget.args;
    if (a?.methodId == null) {
      setState(() => _loading = false);
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
    _roles.text = c?['roles'] as String? ?? '';
    _scenario.text = c?['scenario'] as String? ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final a = widget.args;
    if (a?.methodId == null) return;
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
      base['roles'] = _roles.text.trim();
      base['scenario'] = _scenario.text.trim();
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.args?.methodId ?? '—';
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('Rolli o\'yin'),
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
          title: const Text('Rolli o\'yin'),
          leading: const AppBarBackOrHomeLeading(),
          actions: const [AppProfileIcon()],
        ),
        body: const Center(child: Text('Metod tanlanmagan')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: Text('Rolli o\'yin · $id'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Rollarni va vaziyat ssenariysini yozing. O\'quvchilar topshirig\'ida matn javob beradi.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _roles,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Rollar (masalan: direktor, mutaxassis, mijoz)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _scenario,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Vaziyat / ssenariy',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
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
