// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/curriculum/curriculum_presets.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../router/method_route_args.dart';
import '../data/method_repository.dart';

/// Aqliy hujum — boshvog\'och prompti.
class BrainstormScreen extends StatefulWidget {
  /// Dasturiy tayyor metoddagi default matn — JSONdagi 1-savol bilan almashtirish uchun.
  static const String kDefaultPresetMethodPrompt =
      "Mavzu bo'yicha barcha g'oyalarni yozing (tanqid qilmasdan). Keyin eng yaxshi 3 tasini tanlang.";

  const BrainstormScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<BrainstormScreen> createState() => _BrainstormScreenState();
}

class _BrainstormScreenState extends State<BrainstormScreen> {
  final _prompt = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _prompt.dispose();
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
    var p = m?.config?['prompt'] as String? ?? '';
    if (a.subjectId == 'informatika' &&
        a.methodId == CurriculumPresets.brainstormId) {
      final fromJson0 = InformatikaJsonPresets.brainstormJsonQuestionAt(
        classId: a.classId,
        topicLabel: CurriculumPresets.topicLabel(
          a.subjectId,
          a.classId,
          a.topicId,
        ),
        slotIndex0: 0,
      );
      final t = p.trim();
      final looksDefault =
          t.isEmpty || t == BrainstormScreen.kDefaultPresetMethodPrompt;
      if (looksDefault && fromJson0 != null && fromJson0.isNotEmpty) {
        p = fromJson0;
      }
    }
    _prompt.text = p;
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
      base['prompt'] = _prompt.text.trim();
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
          title: const Text('Aqliy hujum'),
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
          title: const Text('Aqliy hujum'),
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
        title: Text('Aqliy hujum · $id'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'O\'quvchilarga beriladigan savol yoki yo\'riqnoma (boshvog\'och / aqliy hujum).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (widget.args?.methodId == CurriculumPresets.brainstormId &&
              widget.args?.subjectId == 'informatika') ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Eslatma: «Tayyor savollar bazasi» yoki yakka topshiriqda '
                  'fayl (aqliy-hujum JSON) orqali alohida savol biriktiriladi; '
                  'o‘quvchi o‘sha savolni ko‘radi. Ushbu maydon ixtiyoriy umumiy '
                  'matn; to‘ldirmasangiz yoki yangi vazifada alohida savol '
                  'bo‘lmasa, dastur JSON bo‘yicha avtomatik qo‘llaydi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _prompt,
            minLines: 6,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Prompt / savol',
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
