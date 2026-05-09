import 'package:flutter/material.dart';

import '../../../../core/widgets/method_type_artwork.dart';

/// Metodlar ro‘yxati: logo (`BoxFit.contain`) + pastda metod nomi va ixtiyoriy ikonlar.
class TeacherMethodGridCard extends StatefulWidget {
  const TeacherMethodGridCard({
    super.key,
    required this.methodType,
    required this.methodName,
    required this.onOpen,
    this.actions,
    this.showBoshlash = true,
  });

  final String methodType;
  /// Pastki qatorda ko‘rinadigan metod nomi (masalan, «Aqliy hujum»).
  final String methodName;
  final VoidCallback onOpen;
  final List<Widget>? actions;
  /// Pastki panel (dialogda odatda false).
  final bool showBoshlash;

  static const double _radius = 18;

  @override
  State<TeacherMethodGridCard> createState() => _TeacherMethodGridCardState();
}

class _TeacherMethodGridCardState extends State<TeacherMethodGridCard> {
  bool _hover = false;

  bool get _hasFooter =>
      widget.showBoshlash ||
      (widget.actions != null && widget.actions!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brightness = theme.brightness;
    final hasActions =
        widget.actions != null && widget.actions!.isNotEmpty;

    final hero = ColoredBox(
      color: cs.surfaceContainerLow,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Center(
              child: _MethodHeroBackdrop(
                methodType: widget.methodType,
                brightness: brightness,
              ),
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: _hover ? const Offset(0, -0.04) : Offset.zero,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: cs.surfaceContainerLowest,
          elevation: _hover ? 8 : 1,
          shadowColor: Colors.black.withValues(alpha: _hover ? 0.22 : 0.14),
          surfaceTintColor: cs.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(TeacherMethodGridCard._radius),
            side: BorderSide(
              color: _hover
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.55),
              width: _hover ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: hero),
              if (_hasFooter)
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
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.showBoshlash)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: hasActions ? 36 : 4,
                          ),
                          child: TextButton(
                            onPressed: widget.onOpen,
                            style: TextButton.styleFrom(
                              foregroundColor: cs.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              widget.methodName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: (theme.textTheme.titleSmall
                                            ?.fontSize ??
                                        14) -
                                    0.5,
                              ),
                            ),
                          ),
                        ),
                      if (hasActions)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: widget.actions!,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
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
        fit: BoxFit.contain,
        alignment: Alignment.center,
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
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, deep],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: MethodTypeArtworkImage(
            methodType: methodType,
            fit: BoxFit.contain,
            iconSize: 58,
          ),
        ),
      ),
    );
  }
}
