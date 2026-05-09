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

/// Muammoli vaziyat — ssenario matni (o'qituvchi tomonidan tahrirlash).
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
  bool _solutionExpanded = false;

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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Saqlandi'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('Muammoli vaziyat'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Sarlavha kartasi ──────────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            color: cs.primaryContainer.withValues(alpha: 0.55),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primary.withValues(alpha: 0.15),
                    radius: 22,
                    child: Icon(Icons.cases_outlined, color: cs.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muammoli vaziyat (Case Study)',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Haqiqiy kontekst va muammoni yozing. O\'quvchi tahlil va yechimni '
                          'interaktiv tarzda topshiradi.',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID: $id',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Vaziyat matni ─────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.description_outlined,
            label: 'Vaziyat matni',
            subtitle: 'O\'quvchi duch keladigan muammo yoki hodisani batafsil yozing',
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _scenario,
                minLines: 7,
                maxLines: 22,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
                decoration: InputDecoration(
                  hintText:
                      'Masalan:\n«Maktab kompyuterida antivirusni yangilash kerak degan xabar paydo bo\'ldi. '
                      'Havolani bosing yoki rasmiy saytga kiring...»',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.all(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Ko'rsatma chip
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TipChip(icon: Icons.warning_amber_outlined, label: 'Muammo/xavf mavjud bo\'lsin'),
              _TipChip(icon: Icons.psychology_outlined, label: 'Tahlil talab etsin'),
              _TipChip(icon: Icons.business_center_outlined, label: 'Haqiqiy kontekst'),
            ],
          ),
          const SizedBox(height: 20),

          // ── Yechim kaliti ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _solutionExpanded = !_solutionExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.key_outlined,
                  size: 18,
                  color: cs.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yechim kaliti / Kutilgan ketma-ketlik',
                    style: tt.titleSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _solutionExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (!_solutionExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2, bottom: 4),
              child: Text(
                'Faqat o\'qituvchi uchun — o\'quvchiga ko\'rsatilmaydi',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _solutionExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Card(
                margin: EdgeInsets.zero,
                color: cs.secondaryContainer.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16, color: cs.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'Faqat o\'qituvchi uchun',
                            style: tt.labelSmall?.copyWith(
                              color: cs.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _caseSolutionPath,
                        minLines: 3,
                        maxLines: 10,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                        decoration: InputDecoration(
                          hintText:
                              'Masalan: havolani bosmaslik → rasmiy sayt orqali tekshirish → IT bo\'limiga xabar berish',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.all(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox(height: 4),
          ),
          const SizedBox(height: 24),

          // ── Saqlash ───────────────────────────────────────────────────────
          CustomButton(
            label: 'Saqlash',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 16),

          // ── Boshqaruv / monitoring ────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.analytics_outlined,
            label: 'Monitoring va tahlil',
            subtitle: 'O\'quvchi javoblari va statistikani ko\'ring',
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.dashboard_customize_outlined,
                  iconColor: cs.primary,
                  title: 'Boshqaruv paneli',
                  subtitle: 'Monitoring va tahlil',
                  onTap: () {
                    final a = widget.args;
                    if (a == null || a.methodId == null || a.methodId!.isEmpty) return;
                    context.push(AppRoutes.teacherCaseDashboard, extra: a);
                  },
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                _ActionTile(
                  icon: Icons.assignment_outlined,
                  iconColor: cs.secondary,
                  title: 'Topshiriqlar va javoblar',
                  subtitle: 'O\'quvchilarning yuborishlari',
                  onTap: () {
                    final a = widget.args;
                    if (a == null || a.methodId == null || a.methodId!.isEmpty) return;
                    final mid = a.methodId!;
                    context.push(
                      '/teacher/classes/${a.classId}/subjects/${a.subjectId}'
                      '/topics/${a.topicId}/methods/$mid/assignments-list',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        radius: 20,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
