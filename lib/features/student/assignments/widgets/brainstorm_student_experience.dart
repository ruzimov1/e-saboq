// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/student_display_name.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../teacher/assignments/data/assignment_lookup.dart';
import '../data/submission_repository.dart';

import '../../../../core/assignments/brainstorm_session_config.dart';

/// O‘quvchi matni: APK / och fonlarda ham o‘qish oson bo‘lsin.
const Color _kStudentBodyText = Color(0xFF1A1A1A);
const Color _kStudentSecondaryText = Color(0xFF37474F);
/// Aqliy hujum: doska, yaltirash savol, burchakdagi taymer, stikerlar, like, slotlar.
class BrainstormStudentExperience extends StatefulWidget {
  const BrainstormStudentExperience({
    super.key,
    required this.lookup,
    required this.config,
    required this.mainPrompt,
    this.guide,
    this.assignmentCode,
    required this.rubric,
    this.secondsLeft,
    required this.timeExpired,
    required this.formatMmSs,
    required this.blockSession,
    required this.loggedIn,
    required this.myIdeas,
    required this.ideaInput,
    required this.onAddIdea,
    required this.onFinalSubmit,
    required this.isSubmitting,
  });

  final AssignmentLookup lookup;
  final BrainstormSessionConfig config;
  final String mainPrompt;
  final String? guide;
  final String? assignmentCode;
  final String rubric;
  final int? secondsLeft;
  final bool timeExpired;
  final String Function(int? sec) formatMmSs;
  final bool blockSession;
  final bool loggedIn;
  final List<String> myIdeas;
  final TextEditingController ideaInput;
  final Future<void> Function(String text) onAddIdea;
  final VoidCallback onFinalSubmit;
  final bool isSubmitting;

  @override
  State<BrainstormStudentExperience> createState() =>
      _BrainstormStudentExperienceState();
}

class _BrainstormStudentExperienceState extends State<BrainstormStudentExperience> {
  bool _adding = false;

  /// Oxirgi bosilgan stiker — Stackda yuqorida chiziladi.
  String? _frontStickerId;

  static const double _kStickerW = 132;
  static const double _kStickerH = 98;
  static const double _kStickerGap = 10;

  static const _stickerColors = <Color>[
    Color(0xFFFFF9C4),
    Color(0xFFFFE0B2),
    Color(0xFFFFCDD2),
    Color(0xFFE1BEE7),
    Color(0xFFBBDEFB),
    Color(0xFFC8E6C9),
  ];

  Color _stickerColor(String seed) {
    return _stickerColors[seed.hashCode.abs() % _stickerColors.length];
  }

  int _gridColumns(double boardW) {
    final cell = _kStickerW + _kStickerGap;
    return math.max(1, (boardW / cell).floor());
  }

  double _boardContentHeight(int count, double boardW) {
    if (count == 0) {
      return 120;
    }
    final cols = _gridColumns(boardW);
    final rows = (count + cols - 1) ~/ cols;
    return _kStickerGap + rows * (_kStickerH + _kStickerGap);
  }

  Offset _offsetForGridIndex(int index, double boardW) {
    final cols = _gridColumns(boardW);
    final col = index % cols;
    final row = index ~/ cols;
    return Offset(
      _kStickerGap + col * (_kStickerW + _kStickerGap),
      _kStickerGap + row * (_kStickerH + _kStickerGap),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
    list.sort((a, b) {
      final ta = a.data()['submittedAt'];
      final tb = b.data()['submittedAt'];
      if (ta is Timestamp && tb is Timestamp) {
        return ta.compareTo(tb);
      }
      return a.id.compareTo(b.id);
    });
    return list;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _paintOrder(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sorted,
  ) {
    final id = _frontStickerId;
    if (id == null || id.isEmpty) {
      return sorted;
    }
    final front = sorted.where((d) => d.id == id).toList();
    final rest = sorted.where((d) => d.id != id).toList();
    return [...rest, ...front];
  }

  Future<void> _showStickerDetail(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required ThemeData t,
    required String myUserId,
    required bool hideNames,
  }) async {
    final d = doc.data();
    final text = d['text'] as String? ?? '';
    final sid = d['studentId'] as String? ?? '';
    final likeCount = (d['likeCount'] as num?)?.toInt() ?? 0;
    final likeUsers = (d['likeUserIds'] as List<dynamic>?)
            ?.map((e) => '$e')
            .toList() ??
        <String>[];
    final iLiked = myUserId.isNotEmpty && likeUsers.contains(myUserId);
    final g10 = d['grade10'];
    final g10i = g10 is num ? g10.round().clamp(0, 10) : null;
    final teacherComment = (d['teacherComment'] as String?)?.trim();

    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sticky_note_2, color: t.colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Fikr (to‘liq)')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                text.isEmpty ? '—' : text,
                style: t.textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: t.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _stickerAttribution(
                t,
                studentId: sid,
                myUserId: myUserId,
                hideNames: hideNames,
              ),
              if (sid == myUserId && (g10i != null || (teacherComment != null &&
                      teacherComment.isNotEmpty))) ...[
                const SizedBox(height: 12),
                if (g10i != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: t.colorScheme.primary,
                      ),
                      label: Text('O‘qituvchi bahosi: $g10i/10'),
                    ),
                  ),
                if (teacherComment != null && teacherComment.isNotEmpty) ...[
                  if (g10i != null) const SizedBox(height: 6),
                  Text(
                    'Izoh: $teacherComment',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
              if (sid != myUserId && myUserId.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    context.read<SubmissionRepository>().toggleIdeaLike(
                          lookup: widget.lookup,
                          ideaDocumentId: doc.id,
                          studentId: myUserId,
                        );
                  },
                  icon: Icon(
                    iLiked ? Icons.favorite : Icons.favorite_border,
                    color: t.colorScheme.error,
                  ),
                  label: Text('Yurakcha · $likeCount'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final maxSlots = widget.config.maxIdeasPerStudent;
    final hasTimer = widget.config.durationMinutes > 0;
    final hidePeerNames = widget.config.isAnonymous;
    final auth = context.watch<AuthBloc>().state;
    final me = auth is AuthAuthenticated ? auth.user.id : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGlowingQuestion(context, t),
        if (widget.assignmentCode != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'Kod: ${widget.assignmentCode}',
              style: t.textTheme.labelMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (widget.guide != null && widget.guide!.trim().isNotEmpty) ...[
          Text(
            'Yo‘riq',
            style: t.textTheme.labelLarge?.copyWith(
              color: t.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.guide!.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.bodyMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.rubric.isNotEmpty) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                widget.rubric,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        _buildSlotRow(t, maxSlots),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: context
                          .read<SubmissionRepository>()
                          .watchIdeaFeedByLookup(widget.lookup),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Stack(
                            children: [
                              Positioned.fill(child: _corkBackground(t)),
                              Center(child: Text('${snap.error}')),
                            ],
                          );
                        }
                        if (!snap.hasData) {
                          return Stack(
                            children: [
                              Positioned.fill(child: _corkBackground(t)),
                              const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        final raw = snap.data!.docs;
                        if (raw.isEmpty) {
                          return Stack(
                            children: [
                              Positioned.fill(child: _corkBackground(t)),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Hali stikerlar yo‘q. Pastdan birinchi fikrni yuboring.',
                                    textAlign: TextAlign.center,
                                    style: t.textTheme.bodyMedium?.copyWith(
                                      color: _kStudentSecondaryText,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        final sorted = _sortedDocs(raw);
                        final indexById = {
                          for (var i = 0; i < sorted.length; i++) sorted[i].id: i,
                        };
                        final paint = _paintOrder(sorted);
                        final bw = constraints.maxWidth;
                        final minH = constraints.maxHeight;
                        final contentH = math.max(
                          minH,
                          _boardContentHeight(sorted.length, bw),
                        );
                        return SingleChildScrollView(
                          child: SizedBox(
                            width: bw,
                            height: contentH,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: _corkBackground(t),
                                ),
                                for (final d in paint)
                                  _stickerOnBoard(
                                    context,
                                    t: t,
                                    doc: d,
                                    left: _offsetForGridIndex(
                                      indexById[d.id] ?? 0,
                                      bw,
                                    ).dx,
                                    top: _offsetForGridIndex(
                                      indexById[d.id] ?? 0,
                                      bw,
                                    ).dy,
                                    myUserId: me,
                                    hideNames: hidePeerNames,
                                    stickerColor: _stickerColor(d.id),
                                    isOnTop: d.id == _frontStickerId,
                                    onTap: () {
                                      setState(
                                        () => _frontStickerId = d.id,
                                      );
                                      _showStickerDetail(
                                        context,
                                        d,
                                        t: t,
                                        myUserId: me,
                                        hideNames: hidePeerNames,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasTimer)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _cornerTimerPill(
                        t,
                        widget.timeExpired
                            ? '00:00'
                            : widget.formatMmSs(widget.secondsLeft),
                        danger: (widget.secondsLeft ?? 0) <= 10 &&
                            !widget.timeExpired,
                        expired: widget.timeExpired,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        _buildBottomInput(t),
      ],
    );
  }

  Widget _buildGlowingQuestion(BuildContext context, ThemeData t) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.colorScheme.primaryContainer.withValues(alpha: 0.95),
            t.colorScheme.tertiaryContainer.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: t.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: t.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        widget.mainPrompt,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: t.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: t.colorScheme.onPrimaryContainer,
        ),
      )
          .animate(
            onPlay: (c) => c.repeat(reverse: true),
          )
          .shimmer(
            delay: 1.seconds,
            duration: 2.5.seconds,
            color: t.colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
          ),
    );
  }

  Widget _corkBackground(ThemeData t) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD7CCC8),
            Color(0xFFBCAAA4),
          ],
        ),
        border: Border.all(
          color: t.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _stickerOnBoard(
    BuildContext context, {
    required ThemeData t,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required double left,
    required double top,
    required String myUserId,
    required bool hideNames,
    required Color stickerColor,
    required bool isOnTop,
    required VoidCallback onTap,
  }) {
    final d = doc.data();
    final text = d['text'] as String? ?? '';
    final sid = d['studentId'] as String? ?? '';
    final likeCount = (d['likeCount'] as num?)?.toInt() ?? 0;
    final likeUsers = (d['likeUserIds'] as List<dynamic>?)
            ?.map((e) => '$e')
            .toList() ??
        <String>[];
    final iLiked = myUserId.isNotEmpty && likeUsers.contains(myUserId);
    final g10 = d['grade10'];
    final g10i = g10 is num ? g10.round().clamp(0, 10) : null;
    final isMine = sid == myUserId && myUserId.isNotEmpty;

    final rng = math.Random(doc.id.hashCode);
    final rot = (rng.nextDouble() - 0.5) * 0.12;
    final scale = 0.9 + 0.1 * (likeCount / (likeCount + 3)).clamp(0, 1);

    return Positioned(
      key: ValueKey('sticker-${doc.id}'),
      left: left,
      top: top,
      child: Transform.rotate(
        angle: rot,
        child: Transform.scale(
          scale: scale,
          child: Material(
            elevation: isOnTop ? 10 : 3,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(4),
              child: Ink(
                decoration: BoxDecoration(
                  color: stickerColor,
                  border: Border.all(
                    color: isOnTop
                        ? t.colorScheme.primary
                        : (likeCount > 2
                            ? Colors.amber.shade600.withValues(alpha: 0.5)
                            : Colors.black12),
                    width: isOnTop ? 1.5 : 1,
                  ),
                  boxShadow: likeCount > 0
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(
                              alpha: 0.2 +
                                  0.06 *
                                      likeCount.toDouble().clamp(0, 5),
                            ),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Container(
                  width: _kStickerW,
                  height: _kStickerH,
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          maxLines: isMine && g10i != null ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.copyWith(
                            height: 1.2,
                            fontWeight:
                                isOnTop ? FontWeight.w600 : FontWeight.w500,
                            color: _kStudentBodyText,
                          ),
                        ),
                      ),
                      if (isMine && g10i != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          'Baho: $g10i/10',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.labelSmall?.copyWith(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: t.colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: _stickerAttribution(
                              t,
                              studentId: sid,
                              myUserId: myUserId,
                              hideNames: hideNames,
                            ),
                          ),
                          if (sid != myUserId && myUserId.isNotEmpty) ...[
                            InkWell(
                              onTap: () {
                                context
                                    .read<SubmissionRepository>()
                                    .toggleIdeaLike(
                                      lookup: widget.lookup,
                                      ideaDocumentId: doc.id,
                                      studentId: myUserId,
                                    );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      iLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 14,
                                      color: t.colorScheme.error,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$likeCount',
                                      style: t.textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _kStudentBodyText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _stickerAttribution(
    ThemeData t, {
    required String studentId,
    required String myUserId,
    required bool hideNames,
  }) {
    if (studentId == myUserId) {
      return Text(
        'Siz',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.textTheme.labelSmall?.copyWith(
          fontSize: 9.5,
          color: _kStudentBodyText,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (hideNames) {
      return Text(
        'Anonim',
        maxLines: 1,
        style: t.textTheme.labelSmall?.copyWith(
          fontSize: 9.5,
          color: _kStudentSecondaryText,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return FutureBuilder<String>(
      future: StudentDisplayNameResolver.forUid(studentId),
      builder: (context, snap) {
        final s = snap.data ?? '·';
        return Text(
          s,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.labelSmall?.copyWith(
            fontSize: 9.5,
            color: _kStudentSecondaryText,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  Widget _cornerTimerPill(
    ThemeData t,
    String time, {
    required bool danger,
    required bool expired,
  }) {
    return Material(
      color: (danger && !expired)
          ? t.colorScheme.error
          : (expired ? t.colorScheme.outline : t.colorScheme.primary),
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 16,
              color: t.colorScheme.onError,
            ),
            const SizedBox(width: 5),
            Text(
              expired ? 'Tugadi' : time,
              style: t.textTheme.labelLarge?.copyWith(
                color: t.colorScheme.onError,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotRow(ThemeData t, int maxSlots) {
    return Row(
      children: List.generate(maxSlots, (i) {
        final filled = i < widget.myIdeas.length;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: 200.ms,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: filled
                    ? _stickerColors[i % _stickerColors.length]
                    : t.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                border: Border.all(
                  color: filled
                      ? t.colorScheme.primary
                      : t.colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomInput(ThemeData t) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 10,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: t.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: t.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yangi fikr',
                style: t.textTheme.labelLarge?.copyWith(
                  color: t.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: widget.ideaInput,
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                enabled: widget.loggedIn && !widget.blockSession,
                style: TextStyle(
                  color: t.colorScheme.onSurface,
                  fontSize: 16,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Bir qator – bir g‘oya. Doskaga yuborishingiz mumkin',
                  hintStyle: TextStyle(
                    color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onPressed: (widget.isSubmitting ||
                              _adding ||
                              !widget.loggedIn ||
                              widget.blockSession)
                          ? null
                          : () async {
                              final s = widget.ideaInput.text.trim();
                              if (s.isEmpty) {
                                return;
                              }
                              if (widget.myIdeas.length >=
                                  widget.config.maxIdeasPerStudent) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fikr limiti to’lgan. Avvalgilar doskada',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              setState(() => _adding = true);
                              try {
                                await widget.onAddIdea(s);
                              } finally {
                                if (mounted) {
                                  setState(() => _adding = false);
                                }
                              }
                            },
                      icon: _adding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sticky_note_2_outlined, size: 20),
                      label: const Text(
                        'Doskaga yuborish',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onPressed: (widget.isSubmitting ||
                            !widget.loggedIn ||
                            widget.blockSession)
                        ? null
                        : widget.onFinalSubmit,
                    child: widget.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Yuborish'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

