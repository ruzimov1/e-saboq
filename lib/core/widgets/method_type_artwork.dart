import 'package:flutter/material.dart';

import '../constants/method_types.dart';

/// Loyiha ildizidagi `icons/` papkadagi rasmlar (`pubspec.yaml`da ro‘yxatlangan).
abstract final class MethodTypeArtwork {
  /// Firestore `methods.type` qiymati → asset yo‘li.
  static String? assetPathForFirestoreType(String type) {
    switch (type) {
      case 'quiz':
        return 'icons/Quiz.png';
      case 'brainstorm':
        return 'icons/Aqliy hujum.png';
      case 'case':
        return 'icons/Muammoli vaziyat(case-study).png';
      case 'group':
        return 'icons/klaster.png';
      case 'fishbone':
        return 'icons/t-sxema.png';
      case 'poll':
      case 'role_play':
        return null;
      default:
        return null;
    }
  }

  static String? assetPathForMethodType(MethodType mt) =>
      assetPathForFirestoreType(mt.firestoreValue);
}

/// Metod turiga mos raster yoki [fallback].
class MethodTypeArtworkImage extends StatelessWidget {
  const MethodTypeArtworkImage({
    super.key,
    required this.methodType,
    this.fit = BoxFit.contain,
    this.fallbackIcon = Icons.widgets_outlined,
    this.iconSize = 40,
  });

  final String methodType;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final path = MethodTypeArtwork.assetPathForFirestoreType(methodType);
    final cs = Theme.of(context).colorScheme;
    if (path == null) {
      return Icon(
        fallbackIcon,
        size: iconSize,
        color: cs.onSurfaceVariant,
      );
    }
    return Image.asset(
      path,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        fallbackIcon,
        size: iconSize,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
