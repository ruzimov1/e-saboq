// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/ai/gemini_method_coach.dart';
import '../../../../core/case_study/case_study_cyber_models.dart';

const _kDarkCyan = Color(0xFF00E5FF);
const _kNeonGreen = Color(0xFF39FF14);
const _kPanel = Color(0xFF0D1520);
const _kLine = Color(0xFF1E3A5F);

/// Muammoli vaziyat «Problem Solving Hub»: hikoya, glassmorphism, qaror kartalari, DnD asboblar, tahlil.
class CaseStudyCyberExperience extends StatefulWidget {
  const CaseStudyCyberExperience({
    super.key,
    required this.task,
    required this.reflectionController,
    required this.onChanged,
  });

  final CaseCyberTask task;
  final TextEditingController reflectionController;
  final VoidCallback onChanged;

  @override
  State<CaseStudyCyberExperience> createState() => CaseStudyCyberExperienceState();
}

class CaseStudyCyberExperienceState extends State<CaseStudyCyberExperience> {
  final List<Map<String, dynamic>> _probeLog = [];
  final List<String> _toolDrops = [];
  final List<String> _aiStoryBranches = [];
  bool? _consequenceFlash;
  bool _aiBranchLoading = false;
  bool _reflectionAiBusy = false;
  String? _reflectionAiNote;

  static const _darkCyan = _kDarkCyan;
  static const _neonGreen = _kNeonGreen;
  static const _panel = _kPanel;
  static const _line = _kLine;

  static const _toolbox = [
    'Antivirus',
    'Firewall',
    'Zaxira nusxa',
    'Parol siyosati',
    'Tarmoqni izolyatsiya',
  ];

  Map<String, dynamic> buildAnswerPayload() {
    final reflection = widget.reflectionController.text.trim();
    final buf = StringBuffer();
    if (_probeLog.isNotEmpty) {
      buf.writeln('— Taassurof tanlovlari —');
      for (final p in _probeLog) {
        buf.writeln('• ${p['label']} → ${p['reaction']}');
      }
      buf.writeln();
    }
    if (_toolDrops.isNotEmpty) {
      buf.writeln('— Tanlangan asboblar —');
      for (final t in _toolDrops) {
        buf.writeln('• $t');
      }
      buf.writeln();
    }
    buf.writeln('— Yozma yechim / tahlil —');
    buf.writeln(reflection.isEmpty ? '—' : reflection);
    return {
      'kind': 'case',
      'text': buf.toString(),
      'caseReflection': reflection,
      'caseProbes': List<Map<String, dynamic>>.from(
        _probeLog.map((e) => Map<String, dynamic>.from(e)),
      ),
      if (_toolDrops.isNotEmpty)
        'caseToolDrops': _toolDrops.map((t) => {'tool': t}).toList(),
      if (_aiStoryBranches.isNotEmpty)
        'caseAiStoryBranches': List<String>.from(_aiStoryBranches),
      if (_reflectionAiNote != null && _reflectionAiNote!.trim().isNotEmpty)
        'caseAiReflectionCoach': _reflectionAiNote!.trim(),
      'caseAlert': widget.task.alertTitle,
      'caseScenario': widget.task.scenario,
    };
  }

  Future<void> _flashConsequence(bool positive) async {
    setState(() => _consequenceFlash = positive);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted) {
      setState(() => _consequenceFlash = null);
    }
  }

  Future<void> _pick(CaseCyberOption o) async {
    setState(() {
      _probeLog.add({
        'label': o.label,
        'correct': o.isCorrect,
        'reaction': o.reaction,
      });
    });
    await _flashConsequence(o.isCorrect);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              o.isCorrect ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(o.reaction)),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: o.isCorrect ? Colors.green.shade800 : Colors.red.shade900,
      ),
    );
    widget.onChanged();
    if (!o.isCorrect) {
      unawaited(_maybeAiScenarioBranch(o));
    }
  }

  Future<void> _maybeAiScenarioBranch(CaseCyberOption o) async {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) return;
    setState(() => _aiBranchLoading = true);
    try {
      final prior = _probeLog.map((p) => '${p['label']}').join(' → ');
      final text = await GeminiMethodCoach.caseStudyDynamicBranch(
        apiKey: key,
        scenarioSummary: widget.task.scenario,
        chosenAction: o.label,
        systemReaction: o.reaction,
        priorContext: prior,
      );
      if (!mounted) return;
      setState(() {
        _aiStoryBranches.add(text);
        _aiBranchLoading = false;
      });
      widget.onChanged();
    } catch (_) {
      if (mounted) setState(() => _aiBranchLoading = false);
    }
  }

  Future<void> _runReflectionCoach() async {
    final key = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GEMINI_API_KEY .env faylida yo‘q'),
        ),
      );
      return;
    }
    final draft = widget.reflectionController.text.trim();
    if (draft.length < 12) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tahlil matnini biroz kengroq yozing'),
        ),
      );
      return;
    }
    setState(() => _reflectionAiBusy = true);
    try {
      final probes = _probeLog
          .map((p) => '${p['label']} (${p['correct'] == true ? 'to‘g‘ri' : 'xato'})')
          .join('; ');
      final note = await GeminiMethodCoach.caseStudyReflectionCoach(
        apiKey: key,
        scenarioSummary: '${widget.task.alertTitle}\n${widget.task.scenario}',
        reflectionDraft: draft,
        probesSummary: probes.isEmpty ? null : probes,
      );
      if (!mounted) return;
      setState(() {
        _reflectionAiNote = note;
        _reflectionAiBusy = false;
      });
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() => _reflectionAiBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _aiSsenaristBubble(String paragraph) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: _neonGreen.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Text(
                  'AI SSENARIST · keyingi voqea',
                  style: TextStyle(
                    color: _neonGreen.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              paragraph,
              style: TextStyle(
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CaseScene _sceneForBlob(String blob) {
    final b = blob.toLowerCase();
    if (b.contains('pocht') || b.contains('email') || b.contains('xat') || b.contains('gmail')) {
      return _CaseScene.email;
    }
    if (b.contains('protsessor') ||
        b.contains('hardware') ||
        b.contains('qurilma') ||
        b.contains('matx') ||
        b.contains('kompyuter')) {
      return _CaseScene.hardware;
    }
    if (b.contains('tarmoq') || b.contains('internet') || b.contains('wifi') || b.contains('dns')) {
      return _CaseScene.network;
    }
    return _CaseScene.generic;
  }

  LinearGradient _gradientFor(_CaseScene s) {
    switch (s) {
      case _CaseScene.email:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF152238), Color(0xFF0D1B2A)],
        );
      case _CaseScene.hardware:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080A0C), Color(0xFF121920), Color(0xFF1A1510)],
        );
      case _CaseScene.network:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050810), Color(0xFF0C1829), Color(0xFF061016)],
        );
      case _CaseScene.generic:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF070B12), Color(0xFF121A28)],
        );
    }
  }

  String _speakerTitle(String role) {
    switch (role) {
      case 'admin':
        return 'TIZIM ADMINI';
      case 'system':
        return 'TIZIM';
      case 'client':
        return 'MIJOZ';
      case 'user':
        return 'FOYDALANUVCHI';
      default:
        return 'OPERATOR';
    }
  }

  Alignment _bubbleAlign(String role) {
    if (role == 'client' || role == 'user') {
      return Alignment.centerRight;
    }
    return Alignment.centerLeft;
  }

  Color _bubbleAccent(String role) {
    if (role == 'client' || role == 'user') {
      return _darkCyan.withValues(alpha: 0.65);
    }
    return Colors.orangeAccent.withValues(alpha: 0.55);
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry pad = const EdgeInsets.all(14)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Padding(padding: pad, child: child),
        ),
      ),
    );
  }

  Widget _sceneWatermark(_CaseScene scene) {
    IconData icon;
    switch (scene) {
      case _CaseScene.email:
        icon = Icons.mark_email_unread_outlined;
        break;
      case _CaseScene.hardware:
        icon = Icons.memory_outlined;
        break;
      case _CaseScene.network:
        icon = Icons.hub_outlined;
        break;
      case _CaseScene.generic:
        icon = Icons.shield_outlined;
        break;
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 220,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
    );
  }

  Widget _faintGrid() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GridPainter(color: _darkCyan.withValues(alpha: 0.07)),
        ),
      ),
    );
  }

  Widget _progressTrack() {
    final lines = widget.task.resolvedDialogue();
    final baseSteps = lines.isEmpty ? 1 : lines.length.clamp(2, 6);
    final decisionCount = _probeLog.length;
    final total = baseSteps + 3;
    final current = (1 + decisionCount).clamp(0, total);

    return _glassCard(
      pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, size: 18, color: _darkCyan.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Text(
                'MUAMMONI HAL QILISH YO‘LI',
                style: TextStyle(
                  color: _darkCyan.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.35),
              color: _neonGreen.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Holat: tahlil bosqichi · qarorlar: $decisionCount',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _chatSection(List<CaseDialogueLine> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          Align(
            alignment: _bubbleAlign(lines[i].role),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              size: 18, color: _bubbleAccent(lines[i].role)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _speakerTitle(lines[i].role),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.6,
                                color: _bubbleAccent(lines[i].role),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (ctx) {
                          final longSingle = lines.length == 1 && lines[i].text.length > 100;
                          final useTw = (lines.length > 1 && i == 1) || longSingle;
                          if (useTw) {
                            return _TypewriterText(
                              text: lines[i].text,
                              style: TextStyle(
                                height: 1.35,
                                fontSize: 14.5,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            );
                          }
                          return Text(
                            lines[i].text,
                            style: TextStyle(
                              height: 1.35,
                              fontSize: 14.5,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 450.ms, delay: (60 * i).ms)
                              .slideY(begin: 0.06, end: 0);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _decisionCard(CaseCyberOption o) {
    return _CyberActionCard(
      label: o.label,
      onTap: () => _pick(o),
    );
  }

  String _debriefAdvice() {
    if (_probeLog.isEmpty) {
      return 'Harakat variantlarini tanlab, keyin o‘z tahlilingizni terminalga yozing.';
    }
    final ok = _probeLog.where((p) => p['correct'] == true).length;
    final total = _probeLog.length;
    final ratio = ok / total;
    if (ratio >= 0.75) {
      return 'Siz mantiqiy va xavfsizlikni ustun qo‘ygan yo‘l tutdingiz. Yakuniy tahlilda qoidalar va ishonchli manbalarni alohida qayd eting.';
    }
    if (ratio >= 0.4) {
      return 'Qisman to‘g‘ri taktika — lekin ayrim qadamlar xavfni oshirishi mumkin. Zaxira nusxa va rasmiy kanallarni tekshirishni unutmang.';
    }
    return 'Bu vaziyatda shoshilinch tanlov va yashirish odatda muammoni kattalashtiradi. Qayta tahlil qilib, xavfsiz yo‘lni tanlang.';
  }

  Widget _impactMeter() {
    if (_probeLog.isEmpty) {
      return const SizedBox.shrink();
    }
    final ok = _probeLog.where((p) => p['correct'] == true).length;
    final total = _probeLog.length;
    final safety = ok / total;
    final eff = 0.55 + 0.45 * safety - (1 - safety) * 0.15;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAHLIL · TA’SIR',
            style: TextStyle(
              color: _neonGreen.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _meterRow('Xavfsizlik', safety, Colors.greenAccent.shade200),
          const SizedBox(height: 10),
          _meterRow('Samaradorlik', eff.clamp(0.0, 1.0), _darkCyan),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.psychology_outlined, size: 20, color: Colors.amber.shade200),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _debriefAdvice(),
                  style: TextStyle(
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Aqlli maslahat: o‘qituvchi va AI tahlili topshiriq yuborilgach ham mavjud bo‘lishi mumkin.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meterRow(String label, double v, Color c) {
    final pct = (v * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            Text(
              '${pct > 0 ? '+' : ''}$pct% rel.',
              style: TextStyle(color: c.withValues(alpha: 0.95), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            color: c.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _toolboxDnD() {
    if (!widget.task.hasInteractive) {
      return const SizedBox.shrink();
    }
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASBOBLAR QUTISI · sudrab muammo zonasiga torting',
            style: TextStyle(
              color: _darkCyan.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _toolbox.map((t) {
              return Draggable<String>(
                data: t,
                feedback: Material(
                  color: Colors.transparent,
                  child: _toolChip(t, dragging: true),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: _toolChip(t)),
                child: _toolChip(t),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          DragTarget<String>(
            onAcceptWithDetails: (d) {
              setState(() {
                if (!_toolDrops.contains(d.data)) {
                  _toolDrops.add(d.data);
                }
              });
              widget.onChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('«${d.data}» operativ reja zonasiga qo‘shildi'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            builder: (ctx, candidate, _) {
              final hover = candidate.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hover ? _neonGreen.withValues(alpha: 0.7) : Colors.white24,
                    width: hover ? 2 : 1,
                  ),
                  color: hover ? _neonGreen.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.25),
                ),
                alignment: Alignment.center,
                child: Text(
                  _toolDrops.isEmpty
                      ? 'Muammo hal zonasi — asbobni bu yerga torting'
                      : _toolDrops.join(' · '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: _toolDrops.isEmpty ? 0.35 : 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _toolChip(String t, {bool dragging = false}) {
    return Material(
      color: _line.withValues(alpha: dragging ? 0.75 : 0.55),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_circle_outlined, size: 18, color: _darkCyan.withValues(alpha: 0.85)),
            const SizedBox(width: 6),
            Text(
              t,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _terminalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'TERMINAL · JAVOB / TAHLIL',
                style: TextStyle(
                  color: _neonGreen.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.85,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _reflectionAiBusy ? null : _runReflectionCoach,
              icon: _reflectionAiBusy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _neonGreen.withValues(alpha: 0.8),
                      ),
                    )
                  : Icon(Icons.psychology_outlined, size: 18, color: _neonGreen.withValues(alpha: 0.85)),
              label: Text(
                'AI maslahat',
                style: TextStyle(color: _neonGreen.withValues(alpha: 0.9)),
              ),
            ),
          ],
        ),
        if (_reflectionAiNote != null && _reflectionAiNote!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI · INDIVIDUAL TAHLIL',
                  style: TextStyle(
                    color: Colors.amber.shade200,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _reflectionAiNote!,
                  style: TextStyle(
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: widget.reflectionController,
          onChanged: (_) => widget.onChanged(),
          minLines: 4,
          maxLines: 10,
          style: TextStyle(
            fontFamily: 'monospace',
            color: _neonGreen.withValues(alpha: 0.92),
            height: 1.45,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: '> tahlil, xavflar, aniq qadamlar va asoslantirish...',
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              color: _neonGreen.withValues(alpha: 0.25),
            ),
            filled: true,
            fillColor: const Color(0xFF050806),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1A4D2E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _neonGreen.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _neonGreen.withValues(alpha: 0.85), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final blob = '${widget.task.scenario} ${widget.task.alertTitle}'.toLowerCase();
    final scene = _sceneForBlob(blob);
    final lines = widget.task.resolvedDialogue();

    final dark = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkCyan,
        brightness: Brightness.dark,
        surface: _panel,
      ),
    );

    return Theme(
      data: dark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: _gradientFor(scene))),
          _faintGrid(),
          _sceneWatermark(scene),
          if (_consequenceFlash != null)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.32, end: 0),
                  duration: const Duration(milliseconds: 500),
                  builder: (ctx, v, _) {
                    final pos = _consequenceFlash == true;
                    return Container(
                      color: (pos ? Colors.greenAccent : Colors.redAccent).withValues(alpha: v),
                    );
                  },
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Icon(Icons.hub_outlined, color: _darkCyan.withValues(alpha: 0.9), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'MUAMMOLARNI HAL QILISH MARKAZI',
                        style: TextStyle(
                          color: _darkCyan.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.05,
                          fontSize: 11.5,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.circle, size: 9, color: Colors.greenAccent.withValues(alpha: 0.85)),
                      const SizedBox(width: 6),
                      Text(
                        'SESSIYA: FAOL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _progressTrack(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      _chatSection(lines),
                      if (_aiBranchLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      for (final s in _aiStoryBranches) _aiSsenaristBubble(s),
                      if (widget.task.hasInteractive) ...[
                        const SizedBox(height: 8),
                        Text(
                          'HARAKAT KARTALARI',
                          style: TextStyle(
                            color: _darkCyan.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final o in widget.task.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _decisionCard(o),
                          ),
                        const SizedBox(height: 6),
                        _toolboxDnD(),
                      ],
                      if (_probeLog.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _impactMeter(),
                      ],
                      const SizedBox(height: 18),
                      _terminalField(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CaseScene { email, hardware, network, generic }

class _CyberActionCard extends StatefulWidget {
  const _CyberActionCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_CyberActionCard> createState() => _CyberActionCardState();
}

class _CyberActionCardState extends State<_CyberActionCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    const cyan = _kDarkCyan;
    const line = _kLine;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: line.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: cyan.withValues(alpha: _scale < 1 ? 0.35 : 0.12),
                blurRadius: _scale < 1 ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.bolt_outlined, size: 22, color: cyan.withValues(alpha: 0.85)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(Icons.touch_app_outlined, color: Colors.white.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  const _TypewriterText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  Timer? _timer;
  var _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 22), (_) {
      if (_i >= widget.text.length) {
        _timer?.cancel();
        return;
      }
      setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _i.clamp(0, widget.text.length));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            shown + (_i < widget.text.length ? '▍' : ''),
            style: widget.style,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.color != color;
}
