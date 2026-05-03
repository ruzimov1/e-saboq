import 'dart:math' as math;

import 'package:flutter/material.dart';

/// O‘qituvchi klasteri uchun soddalashgan "mind map" ko‘rinishi (o‘qituvchi preview).
class ClusterMindMapPreview extends StatelessWidget {
  const ClusterMindMapPreview({
    super.key,
    required this.center,
    required this.branches,
  });

  final String center;
  final List<({String text, Color color})> branches;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final use = branches.where((b) => b.text.trim().isNotEmpty).toList();
    if (center.trim().isEmpty && use.isEmpty) {
      return Center(
        child: Text(
          'Markaz va kamida bitta tarmoq kiriting',
          style: th.textTheme.bodySmall?.copyWith(
            color: th.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight.isFinite
            ? c.maxHeight.clamp(180.0, 520.0)
            : math.min(MediaQuery.sizeOf(context).shortestSide * 0.45, 320.0);
        return CustomPaint(
          size: Size(w, h),
          painter: _ClusterRadialPainter(
            centerText: center.trim().isEmpty ? '…' : center.trim(),
            branches: use,
            theme: th,
          ),
        );
      },
    );
  }
}

class _ClusterRadialPainter extends CustomPainter {
  _ClusterRadialPainter({
    required this.centerText,
    required this.branches,
    required this.theme,
  });

  final String centerText;
  final List<({String text, Color color})> branches;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final n = math.max(branches.length, 1);
    final r = (math.min(size.width, size.height) * 0.36).clamp(52.0, 110.0);
    final linePaint = Paint()
      ..color = theme.colorScheme.outlineVariant
      ..strokeWidth = 1.2;

    for (var i = 0; i < branches.length; i++) {
      final t = i / n * 2 * math.pi - math.pi / 2;
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      canvas.drawLine(Offset(cx, cy), Offset(x, y), linePaint);
    }

    // Markaz
    final centerR = 44.0;
    final cPaint = Paint()..color = theme.colorScheme.primaryContainer;
    canvas.drawCircle(Offset(cx, cy), centerR, cPaint);
    _drawFitted(
      canvas,
      centerText,
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: centerR * 1.6,
        height: centerR * 1.4,
      ),
      theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 13),
    );

    // Tarmoqlar
    for (var i = 0; i < branches.length; i++) {
      final t = i / n * 2 * math.pi - math.pi / 2;
      final x = cx + r * math.cos(t);
      final y = cy + r * math.sin(t);
      final p = branches[i].color;
      final chipPaint = Paint()..color = p.withValues(alpha: 0.25);
      final rx = 48.0;
      final ry = 20.0;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
        const Radius.circular(10),
      );
      canvas.drawRRect(rrect, chipPaint);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _drawFitted(
        canvas,
        branches[i].text,
        Rect.fromCenter(center: Offset(x, y), width: rx * 1.85, height: ry * 1.7),
        theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ) ??
            const TextStyle(fontSize: 10),
      );
    }
  }

  void _drawFitted(
    Canvas canvas,
    String text,
    Rect rect,
    TextStyle? base,
  ) {
    final s = _short(text, 48);
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: base,
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 3,
    )..layout(maxWidth: rect.width);
    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
  }

  String _short(String t, int max) {
    final x = t.trim();
    if (x.length <= max) return x;
    return '${x.substring(0, max - 1)}…';
  }

  @override
  bool shouldRepaint(covariant _ClusterRadialPainter oldDelegate) {
    return oldDelegate.centerText != centerText ||
        oldDelegate.branches != branches;
  }
}
