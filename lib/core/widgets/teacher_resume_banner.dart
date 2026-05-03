import 'package:flutter/material.dart';

import '../services/teacher_last_route_prefs.dart';

/// "Oxirgi joy" — tezkor qaytish.
class TeacherResumeBanner extends StatelessWidget {
  const TeacherResumeBanner({
    super.key,
    required this.route,
    required this.onOpen,
  });

  final TeacherLastRoute route;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Material(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14),
          child: Semantics(
            button: true,
            label: 'Oxirgi joy: ${route.contextSummaryLine()}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oxirgi joy',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.contextSummaryLine(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
