// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// O‘qituvchi konfiguratsiyasi — o‘quvchiga faqat [text] + [color] (to‘g‘ri bog‘langanda)
/// va [isDistractor] (ichki tekshiruv).
class StudentClusterBranch {
  const StudentClusterBranch({
    required this.index,
    required this.text,
    required this.isDistractor,
    this.colorArgb32,
    this.isStudentAuthored = false,
  });

  final int index;
  final String text;
  final bool isDistractor;
  final int? colorArgb32;
  /// O‘quvchi matn orqali qo‘shgan tarmoq (o‘qituvchidan kelganlar bunday emas).
  final bool isStudentAuthored;
  Color? get color =>
      colorArgb32 == null ? null : Color(0xFF000000 | (colorArgb32! & 0x00FFFFFF));
}

/// Markazga qo‘yilgan va hali bankdagi tarmoqlar soniga qarab klaster kanvasining
/// minimal yon tomoni — [screenHeight] bo‘yicha qo‘shimcha «virtual» maydon (zoom/pan).
double _clusterMapMinSide({
  required double viewportShortest,
  required double screenHeight,
  required int placedCount,
  required int totalBranches,
}) {
  final p = placedCount.clamp(0, 40);
  final inBank = (totalBranches - p).clamp(0, 36);
  final raw = 304.0 + 46.0 * p + 4.0 * inBank;
  final fromGraph = raw.clamp(304.0, 960.0);
  // Butun oynaga nisbatan minimal maydon — tor ko‘rinish oynasida ham katta xarita.
  final fromScreen = (screenHeight * 0.36).clamp(280.0, 920.0);
  return math.max(viewportShortest, math.max(fromGraph, fromScreen));
}

/// Mobil: kichik markaz doirasi; [w] odatda klaster kanvas kengligi.
double _centerRingRadiusForContent(double w, {required bool isCompact}) {
  if (!isCompact) {
    return 102;
  }
  return (w * 0.25).clamp(52.0, 80.0);
}

/// Kichik ekran va ikki aylana rejimi uchun tarmoq radiusi (chizgilar bilan [Radial] mos).
class _RadialLayout {
  const _RadialLayout({
    required this.useDual,
    required this.rSingle,
    required this.rInner,
    required this.rOuter,
    required this.maxOutward,
  });

  final bool useDual;
  final double rSingle;
  final double rInner;
  final double rOuter;
  /// Markazdan yorliq atrofigacha taxminan — [InteractiveViewer] «sig‘dirish».
  final double maxOutward;

  static const double kGapFromRing = 22.0;
  static const double kCenterR = 102.0;

  static double _nodeR(int n) => 7.0 + math.min(4.0, n * 0.35);

  static _RadialLayout compute({
    required int n,
    required double w,
    required double h,
    required bool isCompact,
    double centerRing = kCenterR,
  }) {
    final m = math.min(w, h);
    if (n < 1) {
      return const _RadialLayout(
        useDual: false,
        rSingle: 0,
        rInner: 0,
        rOuter: 0,
        maxOutward: 140,
      );
    }
    final nr = _nodeR(n);
    final rNodeCenterMin = centerRing + kGapFromRing + nr + 2;
    final labelOff = 12.0 + nr + math.min(28.0, 5.0 * n);
    final wForR = isCompact ? w : m;
    if (isCompact && n > 6) {
      var r1 = (wForR * 0.25).clamp(rNodeCenterMin, m * 0.34);
      var r2 = (r1 * 1.35).clamp(r1 + 28.0, m * 0.40);
      if (r2 - r1 < 28) {
        r2 = r1 + 28;
      }
      r1 = r1.clamp(rNodeCenterMin, r2 - 20);
      final rMaxText = 52.0;
      final out = (r2 + labelOff + rMaxText).clamp(120.0, m * 0.5);
      return _RadialLayout(
        useDual: true,
        rSingle: 0,
        rInner: r1,
        rOuter: r2,
        maxOutward: out,
      );
    }
    var r = rNodeCenterMin + (n > 4 ? 8.0 * (n - 4).clamp(0, 6) : 0.0);
    final rMax = isCompact
        ? (wForR * 0.25).clamp(rNodeCenterMin + 2, m * 0.40)
        : (m * 0.46).clamp(rNodeCenterMin + 8, m * 0.5);
    r = r.clamp(rNodeCenterMin, rMax);
    final rMaxText = 52.0;
    return _RadialLayout(
      useDual: false,
      rSingle: r,
      rInner: 0,
      rOuter: 0,
      maxOutward: (r + labelOff + rMaxText).clamp(100.0, m * 0.52),
    );
  }
}

void _showClusterConnectionsSheet(
  BuildContext context, {
  required String centerLabel,
  required List<int> placedOrder,
  required List<StudentClusterBranch> branches,
}) {
  final th = Theme.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewPaddingOf(ctx).bottom;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.58;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Markazdagi tushuncha',
                  style: th.textTheme.labelMedium?.copyWith(
                    color: th.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  centerLabel,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: th.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ulangan tarmoqlar (${placedOrder.length})',
                  style: th.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (placedOrder.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Hozircha hech qanday tarmoq ulangan emas. '
                        'Terminni pastdan yuqoridagi o‘zag‘ga torting.',
                        textAlign: TextAlign.center,
                        style: th.textTheme.bodyMedium?.copyWith(
                          color: th.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: placedOrder.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (c, k) {
                        final i = placedOrder[k];
                        final b = i < branches.length ? branches[i] : null;
                        final text = b?.text ?? '—';
                        final ccol = b?.color ??
                            (b != null && b.isStudentAuthored
                                ? th.colorScheme.secondary
                                : th.colorScheme.tertiary);
                        return Material(
                          color: ccol.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: ccol.withValues(alpha: 0.45),
                              foregroundColor: th.colorScheme.onSurface,
                              child: Text(
                                '${k + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              text,
                              style: th.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: b != null && b.isStudentAuthored
                                ? Text(
                                    'O‘zingiz qo‘shgan termin',
                                    style: th.textTheme.labelSmall?.copyWith(
                                      color: th.colorScheme.secondary,
                                    ),
                                  )
                                : (b != null && b.isDistractor)
                                    ? Text(
                                        'Chalg‘ituvchi (bajarish shartiga kirmaydi)',
                                        style: th.textTheme.labelSmall?.copyWith(
                                          color: th.colorScheme.error,
                                        ),
                                      )
                                    : null,
                            trailing: Icon(
                              Icons.hub_outlined,
                              color: ccol,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Yopish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ClusterProgressStars extends StatelessWidget {
  const _ClusterProgressStars({
    required this.placed,
    required this.target,
    required this.theme,
    this.compact = false,
  });

  final int placed;
  final int target;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (target < 1) {
      return const SizedBox.shrink();
    }
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 3),
          Text(
            '$placed/$target',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 2),
          ...List.generate(
            target,
            (i) {
              final on = i < placed;
              return Padding(
                padding: const EdgeInsets.only(left: 1.5),
                child: Icon(
                  on ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16,
                  color: on
                      ? const Color(0xFFFFB300)
                      : theme.colorScheme.outline
                          .withValues(alpha: 0.45),
                ),
              );
            },
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "To'g'ri ulangan: $placed / $target",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            target,
            (i) {
              final on = i < placed;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  on ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 32,
                  color: on
                      ? const Color(0xFFFFB300)
                      : theme.colorScheme.outline
                          .withValues(alpha: 0.4),
                  shadows: on
                      ? const [
                          Shadow(
                            color: Color(0x40FFB300),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Drag & drop klaster: markaz, pastdagi terminar, progress, chalg‘ituvchida silkinish.
class ClusterStudentExperience extends StatefulWidget {
  const ClusterStudentExperience({
    super.key,
    required this.center,
    required this.branches,
    this.onComplete,
    /// Tor ekran: yulduzlar "Kod" yonida — dublikatni [solve_assignment_screen] olib tashlaydi.
    this.assignmentCode,
  });

  final String center;
  final List<StudentClusterBranch> branches;
  final VoidCallback? onComplete;
  final String? assignmentCode;

  @override
  State<ClusterStudentExperience> createState() =>
      ClusterStudentExperienceState();
}

class ClusterStudentExperienceState extends State<ClusterStudentExperience> {
  static const int _kMaxStudentBranches = 12;

  final TextEditingController _newBranchText = TextEditingController();

  /// O‘qituvchi + o‘quvchi qo‘shmalari; indeks 0..length-1.
  late final List<StudentClusterBranch> _allBranches;
  int _initialTeacherCount = 0;

  /// Hali markazga to‘g‘ri qo‘yilmagan indekslar (barcha — to‘g‘ri + chalg‘ituvchi).
  final Set<int> _available = {};
  final List<int> _placedOrder = <int>[];
  final List<int> _distractorAttempts = <int>[];
  int? _shaking;
  /// Sudralayotgan termin indeksi — markazda oldindan chiziq.
  int? _draggingIndex;
  /// Chalg‘ituvchi markazga tortilganda qisqa qizil yorug‘lik.
  bool _centerErrorFlash = false;
  List<int> _bankDisplayOrder = [];
  final Map<int, Offset> _scatter = {};

  int get _targetTeacherCorrect {
    if (_initialTeacherCount < 1) {
      return 0;
    }
    var n = 0;
    for (var i = 0; i < _initialTeacherCount; i++) {
      if (i < _allBranches.length && !_allBranches[i].isDistractor) {
        n++;
      }
    }
    return n < 1 ? 1 : n;
  }

  int get _placedTeacherCorrectCount {
    var n = 0;
    for (final i in _placedOrder) {
      if (i < _initialTeacherCount &&
          i < _allBranches.length &&
          !_allBranches[i].isDistractor) {
        n++;
      }
    }
    return n;
  }

  bool get isSessionComplete {
    final need = _targetTeacherCorrect;
    if (need < 1) {
      return false;
    }
    for (var i = 0; i < _initialTeacherCount; i++) {
      if (i >= _allBranches.length) {
        break;
      }
      if (_allBranches[i].isDistractor) {
        continue;
      }
      if (!_placedOrder.contains(i)) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _allBranches = [
      for (var i = 0; i < widget.branches.length; i++)
        StudentClusterBranch(
          index: i,
          text: widget.branches[i].text,
          isDistractor: widget.branches[i].isDistractor,
          colorArgb32: widget.branches[i].colorArgb32,
        ),
    ];
    _initialTeacherCount = widget.branches.length;
    for (var i = 0; i < _allBranches.length; i++) {
      _available.add(i);
    }
    _bankDisplayOrder = List<int>.generate(_allBranches.length, (i) => i)
      ..shuffle();
    final rnd = math.Random(42);
    for (var i = 0; i < _allBranches.length; i++) {
      _scatter[i] = Offset(
        (rnd.nextDouble() - 0.5) * 6,
        (rnd.nextDouble() - 0.5) * 5,
      );
    }
  }

  @override
  void dispose() {
    _newBranchText.dispose();
    super.dispose();
  }

  void _openAddTermSheet() {
    final th = Theme.of(context);
    final can = _allBranches
            .where((b) => b.isStudentAuthored)
            .length <
        _kMaxStudentBranches;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewPaddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'O‘z termininiz (ixtiyoriy)',
                style: th.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Markazdagi tushunchani to‘ldiruvchi qo‘shimcha tushuncha — u ham "
                'sudrab bog‘lanadi.',
                style: th.textTheme.bodySmall?.copyWith(
                  color: th.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newBranchText,
                maxLength: 72,
                maxLines: 1,
                autofocus: true,
                onSubmitted: (_) {
                  if (can) {
                    _addStudentBranch();
                    if (_newBranchText.text.isEmpty) {
                      Navigator.of(ctx).pop();
                    }
                  }
                },
                style: th.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Masalan: Android',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: !can
                    ? null
                    : () {
                        _addStudentBranch();
                        if (mounted) {
                          Navigator.of(ctx).pop();
                        }
                      },
                child: const Text("Qo‘shish va yopish"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addStudentBranch() {
    final raw = _newBranchText.text.trim();
    if (raw.isEmpty) {
      return;
    }
    if (raw.length > 72) {
      return;
    }
    final extra = _allBranches
        .where((b) => b.isStudentAuthored)
        .length;
    if (extra >= _kMaxStudentBranches) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O‘z tarmoqlaringizdan oshiq ($_kMaxStudentBranches) qo‘shib bo‘lmaydi',
            ),
          ),
        );
      }
      return;
    }
    setState(() {
      final i = _allBranches.length;
      _allBranches.add(
        StudentClusterBranch(
          index: i,
          text: raw,
          isDistractor: false,
          colorArgb32: null,
          isStudentAuthored: true,
        ),
      );
      _available.add(i);
      _bankDisplayOrder.add(i);
      _scatter[i] = Offset(
        (math.Random().nextDouble() - 0.5) * 6,
        (math.Random().nextDouble() - 0.5) * 5,
      );
      _newBranchText.clear();
    });
  }

  Map<String, dynamic> buildAnswerPayload() {
    final studentTerms = <Map<String, dynamic>>[];
    for (var i = _initialTeacherCount; i < _allBranches.length; i++) {
      studentTerms.add({
        'text': _allBranches[i].text,
        'placed': _placedOrder.contains(i),
      });
    }
    return {
      'kind': 'group_cluster',
      'placedOrder': List<int>.from(_placedOrder),
      'distractorAttempts': List<int>.from(_distractorAttempts),
      'studentAddedBranches': studentTerms,
      'text': _summaryLine(),
    };
  }

  String _summaryLine() {
    final parts = <String>[];
    for (final i in _placedOrder) {
      if (i >= 0 && i < _allBranches.length) {
        final t = _allBranches[i].text.trim();
        if (t.isNotEmpty) {
          parts.add(t);
        }
      }
    }
    if (parts.isEmpty) {
      return '';
    }
    return parts.join(' · ');
  }

  void _onAcceptToCenter(int index) {
    if (index < 0 || index >= _allBranches.length) {
      return;
    }
    if (!_available.contains(index)) {
      return;
    }
    final b = _allBranches[index];
    if (b.isDistractor) {
      if (!kIsWeb) {
        HapticFeedback.heavyImpact();
      }
      setState(() {
        _distractorAttempts.add(index);
        _shaking = index;
        _centerErrorFlash = true;
      });
      Future<void>.delayed(const Duration(milliseconds: 480), () {
        if (mounted) {
          setState(() {
            _shaking = null;
            _centerErrorFlash = false;
          });
        }
      });
    } else {
      if (!kIsWeb) {
        HapticFeedback.lightImpact();
      }
      setState(() {
        _available.remove(index);
        _placedOrder.add(index);
      });
      if (isSessionComplete) {
        widget.onComplete?.call();
        _showMapDialog();
      }
    }
  }

  void _showMapDialog() {
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Klaster tayyor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Barcha to‘g‘ri tarmoqlar ulandi. Quyida jamlangan xaritani '
                'takrorlashda foydalaning.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _ClusterMapPreview(
                  center: widget.center,
                  placedIndices: _placedOrder,
                  branches: _allBranches,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Yaxshi'),
            ),
          ],
        );
      },
    );
  }

  Widget _clusterZoomableForViewport(
    BuildContext context,
    BoxConstraints mapCons, {
    required String centerText,
    required bool isCompact,
  }) {
    final h = mapCons.maxHeight;
    final w = mapCons.maxWidth;
    final mapShortest = w < h ? w : h;
    final screenH = MediaQuery.sizeOf(context).height;
    var minSide = _clusterMapMinSide(
      viewportShortest: mapShortest,
      screenHeight: screenH,
      placedCount: _placedOrder.length,
      totalBranches: _allBranches.length,
    );
    if (isCompact) {
      // Kichik oynada virtual xitoni juda katta qilmaslik (surish mashaqqatini kamaytirish).
      minSide = math.min(minSide, mapShortest * 1.3);
    }
    final contentW = math.max(w, minSide);
    final contentH = math.max(h, minSide);
    final canAddTerm =
        _allBranches.where((b) => b.isStudentAuthored).length < _kMaxStudentBranches;
    return _ClusterZoomableMap(
      contentWidth: contentW,
      contentHeight: contentH,
      centerLabel: centerText,
      placedOrder: _placedOrder,
      branches: _allBranches,
      onDropIndex: _onAcceptToCenter,
      draggingIndex: _draggingIndex,
      centerErrorFlash: _centerErrorFlash,
      onAddTerm: canAddTerm ? _openAddTermSheet : null,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final centerText = widget.center.trim().isEmpty
        ? 'Mavzu'
        : widget.center.trim();
    final isCompact = MediaQuery.sizeOf(context).shortestSide < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        if (isCompact)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.assignmentCode != null)
                  Expanded(
                    child: Text(
                      'Kod: ${widget.assignmentCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: th.textTheme.bodySmall,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 4),
                _ClusterProgressStars(
                  placed: _placedTeacherCorrectCount,
                  target: _targetTeacherCorrect,
                  theme: th,
                  compact: true,
                ),
              ],
            ),
          )
        else ...[
          _ClusterProgressStars(
            placed: _placedTeacherCorrectCount,
            target: _targetTeacherCorrect,
            theme: th,
          ),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, cons) {
              if (isCompact) {
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
                            child: Text(
                              'Surish / masshtab / termin: pastki varaq',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: th.textTheme.labelSmall?.copyWith(
                                color: th.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, mapCons) {
                                return _clusterZoomableForViewport(
                                  context,
                                  mapCons,
                                  centerText: centerText,
                                  isCompact: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    DraggableScrollableSheet(
                      initialChildSize: 0.17,
                      minChildSize: 0.08,
                      maxChildSize: 0.44,
                      builder: (context, scrollController) {
                        return Material(
                          elevation: 10,
                          shadowColor:
                              th.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          color: th.colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.98),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 5),
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: th.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  6,
                                  10,
                                  2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.wysiwyg_outlined,
                                      size: 18,
                                      color: th.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Terminlar',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: th.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _BankArea(
                                  scrollController: scrollController,
                                  branches: _allBranches,
                                  available: _available,
                                  bankOrder: _bankDisplayOrder,
                                  scatter: _scatter,
                                  shaking: _shaking,
                                  draggingIndex: _draggingIndex,
                                  onDragIndexChanged: (i) => setState(
                                    () => _draggingIndex = i,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
              // Keng ekran (asosan veb)
              final bankH = (cons.maxHeight * 0.12).clamp(88.0, 150.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Terminlar',
                    style: th.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: bankH,
                    child: _BankArea(
                      branches: _allBranches,
                      available: _available,
                      bankOrder: _bankDisplayOrder,
                      scatter: _scatter,
                      shaking: _shaking,
                      draggingIndex: _draggingIndex,
                      onDragIndexChanged: (i) =>
                          setState(() => _draggingIndex = i),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Surish / masshtab: Ctrl+scroll yoki o‘ng yuqoridagi tugmalar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: th.textTheme.labelSmall?.copyWith(
                      color: th.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, mapCons) {
                        return _clusterZoomableForViewport(
                          context,
                          mapCons,
                          centerText: centerText,
                          isCompact: false,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClusterCenterArea extends StatelessWidget {
  const _ClusterCenterArea({
    required this.centerLabel,
    required this.placedOrder,
    required this.branches,
    required this.onDropIndex,
    this.draggingIndex,
    this.centerErrorFlash = false,
    this.onAddTerm,
    this.isCompact = false,
  });

  final String centerLabel;
  final List<int> placedOrder;
  final List<StudentClusterBranch> branches;
  final void Function(int) onDropIndex;
  final int? draggingIndex;
  final bool centerErrorFlash;
  final VoidCallback? onAddTerm;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            th.colorScheme.primaryContainer.withValues(alpha: 0.2),
            th.colorScheme.surfaceContainerLowest.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.45),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: th.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              final centerR =
                  _centerRingRadiusForContent(w, isCompact: isCompact);
              return ConstrainedBox(
                constraints: BoxConstraints.tightFor(
                  width: w,
                  height: h,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.1,
                            colors: [
                              th.colorScheme.primary.withValues(alpha: 0.12),
                              th.colorScheme.tertiary.withValues(alpha: 0.04),
                              th.colorScheme.surface.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _BlueprintGridPainter(
                            color: th.colorScheme.primary
                                .withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                    // Markaz — Stackda avval (pastki qatlam); tarmoq chiziqlari va
                    // yorliqlar keyin yuqorida chiziladi (Z-index).
                    Center(
                      child: DragTarget<String>(
                        onWillAccept: (_) => true,
                        onAccept: (s) {
                          final i = int.tryParse(s);
                          if (i != null) onDropIndex(i);
                        },
                        builder: (context, candidate, rejected) {
                          final drop = candidate.isNotEmpty;
                          final n = placedOrder.length;
                          return Tooltip(
                            message: n == 0
                                ? 'Tarmoqlarni shu doiraga torting. '
                                    'Bosilganda ro‘yxat ochiladi.'
                                : '$n ta tarmoq ulandi. Bosib to‘liq ro‘yxatni ko‘ring.',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _showClusterConnectionsSheet(
                                  context,
                                  centerLabel: centerLabel,
                                  placedOrder: placedOrder,
                                  branches: branches,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: centerR * 2,
                                height: centerR * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: th.colorScheme.primary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 32,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: th.colorScheme.tertiary
                                          .withValues(alpha: 0.38),
                                      blurRadius: 46,
                                      spreadRadius: -2,
                                    ),
                                    BoxShadow(
                                      color: th.colorScheme.primary
                                          .withValues(alpha: 0.22),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                    if (drop) ...[
                                      BoxShadow(
                                        color: th.colorScheme.tertiary
                                            .withValues(alpha: 0.75),
                                        blurRadius: 40,
                                        spreadRadius: 3,
                                      ),
                                      BoxShadow(
                                        color: th.colorScheme.tertiary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 60,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ],
                                ),
                                child: ClipOval(
                                    child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: drop ? 22 : 18,
                                      sigmaY: drop ? 22 : 18,
                                    ),
                                    child: Container(
                                      width: centerR * 2,
                                      height: centerR * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: drop ? 0.45 : 0.32,
                                            ),
                                            (drop
                                                    ? th.colorScheme
                                                        .tertiaryContainer
                                                    : th
                                                        .colorScheme
                                                        .primaryContainer)
                                                .withValues(
                                                alpha: drop ? 0.62 : 0.5,
                                              ),
                                            th.colorScheme.secondaryContainer
                                                .withValues(alpha: 0.35),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        border: Border.all(
                                          color: Color.lerp(
                                            Colors.white,
                                            th.colorScheme.primary,
                                            drop ? 0.35 : 0.2,
                                          )!,
                                          width: drop ? 3.0 : 2.2,
                                        ),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.fromLTRB(
                                                12,
                                                16,
                                                12,
                                                20,
                                              ),
                                              child: Text(
                                                centerLabel,
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: th.textTheme.titleSmall
                                                    ?.copyWith(
                                                  color: th
                                                      .colorScheme.onSurface
                                                      .withValues(alpha: 0.95),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                  height: 1.2,
                                                  shadows: [
                                                    Shadow(
                                                      color: th
                                                          .colorScheme
                                                          .surface
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (n > 0)
                                            Positioned(
                                              top: 5,
                                              right: 4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: th
                                                      .colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    99,
                                                  ),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                      alpha: 0.9,
                                                    ),
                                                    width: 1.2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: th
                                                          .colorScheme
                                                          .primary
                                                          .withValues(
                                                        alpha: 0.4,
                                                      ),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  '$n',
                                                  style: th
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                    color: th
                                                        .colorScheme
                                                        .onPrimary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13,
                                                    height: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _RadialLinksPainter(
                            placedOrder: placedOrder,
                            branches: branches,
                            theme: th,
                            centerRingRadius: centerR,
                            draggingIndex: draggingIndex,
                            isCompact: isCompact,
                          ),
                        ),
                      ),
                    ),
                    if (centerErrorFlash)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Animate(
                            effects: const [
                              FadeEffect(
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              ),
                            ],
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onAddTerm != null)
                      Positioned(
                        left: w / 2 + centerR + 2,
                        top: h / 2 - 22,
                        child: Material(
                          color: th.colorScheme.secondaryContainer
                              .withValues(alpha: 0.96),
                          elevation: 4,
                          shadowColor:
                              th.colorScheme.primary.withValues(alpha: 0.35),
                          shape: const CircleBorder(),
                          child: IconButton.filledTonal(
                            onPressed: onAddTerm,
                            style: IconButton.styleFrom(
                              backgroundColor: th
                                  .colorScheme.tertiaryContainer
                                  .withValues(alpha: 0.9),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 24),
                            tooltip: "Yangi termin (ochiladi)",
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Nuqtali / panjara — blueprint foni.
class _BlueprintGridPainter extends CustomPainter {
  const _BlueprintGridPainter({this.color = const Color(0xFF6750A4)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color.withValues(alpha: 0.1);
    const step = 20.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.7, dot);
      }
    }
    final line = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += step * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += step * 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintGridPainter old) =>
      old.color != color;
}

/// Klaster: surish (pan), pinchi/tyrek masshtab, tugmalar, vebda Ctrl+scroll.
class _ClusterZoomableMap extends StatefulWidget {
  const _ClusterZoomableMap({
    required this.contentWidth,
    required this.contentHeight,
    required this.centerLabel,
    required this.placedOrder,
    required this.branches,
    required this.onDropIndex,
    this.draggingIndex,
    this.centerErrorFlash = false,
    this.onAddTerm,
    this.isCompact = false,
  });

  final double contentWidth;
  final double contentHeight;
  final String centerLabel;
  final List<int> placedOrder;
  final List<StudentClusterBranch> branches;
  final void Function(int) onDropIndex;
  final int? draggingIndex;
  final bool centerErrorFlash;
  final VoidCallback? onAddTerm;
  final bool isCompact;

  @override
  State<_ClusterZoomableMap> createState() => _ClusterZoomableMapState();
}

class _ClusterZoomableMapState extends State<_ClusterZoomableMap> {
  final TransformationController _t = TransformationController();

  static const double _minScale = 0.22;
  static const double _maxScale = 4.2;

  @override
  void initState() {
    super.initState();
    if (widget.isCompact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitClusterToView();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ClusterZoomableMap old) {
    super.didUpdateWidget(old);
    if (widget.isCompact) {
      if (old.draggingIndex == null && widget.draggingIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _zoomOutSlightlyForDrag();
          }
        });
      } else if (old.draggingIndex != null && widget.draggingIndex == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fitClusterToView();
          }
        });
      }
      if (old.contentWidth != widget.contentWidth ||
          old.contentHeight != widget.contentHeight) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fitClusterToView();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _zoomOutSlightlyForDrag() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final m = _t.value.clone();
    var s = m.getMaxScaleOnAxis();
    if (s.isNaN || s <= 0) {
      s = 1;
    }
    const factor = 0.88;
    final newS = (s * factor).clamp(_minScale, _maxScale);
    if ((newS - s).abs() < 0.002) {
      return;
    }
    final ratio = newS / s;
    final ox = box.size.width / 2;
    final oy = box.size.height / 2;
    final t = Matrix4.identity()
      ..translate(ox, oy)
      ..scale(ratio, ratio, 1)
      ..translate(-ox, -oy);
    setState(() {
      _t.value = t * m;
    });
  }

  void _fitClusterToView() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final viewW = box.size.width;
    final viewH = box.size.height;
    final cw = widget.contentWidth;
    final ch = widget.contentHeight;
    final n = widget.placedOrder.length;
    final cr = _centerRingRadiusForContent(cw, isCompact: true);
    final lay = _RadialLayout.compute(
      n: n,
      w: cw,
      h: ch,
      isCompact: true,
      centerRing: cr,
    );
    final R = n < 1 ? 150.0 : lay.maxOutward;
    const margin = 28.0;
    final s = (math.min(viewW, viewH) - 2 * margin) / (2 * R);
    final clamped = s.clamp(_minScale, 1.15);
    final cx = cw / 2;
    final cy = ch / 2;
    final vx = viewW / 2;
    final vy = viewH / 2;
    setState(() {
      _t.value = Matrix4.identity()
        ..translate(vx, vy)
        ..scale(clamped, clamped)
        ..translate(-cx, -cy);
    });
  }

  void _scaleBy(double factor) {
    final m = _t.value;
    var s = m.getMaxScaleOnAxis();
    if (s.isNaN || s <= 0) {
      s = 1;
    }
    final next = (s * factor).clamp(_minScale, _maxScale);
    if ((next - s).abs() < 0.0001) {
      return;
    }
    final t = next / s;
    _t.value = m * Matrix4.diagonal3Values(t, t, 1);
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final canPinchWhileDrag = widget.isCompact;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        InteractiveViewer(
          transformationController: _t,
          minScale: _minScale,
          maxScale: _maxScale,
          // Mobil: bitta barmoq sudrish va ikki barmoq masshtab — bir vaqtda.
          trackpadScrollCausesScale: widget.draggingIndex == null,
          panEnabled: widget.draggingIndex == null,
          scaleEnabled: canPinchWhileDrag || widget.draggingIndex == null,
          boundaryMargin: EdgeInsets.all(widget.isCompact ? 160 : 100),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: widget.contentWidth,
            height: widget.contentHeight,
            child: _ClusterCenterArea(
              centerLabel: widget.centerLabel,
              placedOrder: widget.placedOrder,
              branches: widget.branches,
              onDropIndex: widget.onDropIndex,
              draggingIndex: widget.draggingIndex,
              centerErrorFlash: widget.centerErrorFlash,
              onAddTerm: widget.onAddTerm,
              isCompact: widget.isCompact,
            ),
          ),
        ),
        if (widget.isCompact &&
            widget.draggingIndex != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.32),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(12),
            color: th.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Uzoqlashtirish',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scaleBy(1 / 1.12),
                  icon: const Icon(Icons.zoom_out, size: 20),
                ),
                IconButton(
                  tooltip: 'Yaqinlashtirish',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scaleBy(1.12),
                  icon: const Icon(Icons.zoom_in, size: 20),
                ),
                IconButton(
                  tooltip: widget.isCompact
                      ? 'Barcha tarmoqlarni sig‘dirish'
                      : '100% (asl ko‘rinish)',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    if (widget.isCompact) {
                      _fitClusterToView();
                    } else {
                      setState(() {
                        _t.value = Matrix4.identity();
                      });
                    }
                  },
                  icon: Icon(
                    widget.isCompact ? Icons.center_focus_strong : Icons.fit_screen,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Path _clusterBezierPath(Offset a, Offset b, int bendSign) {
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;
  var nx = -dy;
  var ny = dx;
  final len = math.sqrt(nx * nx + ny * ny);
  if (len < 0.01) {
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
  }
  nx /= len;
  ny /= len;
  // Qisqa tarmoqlar: kamroq bukilish
  final bend = 20.0 * bendSign;
  final c1 = Offset(
    a.dx + dx * 0.32 + nx * bend * 0.45,
    a.dy + dy * 0.32 + ny * bend * 0.45,
  );
  final c2 = Offset(
    a.dx + dx * 0.68 + nx * bend * 0.3,
    a.dy + dy * 0.68 + ny * bend * 0.3,
  );
  return Path()
    ..moveTo(a.dx, a.dy)
    ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
}

class _RadialLinksPainter extends CustomPainter {
  _RadialLinksPainter({
    required this.placedOrder,
    required this.branches,
    required this.theme,
    this.centerRingRadius = 102,
    this.draggingIndex,
    this.isCompact = false,
  });

  final List<int> placedOrder;
  final List<StudentClusterBranch> branches;
  final ThemeData theme;
  final double centerRingRadius;
  final int? draggingIndex;
  /// Tor ekran: qisqaroq radius, 6+ tarmoq — ikki aylana.
  final bool isCompact;

  void _drawBezierConnection(
    Canvas canvas,
    Offset a,
    Offset b,
    Color c,
    int k,
  ) {
    final path = _clusterBezierPath(a, b, k % 2 == 0 ? 1 : -1);
    final glow = Paint()
      ..color = c.withValues(alpha: 0.22)
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, glow);
    final pLine = Paint()
      ..color = c
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, pLine);
  }

  void _paintDragTowardTermBank(
    Canvas canvas,
    double cx,
    double cy,
    double m,
  ) {
    if (draggingIndex == null) {
      return;
    }
    final a = Offset(cx, cy - centerRingRadius);
    final b = Offset(cx, cy - m * 0.3);
    final path = _clusterBezierPath(a, b, 1);
    final glow = Paint()
      ..color = theme.colorScheme.tertiary.withValues(alpha: 0.22)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, glow);
    final dash = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.42)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, dash);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final n = placedOrder.length;
    final m = math.min(size.width, size.height);
    if (n == 0) {
      _paintDragTowardTermBank(canvas, cx, cy, m);
      return;
    }
    final nodeR = 7.0 + math.min(4.0, n * 0.35);
    final layout = _RadialLayout.compute(
      n: n,
      w: size.width,
      h: size.height,
      isCompact: isCompact,
      centerRing: centerRingRadius,
    );
    final guide = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    if (layout.useDual) {
      canvas.drawCircle(Offset(cx, cy), layout.rInner, guide);
      canvas.drawCircle(Offset(cx, cy), layout.rOuter, guide);
    } else {
      canvas.drawCircle(Offset(cx, cy), layout.rSingle, guide);
    }
    final labelOff = 12.0 + nodeR + math.min(28.0, 5.0 * n);
    int n1 = 0;
    if (layout.useDual) {
      n1 = (n + 1) ~/ 2;
    }
    for (var k = 0; k < n; k++) {
      final double r;
      final int ringK;
      final int ringN;
      if (layout.useDual) {
        if (k < n1) {
          r = layout.rInner;
          ringK = k;
          ringN = n1;
        } else {
          r = layout.rOuter;
          ringK = k - n1;
          ringN = n - n1;
        }
      } else {
        r = layout.rSingle;
        ringK = k;
        ringN = n;
      }
      final t = ringN <= 0
          ? 0.0
          : (ringK / ringN * 2 * math.pi - math.pi / 2);
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      final i = placedOrder[k];
      final b = (i < branches.length) ? branches[i] : null;
      final col = b?.color ??
          (b != null && b.isStudentAuthored
              ? theme.colorScheme.secondary
              : theme.colorScheme.tertiary);
      final c = col;
      // Chiziq: markaz doira chevaridan tarmoq nuqtasigacha
      var vx = x - cx;
      var vy = y - cy;
      final len = math.sqrt(vx * vx + vy * vy);
      if (len < 1) {
        continue;
      }
      vx /= len;
      vy /= len;
      final x1 = cx + vx * centerRingRadius;
      final y1 = cy + vy * centerRingRadius;
      final x2 = x - vx * (nodeR + 4);
      final y2 = y - vy * (nodeR + 4);
      _drawBezierConnection(
        canvas,
        Offset(x1, y1),
        Offset(x2, y2),
        c,
        k,
      );
      if (b != null && b.text.isNotEmpty) {
        // Shisha uslubidagi kichik tugun (markazdan kichik).
        final nodeFill = Color.lerp(
          c,
          theme.colorScheme.surface,
          0.72,
        )!
            .withValues(alpha: 0.55);
        final glowNode = Paint()
          ..color = c.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x, y), nodeR + 3, glowNode);
        canvas.drawCircle(
          Offset(x, y),
          nodeR,
          Paint()..color = nodeFill,
        );
        canvas.drawCircle(
          Offset(x, y),
          nodeR,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.35,
        );
        canvas.drawCircle(
          Offset(x, y),
          nodeR,
          Paint()
            ..color = c.withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        // Matn — aylanadan tashqariga (markazga qaraganda tashqarida)
        final lx = x + vx * labelOff;
        final ly = y + vy * labelOff;
        _drawLabelPill(
          canvas,
          size,
          b.text,
          Offset(lx, ly),
          c,
          center: Offset(cx, cy),
          keepOutFromCenter: centerRingRadius + 8,
        );
      }
    }
    _paintDragTowardTermBank(canvas, cx, cy, m);
  }

  void _drawLabelPill(
    Canvas canvas,
    Size canvasSize,
    String raw,
    Offset anchor,
    Color accent, {
    Offset? center,
    double keepOutFromCenter = 0,
  }) {
    if (raw.isEmpty) {
      return;
    }
    final t = raw.length > 36 ? '${raw.substring(0, 34)}…' : raw;
    const padH = 8.0;
    const padV = 5.0;
    final maxTextW = (canvasSize.width * (isCompact ? 0.42 : 0.38))
        .clamp(72.0, isCompact ? 220.0 : 200.0);
    final style = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.94),
    );
    final tp = TextPainter(
      text: TextSpan(text: t, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: maxTextW);
    final w = (tp.width + padH * 2).clamp(40.0, maxTextW + padH * 2);
    final h = tp.height + padV * 2;
    var left = anchor.dx - w / 2;
    var top = anchor.dy - h / 2;
    final maxLeft = math.max(6.0, canvasSize.width - w - 6);
    final maxTop = math.max(6.0, canvasSize.height - h - 6);
    left = left.clamp(6.0, maxLeft);
    top = top.clamp(6.0, maxTop);
    // Yorliq markaz aylanasi ichida qolmasin — radian bo‘yicha tashqariga itering
    if (center != null && keepOutFromCenter > 0) {
      final c = center;
      var cx = left + w / 2;
      var cy = top + h / 2;
      final rdx = cx - c.dx;
      final rdy = cy - c.dy;
      var dist = math.sqrt(rdx * rdx + rdy * rdy);
      if (dist < 0.5) {
        dist = 0.5;
      }
      final need = keepOutFromCenter + math.max(w, h) * 0.35;
      if (dist < need) {
        final s = need / dist;
        cx = c.dx + rdx * s;
        cy = c.dy + rdy * s;
        left = cx - w / 2;
        top = cy - h / 2;
        left = left.clamp(6.0, maxLeft);
        top = top.clamp(6.0, maxTop);
      }
    }
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(12),
    );
    final sh = Rect.fromLTWH(left + 1, top + 2, w, h);
    final rsh = RRect.fromRectAndRadius(sh, const Radius.circular(12));
    canvas.drawRRect(
      rsh,
      Paint()
        ..color = theme.colorScheme.shadow.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    final glass = Color.lerp(
      theme.colorScheme.surface,
      const Color(0xFFFFFFFF),
      0.45,
    )!
        .withValues(alpha: 0.52);
    canvas.drawRRect(rrect, Paint()..color = glass);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    tp.paint(
      canvas,
      Offset(
        left + (w - tp.width) / 2,
        top + padV,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RadialLinksPainter oldDelegate) {
    // Ro‘yxat o‘z joyida o‘zgarsa, reference bir xil bo‘lib qolishi mumkin — mobil veb
    // farqi bo‘lmasin.
    return !listEquals(oldDelegate.placedOrder, placedOrder) ||
        oldDelegate.centerRingRadius != centerRingRadius ||
        oldDelegate.branches.length != branches.length ||
        oldDelegate.draggingIndex != draggingIndex ||
        oldDelegate.isCompact != isCompact;
  }
}

class _BankArea extends StatelessWidget {
  const _BankArea({
    required this.branches,
    required this.available,
    required this.bankOrder,
    required this.scatter,
    required this.shaking,
    this.draggingIndex,
    this.onDragIndexChanged,
    this.scrollController,
  });

  final List<StudentClusterBranch> branches;
  final Set<int> available;
  final List<int> bankOrder;
  final Map<int, Offset> scatter;
  final int? shaking;
  final int? draggingIndex;
  final ValueChanged<int?>? onDragIndexChanged;
  /// [DraggableScrollableSheet] ichida bitta scroll qatori.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final inBank = bankOrder
        .where((i) => i >= 0 && i < branches.length && available.contains(i))
        .toList();
    if (inBank.isEmpty) {
      return Center(
        child: Text(
          'Barcha tarmoqlar markazga ulandi',
          style: th.textTheme.bodySmall?.copyWith(
            color: th.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final inner = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: kIsWeb ? 0.3 : 0.5),
            th.colorScheme.surfaceContainerHighest
                .withValues(alpha: kIsWeb ? 0.38 : 0.55),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: th.colorScheme.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        // Mobil: suriladigan g‘ildirak = scroll bilan to‘qnashadi; LongPressDraggable
        // (pastda) uzoq bosib sudrashi mumkin, scroll esa oddiy barmoq tebranishi.
        primary: false,
        physics: draggingIndex != null
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: inBank.map((i) {
            final b = branches[i];
            return Transform.translate(
              offset: scatter[i] ?? Offset.zero,
              child: _DraggableBranchChip(
                key: ValueKey('bank_$i'),
                index: i,
                text: b.text,
                isStudentAuthored: b.isStudentAuthored,
                isShaking: shaking == i,
                onDragIndexChanged: onDragIndexChanged,
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: inner,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: inner,
    );
  }
}

class _DraggableBranchChip extends StatefulWidget {
  const _DraggableBranchChip({
    super.key,
    required this.index,
    required this.text,
    this.isStudentAuthored = false,
    this.isShaking = false,
    this.onDragIndexChanged,
  });

  final int index;
  final String text;
  final bool isStudentAuthored;
  final bool isShaking;
  final ValueChanged<int?>? onDragIndexChanged;

  @override
  State<_DraggableBranchChip> createState() => _DraggableBranchChipState();
}

class _DraggableBranchChipState extends State<_DraggableBranchChip> {
  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final data = '${widget.index}';
    final child = widget.isShaking
        ? _chip(th, 1.0, haptic: false)
            .animate()
            .shake(
              duration: 450.ms,
              hz: 4,
              rotation: 0.02,
              curve: Curves.easeInOut,
            )
        : _chip(th, 1.0, haptic: false);
    return _wrapDraggable(
      th,
      data: data,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        shadowColor: th.colorScheme.primary.withValues(alpha: 0.35),
        child: _chip(th, 1.05, haptic: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: _chip(th, 1.0, haptic: false),
      ),
      child: child,
    );
  }

  /// Veb: sichqoncha — darhol [Draggable]. Mobil: [SingleChildScrollView] emas
  /// balki barmoq sudrishi uchun [LongPressDraggable] (scroll bilan chalkashmaydi).
  Widget _wrapDraggable(
    ThemeData th, {
    required String data,
    required Widget feedback,
    required Widget childWhenDragging,
    required Widget child,
  }) {
    void onStart() {
      widget.onDragIndexChanged?.call(widget.index);
    }

    void onEnd() {
      widget.onDragIndexChanged?.call(null);
    }

    if (kIsWeb) {
      return Draggable<String>(
        data: data,
        maxSimultaneousDrags: 1,
        onDragStarted: onStart,
        onDragEnd: (_) => onEnd(),
        onDraggableCanceled: (Velocity? velocity, Offset? offset) => onEnd(),
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: child,
      );
    }
    return LongPressDraggable<String>(
      data: data,
      delay: const Duration(milliseconds: 300),
      hapticFeedbackOnStart: true,
      maxSimultaneousDrags: 1,
      onDragStarted: onStart,
      onDragEnd: (_) => onEnd(),
      onDraggableCanceled: (Velocity? velocity, Offset? offset) => onEnd(),
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }

  Widget _chip(ThemeData th, double scale, {required bool haptic}) {
    final accent = widget.isStudentAuthored
        ? th.colorScheme.secondary
        : th.colorScheme.primary;
    return Transform.scale(
      scale: scale,
      child: Material(
        color: Colors.transparent,
        elevation: haptic ? 10 : 2,
        shadowColor: th.colorScheme.shadow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.55),
                accent.withValues(alpha: 0.26),
                th.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ],
            ),
            border: Border.all(
              width: haptic ? 1.8 : 1.2,
              color: Color.lerp(
                Colors.white,
                accent,
                0.28,
              )!
                  .withValues(alpha: haptic ? 0.85 : 0.55),
            ),
            boxShadow: haptic
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: th.colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isStudentAuthored
                    ? Icons.person_pin_outlined
                    : Icons.drag_indicator,
                size: 20,
                color: accent.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  widget.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: th.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: th.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClusterMapPreview extends StatelessWidget {
  const _ClusterMapPreview({
    required this.center,
    required this.placedIndices,
    required this.branches,
  });

  final String center;
  final List<int> placedIndices;
  final List<StudentClusterBranch> branches;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPreviewPainter(
        center: center,
        placedIndices: placedIndices,
        branches: branches,
        theme: Theme.of(context),
      ),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  _MapPreviewPainter({
    required this.center,
    required this.placedIndices,
    required this.branches,
    required this.theme,
  });

  final String center;
  final List<int> placedIndices;
  final List<StudentClusterBranch> branches;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final n = placedIndices.length;
    final r = (math.min(size.width, size.height) * 0.36).clamp(48.0, 80.0);
    final cPaint = Paint()..color = theme.colorScheme.primaryContainer;
    canvas.drawCircle(Offset(cx, cy), 38, cPaint);
    _drawFitted(
      canvas,
      center,
      Rect.fromCenter(center: Offset(cx, cy), width: 68, height: 56),
      theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 11),
    );
    if (n == 0) return;
    for (var k = 0; k < n; k++) {
      final t = k / n * 2 * math.pi - math.pi / 2;
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      final i = placedIndices[k];
      final b = (i < branches.length) ? branches[i] : null;
      final col = b?.color ??
          (b != null && b.isStudentAuthored
              ? theme.colorScheme.secondary
              : theme.colorScheme.tertiary);
      final line = Paint()
        ..color = col.withValues(alpha: 0.55)
        ..strokeWidth = 1.8;
      canvas.drawLine(Offset(cx, cy), Offset(x, y), line);
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 56, height: 30),
        const Radius.circular(8),
      );
      final bg = Paint()..color = col.withValues(alpha: 0.2);
      canvas.drawRRect(rr, bg);
      canvas.drawRRect(
        rr,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      final text = b?.text ?? '';
      _drawFitted(
        canvas,
        text,
        Rect.fromCenter(center: Offset(x, y), width: 52, height: 24),
        theme.textTheme.labelSmall,
      );
    }
  }

  void _drawFitted(
    Canvas canvas,
    String text,
    Rect rect,
    TextStyle? style,
  ) {
    if (text.isEmpty) return;
    final t = text.length > 32 ? '${text.substring(0, 30)}…' : text;
    final tp = TextPainter(
      text: TextSpan(text: t, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: rect.width);
    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) {
    return oldDelegate.placedIndices != placedIndices;
  }
}
