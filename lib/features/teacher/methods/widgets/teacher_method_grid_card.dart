import 'package:flutter/material.dart';

import '../../../../core/widgets/method_type_artwork.dart';

/// Metodlar ro‘yxati yoki tanlash dialogi uchun kartochka (hero + pastki panel).
class TeacherMethodGridCard extends StatefulWidget {
  const TeacherMethodGridCard({
    super.key,
    required this.title,
    required this.methodType,
    required this.onOpen,
    this.actions,
    this.contextHint,
    this.isPreset,
    this.showBlurb = true,
    this.showBoshlash = true,
  });

  final String title;
  final String methodType;
  final VoidCallback onOpen;
  final List<Widget>? actions;
  /// Masalan, "7-sinf · Mavzu"
  final String? contextHint;
  final bool? isPreset;
  final bool showBlurb;
  final bool showBoshlash;

  static const double _radius = 18;

  @override
  State<TeacherMethodGridCard> createState() => _TeacherMethodGridCardState();
}

class _TeacherMethodGridCardState extends State<TeacherMethodGridCard> {
  bool _hover = false;

  /// Sarlavhada texnik id va "Klaster:" prefikslarini obertmasdan tozalaydi.
  static String _heroTitle(String raw, String methodType) {
    var t = raw.trim();
    t = t.replaceFirst(RegExp(r'^klaster\s*:', caseSensitive: false), '').trim();
    t = t.replaceAll(RegExp(r'\bpreset_[a-z0-9_]+\b', caseSensitive: false), '').trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) {
      return MethodTypeVisual.typeLabelUz(methodType);
    }
    if (RegExp(r'^[_a-z0-9]+$').hasMatch(t) && t.contains('_')) {
      return MethodTypeVisual.typeLabelUz(methodType);
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brightness = theme.brightness;
    final heroTitle = _heroTitle(widget.title, widget.methodType);
    final blurb = MethodTypeVisual.blurbUz(widget.methodType);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: cs.surfaceContainerLowest,
        elevation: _hover ? 3 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        surfaceTintColor: cs.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TeacherMethodGridCard._radius),
          side: BorderSide(
            color: _hover
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.55),
            width: _hover ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onOpen,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: _MethodHeroBackdrop(
                          methodType: widget.methodType,
                          brightness: brightness,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              heroTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                height: 1.2,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (widget.contextHint != null &&
                                widget.contextHint!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.contextHint!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (widget.showBlurb) ...[
                              const SizedBox(height: 8),
                              Text(
                                blurb,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 12,
              child: Container(
                color: Color.alphaBlend(
                  cs.primaryContainer.withValues(alpha: 0.22),
                  cs.surface,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          top: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.isPreset == true)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Tayyor shablon',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else if (widget.isPreset == false)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Qo‘shimcha',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (widget.actions != null &&
                              widget.actions!.isNotEmpty)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: widget.actions!,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          if (widget.showBoshlash)
                            FilledButton(
                              onPressed: widget.onOpen,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const CircleBorder(),
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                elevation: _hover ? 3 : 1,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 22,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodHeroBackdrop extends StatelessWidget {
  const _MethodHeroBackdrop({
    required this.methodType,
    required this.brightness,
  });

  final String methodType;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final path = MethodTypeArtwork.assetPathForFirestoreType(methodType);
    if (path != null) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _MethodHeroFallback(methodType: methodType, brightness: brightness),
      );
    }
    return _MethodHeroFallback(methodType: methodType, brightness: brightness);
  }
}

class _MethodHeroFallback extends StatelessWidget {
  const _MethodHeroFallback({
    required this.methodType,
    required this.brightness,
  });

  final String methodType;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final c = MethodTypeVisual.iconCircleColor(methodType, brightness);
    final deep = Color.alphaBlend(c, const Color(0xFF4A148C));
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, deep],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.45,
          child: MethodTypeArtworkImage(
            methodType: methodType,
            fit: BoxFit.contain,
            iconSize: 72,
          ),
        ),
      ),
    );
  }
}
