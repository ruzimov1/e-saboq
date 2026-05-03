// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../router/app_router.dart';
import '../../../../router/method_route_args.dart';
import '../data/method_repository.dart';

/// Muammoli vaziyat — ssenario matni.
class CaseStudyScreen extends StatefulWidget {
  const CaseStudyScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<CaseStudyScreen> createState() => _CaseStudyScreenState();
}

class _CaseStudyScreenState extends State<CaseStudyScreen> {
  final _scenario = TextEditingController();
  final _caseSolutionPath = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scenario.dispose();
    _caseSolutionPath.dispose();
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
    _scenario.text = m?.config?['scenario'] as String? ?? '';
    _caseSolutionPath.text = m?.config?['caseSolutionPath'] as String? ?? '';
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
      base['scenario'] = _scenario.text.trim();
      base['caseSolutionPath'] = _caseSolutionPath.text.trim();
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
          title: const Text('Muammoli vaziyat'),
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
          title: const Text('Muammoli vaziyat'),
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
        title: Text('Muammoli vaziyat · $id'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Vaziyatlar masalasi: haqiqiy kontekst, muammo va talablar. '
            'O\'quvchi tahlil va yechimni matn bilan yuboradi.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _scenario,
            minLines: 8,
            maxLines: 20,
            decoration: const InputDecoration(
              labelText: 'Vaziyat matni (case)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caseSolutionPath,
            minLines: 3,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Yechim kaliti / kutilgan ketma-ketlik (o‘qituvchi uchun)',
              hintText: 'Masalan: havolani ochmaslik → rasmiy sayt orqali tekshirish → …',
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final a = widget.args;
              if (a == null || a.methodId == null || a.methodId!.isEmpty) {
                return;
              }
              context.push(AppRoutes.teacherCaseDashboard, extra: a);
            },
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: const Text('Boshqaruv paneli: monitoring va tahlil'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final a = widget.args;
              if (a == null || a.methodId == null || a.methodId!.isEmpty) {
                return;
              }
              final mid = a.methodId!;
              context.push(
                '/teacher/classes/${a.classId}/subjects/${a.subjectId}/topics/${a.topicId}/methods/$mid/assignments-list',
              );
            },
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Topshiriqlar va o‘quvchi javoblari'),
          ),
        ],
      ),
    );
  }
}
