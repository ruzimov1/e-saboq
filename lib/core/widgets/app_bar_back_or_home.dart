import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_home_icon.dart';

/// AppBar chap: stackda orqaga qaytish bo'lsa — avvalo asosiy menyu (uy), keyin orqaga;
/// aks holda faqat bosh sahifaga o'tish (uy).
class AppBarBackOrHomeLeading extends StatelessWidget {
  const AppBarBackOrHomeLeading({super.key});

  /// Orqaga + asosiy menyu ikkalasi uchun AppBar. leadingWidth.
  static double leadingWidth(BuildContext context) {
    if (!context.canPop()) {
      return kToolbarHeight;
    }
    return 112.0;
  }

  @override
  Widget build(BuildContext context) {
    if (context.canPop()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Asosiy menyu',
            child: const AppHomeIcon(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
            tooltip: 'Orqaga',
          ),
        ],
      );
    }
    return const AppHomeIcon();
  }
}
