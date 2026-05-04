import 'package:flutter/material.dart';

import '../constants/method_types.dart';

/// Loyiha ildizidagi `icons/` papkadagi rasmlar (`pubspec.yaml`da ro‘yxatlangan).
abstract final class MethodTypeArtwork {
  /// Firestore `methods.type` qiymati → asset yo‘li.
  static String? assetPathForFirestoreType(String type) {
    switch (type) {
      case 'quiz':
        return 'icons/quiz.png';
      case 'brainstorm':
        return 'icons/aqliy-hujum.png';
      case 'case':
        return 'icons/case-study.png';
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

/// Metod kartochkalari uchun rang va qisqa matnlar.
abstract final class MethodTypeVisual {
  static Color iconCircleColor(String type, Brightness brightness) {
    final light = brightness == Brightness.light;
    switch (type) {
      case 'brainstorm':
        return light
            ? const Color(0xFFFFF3C9)
            : const Color(0xFF5D4200).withValues(alpha: 0.38);
      case 'case':
        return light
            ? const Color(0xFFE0F4F1)
            : const Color(0xFF004D40).withValues(alpha: 0.35);
      case 'group':
        return light
            ? const Color(0xFFE3F0FF)
            : const Color(0xFF0D47A1).withValues(alpha: 0.32);
      case 'quiz':
        return light
            ? const Color(0xFFF0E9FF)
            : const Color(0xFF4A148C).withValues(alpha: 0.32);
      case 'fishbone':
        return light
            ? const Color(0xFFFFEDD5)
            : const Color(0xFFE65100).withValues(alpha: 0.3);
      case 'poll':
        return light
            ? const Color(0xFFFFE4EE)
            : const Color(0xFF880E4F).withValues(alpha: 0.3);
      case 'role_play':
        return light
            ? const Color(0xFFE8F5E8)
            : const Color(0xFF1B5E20).withValues(alpha: 0.32);
      default:
        return light
            ? const Color(0xFFF0F0F0)
            : Colors.white.withValues(alpha: 0.08);
    }
  }

  static String typeLabelUz(String type) {
    switch (type) {
      case 'quiz':
        return 'Test (Quiz)';
      case 'brainstorm':
        return 'Aqliy hujum';
      case 'case':
        return 'Muammoli vaziyat';
      case 'group':
        return 'Klaster';
      case 'fishbone':
        return 'T-sxema';
      case 'poll':
        return 'So‘rovnoma';
      case 'role_play':
        return 'Rolli o‘yin';
      default:
        return type;
    }
  }

  /// Karta ostidagi 1–2 qator tushuntirish.
  static String blurbUz(String type) {
    switch (type) {
      case 'quiz':
        return 'Savol-javob va bilimni tekshirish.';
      case 'brainstorm':
        return 'G‘oyalarni yozish va tartiblash.';
      case 'case':
        return 'Muammoni tahlil qilish va yechim.';
      case 'group':
        return 'Markaz va tarmoqlarni bog‘lash.';
      case 'fishbone':
        return 'Sabab-oqibat (baliq suyagi) sxemasi.';
      case 'poll':
        return 'So‘rov va javoblar statistikasi.';
      case 'role_play':
        return 'Rollarni tarqatib mashq qilish.';
      default:
        return 'Interaktiv metod.';
    }
  }
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
