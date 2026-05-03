import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Firebase yo‘q bo‘lsa ogohlantirish (kirish / ro‘yxatdan o‘tishdan oldin).
class FirebaseSetupBanner extends StatelessWidget {
  const FirebaseSetupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isNotEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase ulangan emas',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kirish va ro\'yxatdan o\'tish ishlamaydi. Loyiha ildizida '
              '`flutterfire configure` ni ishga tushiring (avval: '
              '`dart pub global activate flutterfire_cli`).',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
