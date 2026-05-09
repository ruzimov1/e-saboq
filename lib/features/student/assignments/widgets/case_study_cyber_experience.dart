// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/ai/gemini_method_coach.dart';
import '../../../../core/case_study/case_study_cyber_models.dart';

// ── Rang palitasi (minimal, uyg'un) ─────────────────────────────────────────
const _kAccent = Color(0xFF00BCD4);      // moviy-ko'k
const _kSuccess = Color(0xFF66BB6A);     // yashil
const _kWarning = Color(0xFFFFA726);     // sariq-to'q
const _kSurface = Color(0xFF0E1621);     // asosiy qora-ko'k fon
const _kCard = Color(0xFF152233);        // karta foni
const _kBorder = Color(0xFF1E3A5F);      // chegara
const _kTextPrimary = Color(0xFFE8F0FE); // asosiy matn
const _kTextMuted = Color(0xFF7B8EA8);   // ikkinchi darajali matn

/// Muammoli vaziyat «Problem Solving Hub» — o'quvchi uchun interaktiv tajriba.
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
  State<CaseStudyCyberExperience> createState() =>
      CaseStudyCyberExperienceState();
}

class CaseStudyCyberExperienceState extends State<CaseStudyCyberExperience> {
  final List<Map<String, dynamic>> _probeLog = [];
  final List<String> _toolDrops = [];
  final List<String> _aiStoryBranches = [];
  bool? _consequenceFlash;
  bool _aiBranchLoading = false;
  bool _reflectionAiBusy = false;
  String? _reflectionAiNote;
  bool _scenarioExpanded = false;

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
      buf.writeln('— Qarorlar —');
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
    buf.writeln('— Yozma tahlil —');
    buf.writeln(reflection.isEmpty ? '—' : reflection);
    return {
      'kind': 'case',
      'text': buf.toString(),
      'caseReflection': reflection,
      'caseProbes': List<Map<String, dynamic>>.from(
          _probeLog.map((e) => Map<String, dynamic>.from(e))),
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
    if (mounted) setState(() => _consequenceFlash = null);
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
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(o.reaction)),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            o.isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      ),
    );
    widget.onChanged();
    if (!o.isCorrect) unawaited(_maybeAiScenarioBranch(o));
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
        const SnackBar(content: Text('GEMINI_API_KEY .env faylida yo\'q')),
      );
      return;
    }
    final draft = widget.reflectionController.text.trim();
    if (draft.length < 12) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tahlil matnini biroz kengroq yozing')),
      );
      return;
    }
    setState(() => _reflectionAiBusy = true);
    try {
      final probes = _probeLog
          .map((p) =>
              '${p['label']} (${p['correct'] == true ? 'to\u2019g\u2019ri' : 'xato'})')
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

  // ── Kichik yordamchi widgetlar ────────────────────────────────────────────

  Widget _card({required Widget child, EdgeInsetsGeometry pad = const EdgeInsets.all(14)}) {
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }

  Widget _label(String text, {Color color = _kAccent, double size = 10.5}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: size,
        letterSpacing: 0.9,
      ),
    );
  }

  // ── 1. Alert Banner ───────────────────────────────────────────────────────
  Widget _alertBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: _kWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kWarning.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: _kWarning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.task.alertTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _kWarning,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
  }

  // ── 2. Scenario ───────────────────────────────────────────────────────────
  Widget _scenarioCard() {
    final scenario = widget.task.scenario.trim();
    if (scenario.isEmpty) return const SizedBox.shrink();
    final isLong = scenario.length > 280;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 16, color: _kAccent),
              const SizedBox(width: 6),
              _label('VAZIYAT TAVSIFI'),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: (_scenarioExpanded || !isLong)
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Text(
              scenario,
              style: const TextStyle(
                color: _kTextPrimary,
                height: 1.55,
                fontSize: 14,
              ),
            ),
            secondChild: Text(
              scenario,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kTextPrimary,
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _scenarioExpanded = !_scenarioExpanded),
              child: Text(
                _scenarioExpanded ? 'Yig\'ish ▲' : 'To\'liq o\'qish ▼',
                style: const TextStyle(
                  color: _kAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 3. Dialogue bubbles ───────────────────────────────────────────────────
  Widget _dialogueBubbles(List<CaseDialogueLine> lines) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_outlined, size: 16, color: _kAccent),
            const SizedBox(width: 6),
            _label('SUHBAT / HODISA'),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < lines.length; i++)
          _bubble(lines[i], index: i),
      ],
    );
  }

  Widget _bubble(CaseDialogueLine line, {required int index}) {
    final isRight = line.role == 'client' || line.role == 'user';
    final accent = isRight
        ? _kAccent.withValues(alpha: 0.75)
        : _kWarning.withValues(alpha: 0.65);
    final bubbleColor = isRight
        ? _kAccent.withValues(alpha: 0.10)
        : const Color(0xFF1E2D3D);
    final speaker = _speakerTitle(line.role);
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 6),
                index == 1
                    ? _TypewriterText(
                        text: line.text,
                        style: const TextStyle(
                          color: _kTextPrimary,
                          height: 1.45,
                          fontSize: 13.5,
                        ),
                      )
                    : Text(
                        line.text,
                        style: const TextStyle(
                          color: _kTextPrimary,
                          height: 1.45,
                          fontSize: 13.5,
                        ),
                      )
                            .animate()
                            .fadeIn(duration: 380.ms, delay: (60 * index).ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _speakerTitle(String role) {
    switch (role) {
      case 'admin':
        return 'IT ADMIN';
      case 'system':
        return 'TIZIM';
      case 'client':
        return 'FOYDALANUVCHI';
      case 'user':
        return 'SIZ';
      default:
        return 'OPERATOR';
    }
  }

  // ── 4. Progress ───────────────────────────────────────────────────────────
  Widget _progressBar() {
    final lines = widget.task.resolvedDialogue();
    final total = (lines.length.clamp(2, 6) + 3);
    final current = (1 + _probeLog.length).clamp(0, total);
    return _card(
      pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 16, color: _kAccent),
              const SizedBox(width: 6),
              _label('MUAMMONI HAL QILISH YO\u2018LI'),
              const Spacer(),
              Text(
                '$current / $total qadam',
                style: const TextStyle(
                  color: _kTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 6,
              backgroundColor: Colors.black38,
              color: _kSuccess.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Harakat kartalari ──────────────────────────────────────────────────
  Widget _decisionSection() {
    if (!widget.task.hasInteractive) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_outlined, size: 16, color: _kWarning),
            const SizedBox(width: 6),
            _label('HARAKAT TANLANG', color: _kWarning),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Muammoni hal qilish uchun eng to\'g\'ri chora-tadbirni tanlang',
          style: TextStyle(color: _kTextMuted, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 10),
        for (final o in widget.task.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CyberActionCard(label: o.label, onTap: () => _pick(o)),
          ),
      ],
    );
  }

  // ── 6. AI voqea rivojlanishi ──────────────────────────────────────────────
  Widget _aiStorySection() {
    if (_aiStoryBranches.isEmpty && !_aiBranchLoading) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: _kSuccess),
            const SizedBox(width: 6),
            _label('AI SSENARIST · VOQEA RIVOJLANDI', color: _kSuccess),
          ],
        ),
        const SizedBox(height: 8),
        if (_aiBranchLoading)
          const LinearProgressIndicator(minHeight: 3),
        for (final s in _aiStoryBranches)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: _card(
              child: Text(
                s,
                style: const TextStyle(
                  color: _kTextPrimary,
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── 7. Asboblar qutisi ────────────────────────────────────────────────────
  Widget _toolboxSection() {
    if (!widget.task.hasInteractive) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build_outlined, size: 16, color: _kAccent),
              const SizedBox(width: 6),
              _label('ASBOBLAR QUTISI'),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Asbobni sudrab pastdagi zonaga tashlang',
            style: TextStyle(color: _kTextMuted, fontSize: 12),
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
                  child: _ToolChip(label: t, dragging: true),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: _ToolChip(label: t)),
                child: _ToolChip(label: t),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          DragTarget<String>(
            onAcceptWithDetails: (d) {
              setState(() {
                if (!_toolDrops.contains(d.data)) _toolDrops.add(d.data);
              });
              widget.onChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('«${d.data}» operativ reja zonasiga qo\u2019shildi'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            builder: (ctx, candidate, _) {
              final hover = candidate.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hover
                        ? _kSuccess.withValues(alpha: 0.7)
                        : _kBorder.withValues(alpha: 0.8),
                    width: hover ? 2 : 1,
                  ),
                  color: hover
                      ? _kSuccess.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _toolDrops.isEmpty
                      ? 'Operativ reja zonasi — asbobni bu yerga tashlang'
                      : _toolDrops.join(' · '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _toolDrops.isEmpty
                        ? _kTextMuted
                        : _kTextPrimary,
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

  // ── 8. Ta'sir o'lchagich ──────────────────────────────────────────────────
  Widget _impactSection() {
    if (_probeLog.isEmpty) return const SizedBox.shrink();
    final ok = _probeLog.where((p) => p['correct'] == true).length;
    final total = _probeLog.length;
    final safety = ok / total;
    final eff = (0.55 + 0.45 * safety - (1 - safety) * 0.15).clamp(0.0, 1.0);

    String advice;
    if (safety >= 0.75) {
      advice = 'Mantiqiy va xavfsizlikni ustun qo\u2019ygan yo\u2019l tutdingiz. Yakuniy tahlilda qoidalar va ishonchli manbalarni alohida qayd eting.';
    } else if (safety >= 0.4) {
      advice = 'Qisman to\u2019g\u2019ri taktika — lekin ayrim qadamlar xavfni oshirishi mumkin. Zaxira nusxa va rasmiy kanallarni tekshirishni unutmang.';
    } else {
      advice = 'Bu vaziyatda shoshilinch tanlov va yashirish muammoni kattalashtiradi. Qayta tahlil qilib, xavfsiz yo\u2019lni tanlang.';
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_outlined, size: 16, color: _kSuccess),
              const SizedBox(width: 6),
              _label('TAHLIL · TA\u02bcSIR', color: _kSuccess),
            ],
          ),
          const SizedBox(height: 12),
          _meterRow('Xavfsizlik', safety, _kSuccess),
          const SizedBox(height: 10),
          _meterRow('Samaradorlik', eff, _kAccent),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: _kWarning.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  advice,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meterRow(String label, double v, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: _kTextMuted, fontSize: 12)),
            Text(
              '${(v * 100).round()}%',
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 6,
            backgroundColor: Colors.black38,
            color: c.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  // ── 9. Qarorlar jurnali ───────────────────────────────────────────────────
  Widget _probeLogSection() {
    if (_probeLog.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_outlined, size: 16, color: _kTextMuted),
              const SizedBox(width: 6),
              _label('QARORLAR JURNALI', color: _kTextMuted),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in _probeLog)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    p['correct'] == true
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 16,
                    color: p['correct'] == true ? _kSuccess : Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${p['label']}',
                      style: const TextStyle(
                        color: _kTextPrimary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 10. Terminal (tahlil maydoni) ─────────────────────────────────────────
  Widget _terminalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.terminal, size: 16, color: _kSuccess),
            const SizedBox(width: 6),
            _label('YOZMA TAHLIL / JAVOB', color: _kSuccess),
            const Spacer(),
            TextButton.icon(
              onPressed: _reflectionAiBusy ? null : _runReflectionCoach,
              style: TextButton.styleFrom(
                foregroundColor: _kSuccess,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: _reflectionAiBusy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kSuccess,
                      ),
                    )
                  : const Icon(Icons.psychology_outlined, size: 16),
              label: const Text('AI maslahat', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        if (_reflectionAiNote != null &&
            _reflectionAiNote!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('AI · INDIVIDUAL TAHLIL',
                    color: _kWarning.withValues(alpha: 0.9)),
                const SizedBox(height: 8),
                SelectableText(
                  _reflectionAiNote!,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050806),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _kSuccess.withValues(alpha: 0.35),
            ),
          ),
          child: TextField(
            controller: widget.reflectionController,
            onChanged: (_) => widget.onChanged(),
            minLines: 4,
            maxLines: 10,
            style: TextStyle(
              fontFamily: 'monospace',
              color: _kSuccess.withValues(alpha: 0.92),
              height: 1.5,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText:
                  '> tahlil, xavflar, aniq qadamlar va asoslantirish...',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                color: _kSuccess.withValues(alpha: 0.28),
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lines = widget.task.resolvedDialogue();

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _kAccent,
          brightness: Brightness.dark,
          surface: _kSurface,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fon
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1628), _kSurface],
              ),
            ),
          ),
          // Konten
          if (_consequenceFlash != null)
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.28, end: 0),
                  duration: const Duration(milliseconds: 500),
                  builder: (ctx, v, _) => Container(
                    color: (_consequenceFlash == true
                            ? Colors.greenAccent
                            : Colors.redAccent)
                        .withValues(alpha: v),
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
              children: [
                // Sarlavha qatori
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.hub_outlined,
                          color: _kAccent, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'MUAMMOLARNI HAL QILISH MARKAZI',
                          style: TextStyle(
                            color: _kAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _kSuccess.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 7, color: _kSuccess),
                            SizedBox(width: 4),
                            Text(
                              'FAOL',
                              style: TextStyle(
                                color: _kSuccess,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 1. Alert
                _alertBanner(),
                const SizedBox(height: 10),

                // 2. Progress
                _progressBar(),
                const SizedBox(height: 10),

                // 3. Vaziyat matni
                _scenarioCard(),
                const SizedBox(height: 10),

                // 4. Dialogue
                if (lines.isNotEmpty) ...[
                  _dialogueBubbles(lines),
                  const SizedBox(height: 10),
                ],

                // 5. Harakat kartalari
                _decisionSection(),
                const SizedBox(height: 10),

                // 6. Asboblar
                if (widget.task.hasInteractive) ...[
                  _toolboxSection(),
                  const SizedBox(height: 10),
                ],

                // 7. AI voqea
                _aiStorySection(),
                if (_aiStoryBranches.isNotEmpty)
                  const SizedBox(height: 10),

                // 8. Qarorlar jurnali
                _probeLogSection(),
                if (_probeLog.isNotEmpty) const SizedBox(height: 10),

                // 9. Ta'sir o'lchagich
                _impactSection(),
                if (_probeLog.isNotEmpty) const SizedBox(height: 10),

                // 10. Terminal
                _terminalSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Harakar kartasi ───────────────────────────────────────────────────────────
class _CyberActionCard extends StatefulWidget {
  const _CyberActionCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_CyberActionCard> createState() => _CyberActionCardState();
}

class _CyberActionCardState extends State<_CyberActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _pressed
              ? _kAccent.withValues(alpha: 0.18)
              : _kCard,
          border: Border.all(
            color: _pressed
                ? _kAccent.withValues(alpha: 0.8)
                : _kBorder,
            width: _pressed ? 1.5 : 1,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: _kAccent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.bolt_outlined,
              size: 20,
              color: _kAccent.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: _kTextPrimary,
                  fontSize: 13.5,
                ),
              ),
            ),
            const Icon(
              Icons.touch_app_outlined,
              color: _kTextMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Asbob chipi ───────────────────────────────────────────────────────────────
class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.label, this.dragging = false});

  final String label;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dragging
            ? _kAccent.withValues(alpha: 0.25)
            : _kBorder.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_outlined,
              size: 16, color: _kAccent.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: _kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typewriter animatsiyasi ───────────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  const _TypewriterText({required this.text, required this.style});

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
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
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
    return Text(
      shown + (_i < widget.text.length ? '▍' : ''),
      style: widget.style,
    );
  }
}
