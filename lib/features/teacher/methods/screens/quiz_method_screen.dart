// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../router/method_route_args.dart';
import '../data/method_repository.dart';

/// Quiz: vaqt limiti va aralashtirish sozlamalari (`config` ga yoziladi).
/// Savollar ro‘yxati topshiriq yaratishda mavzu bo‘yicha to‘planadi.
class QuizMethodScreen extends StatefulWidget {
  const QuizMethodScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  State<QuizMethodScreen> createState() => _QuizMethodScreenState();
}

class _QuizMethodScreenState extends State<QuizMethodScreen> {
  bool _loading = true;
  bool _saving = false;
  int _secondsPerQuestion = 25;
  bool _shuffle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
    if (m != null) {
      final sec = m.config?['quizSecondsPerQuestion'];
      if (sec is num) {
        _secondsPerQuestion = sec.toInt().clamp(5, 60);
      }
      _shuffle = m.config?['quizShuffle'] == true;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final a = widget.args;
    if (a?.methodId == null) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<MethodRepository>();
      final m = await repo.fetchMethod(
        subjectId: a!.subjectId,
        classId: a.classId,
        topicId: a.topicId,
        methodId: a.methodId!,
      );
      if (!mounted) return;
      final base = Map<String, dynamic>.from(m?.config ?? {});
      base['quizSecondsPerQuestion'] = _secondsPerQuestion.clamp(5, 60);
      base['quizShuffle'] = _shuffle;
      await repo.updateMethodConfig(
        subjectId: a.subjectId,
        classId: a.classId,
        topicId: a.topicId,
        methodId: a.methodId!,
        config: base,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sozlamalar saqlandi')),
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
    final classId = widget.args?.classId ?? '';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
          title: const Text('Test (Quiz)'),
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
          title: const Text('Test (Quiz)'),
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
        title: Text('Test (Quiz) · $id'),
        actions: const [AppProfileIcon()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(
            'Sinf: $classId · Quiz sozlamalari',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vaqt va aralashtirish bu yerda saqlanadi. Savollar «Topshiriqlar» '
            'sahifasida mavzu bo‘yicha bitta quizga yig‘iladi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'Har bir savol uchun vaqt: $_secondsPerQuestion s',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            min: 5,
            max: 60,
            divisions: 55,
            label: '$_secondsPerQuestion s',
            value: _secondsPerQuestion.toDouble().clamp(5, 60),
            onChanged: (v) {
              setState(() => _secondsPerQuestion = v.round().clamp(5, 60));
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aralashtirish (Shuffle)'),
            subtitle: Text(
              'Savollar tartibi va A–D variantlari har bir o‘quvchi uchun '
              'tasodifiy tartibda (ko‘chirib olishning oldini olish).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            value: _shuffle,
            onChanged: (v) => setState(() => _shuffle = v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: CustomButton(
            label: 'Sozlamalarni saqlash',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
    );
  }
}
