// ignore_for_file: deprecated_member_use

import 'dart:math' show Random;
import 'dart:ui' show ImageFilter;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/t_schema/t_schema_method_config.dart';

const _uuid = Uuid();

class TSchemaDragPayload {
  const TSchemaDragPayload({
    required this.id,
    required this.text,
    required this.correctSide,
    required this.isUserAdded,
  });

  final String id;
  final String text;
  final String correctSide;
  final bool isUserAdded;
}

typedef TSchemaDraftMap = Map<String, dynamic>;

/// O‘quvchi: T-sxema drag-and-drop, taymer, stikerlar banki, foydalanuvchi stikerlari.
class TSchemaInteractiveSolver extends StatefulWidget {
  const TSchemaInteractiveSolver({
    super.key,
    required this.config,
    required this.shuffleSeed,
    this.initialDraft,
    required this.onStateChanged,
    this.secondsLeft,
    this.timeExpired = false,
  });

  final TSchemaMethodConfig config;
  final int shuffleSeed;
  final TSchemaDraftMap? initialDraft;
  final VoidCallback onStateChanged;
  final int? secondsLeft;
  final bool timeExpired;

  @override
  State<TSchemaInteractiveSolver> createState() => TSchemaInteractiveSolverState();
}

class TSchemaInteractiveSolverState extends State<TSchemaInteractiveSolver> {
  final List<TSchemaStickerDef> _pool = [];
  final Map<String, TSchemaStickerDef> _leftColumn = {};
  final Map<String, TSchemaStickerDef> _rightColumn = {};
  String? _rejectingId;
  bool _celebration = false;

  int get _targetPresetCount =>
      widget.config.leftItems.length + widget.config.rightItems.length;

  int get _correctPlacedCount {
    var n = 0;
    for (final e in widget.config.leftItems) {
      if (_leftColumn.containsKey(e.id)) {
        n++;
      }
    }
    for (final e in widget.config.rightItems) {
      if (_rightColumn.containsKey(e.id)) {
        n++;
      }
    }
    return n;
  }

  double get _progress =>
      _targetPresetCount <= 0 ? 1.0 : (_correctPlacedCount / _targetPresetCount).clamp(0.0, 1.0);

  bool get isSessionComplete =>
      _targetPresetCount <= 0 ? false : _pool.isEmpty && _correctPlacedCount >= _targetPresetCount;

  String _correctSideForPresetId(String id) {
    if (widget.config.leftItems.any((e) => e.id == id)) {
      return 'left';
    }
    return 'right';
  }

  TSchemaStickerDef? _defById(String id) {
    for (final e in widget.config.leftItems) {
      if (e.id == id) {
        return e;
      }
    }
    for (final e in widget.config.rightItems) {
      if (e.id == id) {
        return e;
      }
    }
    return _leftColumn[id] ?? _rightColumn[id];
  }

  @override
  void initState() {
    super.initState();
    _initFromScratch();
    _applyDraft(widget.initialDraft);
    _maybeCelebration();
  }

  @override
  void didUpdateWidget(covariant TSchemaInteractiveSolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shuffleSeed != widget.shuffleSeed ||
        oldWidget.config.leftItems.length != widget.config.leftItems.length ||
        oldWidget.config.rightItems.length != widget.config.rightItems.length) {
      _initFromScratch();
      _maybeCelebration();
    }
  }

  void _initFromScratch() {
    _pool.clear();
    _leftColumn.clear();
    _rightColumn.clear();
    _celebration = false;
    final all = <TSchemaStickerDef>[
      ...widget.config.leftItems,
      ...widget.config.rightItems,
    ];
    final order = List<TSchemaStickerDef>.from(all);
    order.shuffle(Random(widget.shuffleSeed));
    _pool.addAll(order);
  }

  void _applyDraft(TSchemaDraftMap? d) {
    if (d == null) {
      return;
    }
    final poolIds = (d['tSchemaPoolIds'] as List?)?.map((e) => '$e').toList();
    final leftIds = (d['tSchemaLeftIds'] as List?)?.map((e) => '$e').toList();
    final rightIds = (d['tSchemaRightIds'] as List?)?.map((e) => '$e').toList();
    final userRaw = d['tSchemaUserAdded'] as List?;

    if (poolIds == null && leftIds == null && rightIds == null && userRaw == null) {
      return;
    }

    _leftColumn.clear();
    _rightColumn.clear();
    _pool.clear();

    final allPreset = <TSchemaStickerDef>[
      ...widget.config.leftItems,
      ...widget.config.rightItems,
    ];
    final byId = {for (final e in allPreset) e.id: e};

    void placeSide(String id, String side) {
      final def = byId[id];
      if (def == null) {
        return;
      }
      if (side == 'left') {
        _leftColumn[id] = def;
      } else {
        _rightColumn[id] = def;
      }
    }

    if (leftIds != null) {
      for (final id in leftIds) {
        placeSide(id, 'left');
      }
    }
    if (rightIds != null) {
      for (final id in rightIds) {
        placeSide(id, 'right');
      }
    }

    if (userRaw != null) {
      for (final raw in userRaw) {
        if (raw is! Map) {
          continue;
        }
        final m = Map<String, dynamic>.from(raw);
        final id = '${m['id'] ?? ''}'.trim();
        final text = '${m['text'] ?? ''}'.trim();
        final side = '${m['side'] ?? 'left'}'.trim();
        if (id.isEmpty || text.isEmpty) {
          continue;
        }
        final def = TSchemaStickerDef(id: id, text: text, isUserAdded: true);
        if (side == 'right') {
          _rightColumn[id] = def;
        } else {
          _leftColumn[id] = def;
        }
      }
    }

    if (poolIds != null && poolIds.isNotEmpty) {
      for (final id in poolIds) {
        final def = byId[id];
        if (def != null && !_leftColumn.containsKey(id) && !_rightColumn.containsKey(id)) {
          _pool.add(def);
        }
      }
    } else {
      for (final def in allPreset) {
        if (!_leftColumn.containsKey(def.id) && !_rightColumn.containsKey(def.id)) {
          _pool.add(def);
        }
      }
      _pool.shuffle(Random(widget.shuffleSeed));
    }
  }

  TSchemaDraftMap captureDraft() {
    return {
      'tSchemaPoolIds': _pool.map((e) => e.id).toList(),
      'tSchemaLeftIds': _leftColumn.keys.toList(),
      'tSchemaRightIds': _rightColumn.keys.toList(),
      'tSchemaUserAdded': [
        for (final e in _leftColumn.entries)
          if (e.value.isUserAdded) {'id': e.key, 'text': e.value.text, 'side': 'left'},
        for (final e in _rightColumn.entries)
          if (e.value.isUserAdded) {'id': e.key, 'text': e.value.text, 'side': 'right'},
      ],
    };
  }

  String _summaryText() {
    final buf = StringBuffer();
    buf.writeln(widget.config.center);
    buf.writeln('— ${widget.config.leftTitle} —');
    for (final e in _leftColumn.values) {
      buf.writeln('• ${e.text}');
    }
    buf.writeln('— ${widget.config.rightTitle} —');
    for (final e in _rightColumn.values) {
      buf.writeln('• ${e.text}');
    }
    return buf.toString().trim();
  }

  Map<String, dynamic> buildAnswerPayload() {
    final userAdded = <Map<String, dynamic>>[
      for (final e in _leftColumn.entries)
        if (e.value.isUserAdded) {'side': 'left', 'id': e.key, 'text': e.value.text},
      for (final e in _rightColumn.entries)
        if (e.value.isUserAdded) {'side': 'right', 'id': e.key, 'text': e.value.text},
    ];
    return {
      'kind': 'fishbone',
      'text': _summaryText(),
      'tSchemaInteractive': true,
      'tSchema': {
        'left': [
          for (final e in _leftColumn.entries)
            {'id': e.key, 'text': e.value.text, 'userAdded': e.value.isUserAdded},
        ],
        'right': [
          for (final e in _rightColumn.entries)
            {'id': e.key, 'text': e.value.text, 'userAdded': e.value.isUserAdded},
        ],
        'userAddedItems': userAdded,
      },
    };
  }

  void _notify() {
    widget.onStateChanged();
  }

  void _maybeCelebration() {
    if (isSessionComplete && _targetPresetCount > 0 && mounted) {
      setState(() => _celebration = true);
    }
  }

  void _onDrop(TSchemaDragPayload data, String targetSide) {
    final ok = data.correctSide == targetSide;
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() => _rejectingId = data.id);
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (mounted) {
          setState(() => _rejectingId = null);
        }
      });
      return;
    }
    HapticFeedback.mediumImpact();
    final def = _defById(data.id);
    if (def == null) {
      return;
    }
    setState(() {
      _pool.removeWhere((e) => e.id == data.id);
      if (targetSide == 'left') {
        _leftColumn[data.id] = def;
      } else {
        _rightColumn[data.id] = def;
      }
    });
    _notify();
    _maybeCelebration();
  }

  Future<void> _addUserSticker() async {
    final maxN = widget.config.maxUserStickers;
    final currentUser = _leftColumn.values.where((e) => e.isUserAdded).length +
        _rightColumn.values.where((e) => e.isUserAdded).length;
    if (maxN <= 0) {
      return;
    }
    if (currentUser >= maxN) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maksimal $maxN ta o‘z fikringiz')),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final textCtrl = TextEditingController();
    var side = 'left';
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          title: const Text('O‘z fikringiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'left',
                    label: Text(widget.config.leftTitle, overflow: TextOverflow.ellipsis),
                  ),
                  ButtonSegment(
                    value: 'right',
                    label: Text(widget.config.rightTitle, overflow: TextOverflow.ellipsis),
                  ),
                ],
                selected: {side},
                onSelectionChanged: (s) => setSt(() => side = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Matn',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, '${side.trim()}|${textCtrl.text.trim()}'),
              child: const Text('Qo‘shish'),
            ),
          ],
        ),
      ),
    );
    textCtrl.dispose();
    final raw = picked?.trim() ?? '';
    if (raw.isEmpty || !raw.contains('|') || !mounted) {
      return;
    }
    final sep = raw.indexOf('|');
    final sidePick = raw.substring(0, sep).trim();
    final t = raw.substring(sep + 1).trim();
    if (t.isEmpty) {
      return;
    }
    final id = 'user_${_uuid.v4()}';
    final def = TSchemaStickerDef(id: id, text: t, isUserAdded: true);
    setState(() {
      if (sidePick == 'right') {
        _rightColumn[id] = def;
      } else {
        _leftColumn[id] = def;
      }
    });
    HapticFeedback.lightImpact();
    _notify();
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? pad}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: pad ?? const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _stickerTile(TSchemaStickerDef def, {required String correctSide, Key? key}) {
    final isReject = _rejectingId == def.id;
    final payload = TSchemaDragPayload(
      id: def.id,
      text: def.text,
      correctSide: correctSide,
      isUserAdded: def.isUserAdded,
    );
    final inner = _glassCard(
      pad: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 72, maxWidth: 160, maxHeight: 120),
        child: AutoSizeText(
          def.text,
          maxLines: 6,
          minFontSize: 10,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
        ),
      ),
    );
    Widget card = inner;
    if (isReject) {
      card = inner
          .animate(key: ValueKey('rej_${def.id}'))
          .shake(duration: 380.ms, hz: 4, curve: Curves.easeInOut);
    }
    return Draggable<TSchemaDragPayload>(
      key: key,
      data: payload,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.95,
          child: SizedBox(
            width: 160,
            child: inner,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: inner),
      child: card,
    );
  }

  Widget _buildColumn({
    required String side,
    required String title,
    required Gradient gradient,
  }) {
    return DragTarget<TSchemaDragPayload>(
      onAcceptWithDetails: (details) => _onDrop(details.data, side),
      builder: (context, candidate, rejected) {
        final items = side == 'left' ? _leftColumn.entries.toList() : _rightColumn.entries.toList();
        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  children: [
                    for (final e in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _stickerTile(
                          e.value,
                          correctSide: side,
                          key: ValueKey('col_${e.key}'),
                        ).animate(target: isSessionComplete ? 1 : 0).scale(
                              begin: const Offset(0.92, 0.92),
                              end: const Offset(1, 1),
                              duration: 350.ms,
                              curve: Curves.elasticOut,
                            ),
                      ),
                    if (candidate.isNotEmpty)
                      Container(
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTimer = widget.config.durationMinutes > 0;
    final mmSs = widget.secondsLeft == null
        ? '—'
        : '${(widget.secondsLeft! ~/ 60).toString().padLeft(2, '0')}:${(widget.secondsLeft! % 60).toString().padLeft(2, '0')}';

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTimer) ...[
              Row(
                children: [
                  Icon(
                    widget.timeExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.timeExpired ? 'Vaqt tugadi' : 'Qolgan vaqt: $mmSs',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 6),
            Card(
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  widget.config.center,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildColumn(
                            side: 'left',
                            title: widget.config.leftTitle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFDFF5E4),
                                const Color(0xFFC8EDD0).withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 4,
                          color: const Color(0xFF1565C0).withValues(alpha: 0.85),
                        ),
                        Expanded(
                          child: _buildColumn(
                            side: 'right',
                            title: widget.config.rightTitle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFFFF9E0),
                                const Color(0xFFFFF3BF).withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pastga sudrang',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 104,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final def in _pool)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _stickerTile(
                                def,
                                correctSide: _correctSideForPresetId(def.id),
                                key: ValueKey('pool_${def.id}'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.config.maxUserStickers > 0)
          Positioned(
            right: 8,
            bottom: 118,
            child: FloatingActionButton.small(
              heroTag: 'tschema_add',
              onPressed: widget.timeExpired ? null : _addUserSticker,
              child: const Icon(Icons.add),
            ),
          ),
        if (_celebration)
          Positioned.fill(
            child: Material(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ajoyib!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Barcha stikerlar to‘g‘ri joyda',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(() => _celebration = false),
                          child: const Text('Yaxshi'),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.elasticOut)
                    .fadeIn(),
              ),
            ),
          ),
      ],
    );
  }
}
