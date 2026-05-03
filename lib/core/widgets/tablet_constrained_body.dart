import 'package:flutter/material.dart';

import '../theme/app_design_tokens.dart';

/// Planshet / keng ekranda kontentni cheklangan kenglikda markazlashtiradi.
class TabletConstrainedBody extends StatelessWidget {
  const TabletConstrainedBody({
    super.key,
    required this.child,
    this.maxWidth = AppDesignTokens.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth <= maxWidth) return child;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
