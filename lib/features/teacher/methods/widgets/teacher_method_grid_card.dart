import 'package:flutter/material.dart';

import '../../../../core/widgets/method_type_artwork.dart';
import '../../../../core/widgets/minimal_teacher_list.dart';

/// Metodlar ro‘yxati yoki tanlash dialogi uchun yuqorida rasm, pastda matn.
class TeacherMethodGridCard extends StatelessWidget {
  const TeacherMethodGridCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.methodType,
    required this.onOpen,
    this.actions,
    this.presetAccent = false,
  });

  final String title;
  final String? subtitle;
  final String methodType;
  final VoidCallback onOpen;
  final List<Widget>? actions;
  final bool presetAccent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final onVar = cs.onSurfaceVariant;
    final border = cs.outlineVariant.withValues(alpha: 0.65);
    final shadow = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.05);

    final accentBar = presetAccent ? MinimalTeacherList.accent : cs.outline.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(MinimalTeacherList.cardRadius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 108,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: MethodTypeArtworkImage(
                        methodType: methodType,
                        fit: BoxFit.contain,
                        iconSize: 48,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 36,
                              margin: const EdgeInsets.only(right: 10, top: 2),
                              decoration: BoxDecoration(
                                color: accentBar,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: onVar,
                              height: 1.3,
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
          if (actions != null && actions!.isNotEmpty)
            Material(
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
