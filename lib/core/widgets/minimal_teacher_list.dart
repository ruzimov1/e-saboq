import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../theme/app_design_tokens.dart';
import 'app_bar_back_or_home.dart';
import 'app_profile_icon.dart';

/// Fanlar / Sinflar / Mavzular / Metodlar ro'yxatlari uchun umumiy minimal uslub
/// (light/dark tizim mavzusiga moslashadi).
abstract final class MinimalTeacherList {
  /// [Theme.colorScheme.primary] bilan mos — bitta brend rangi.
  static const Color accent = AppColors.primary;
  static const double cardRadius = AppDesignTokens.radiusMd;

  static Color bgOf(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? c.surfaceContainerLowest
        : const Color(0xFFFAFAFA);
  }

  /// Chap: asosiy menyu + orqaga (stack bo'lsa), o'ng: profil; [actions] — qo'shimcha (profildan oldin).
  static AppBar appBar(
    BuildContext context,
    String title, {
    List<Widget>? actions,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.5,
        );
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bgOf(context),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 24,
      leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
      leading: const AppBarBackOrHomeLeading(),
      title: Text(title, style: titleStyle),
      actions: [
        ...?actions,
        const AppProfileIcon(),
      ],
    );
  }

  static Widget progressIndicator(BuildContext context) => Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  static Widget errorText(BuildContext context, String message) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      );

  /// Tarmoq xatosi uchun "Qayta urinish".
  static Widget errorWithRetry(
    BuildContext context,
    String message, {
    required VoidCallback onRetry,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(AppLocalizations.of(context)!.actionRetry),
            ),
          ],
        ),
      ),
    );
  }

  static Widget emptyState(BuildContext context, String message) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      );

  static Widget extendedFab({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: dark ? cs.surfaceContainerHigh : Colors.white,
      foregroundColor: accent,
      elevation: dark ? 2 : 1,
      hoverElevation: 2,
      highlightElevation: 2,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class MinimalTeacherListCard extends StatelessWidget {
  const MinimalTeacherListCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.showChevron = true,
    this.leading,
    this.onDelete,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showChevron;
  final Widget? leading;
  /// O'chirish tugmasi (tizim elementlarida ko'rinmaydi).
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final onVar = cs.onSurfaceVariant;
    final border = cs.outlineVariant.withValues(alpha: 0.6);
    final shadow = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.04);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(MinimalTeacherList.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 26,
                    decoration: BoxDecoration(
                      color: MinimalTeacherList.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (leading != null) ...[
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: leading!,
                    ),
                  ],
                  SizedBox(width: leading == null ? 18 : 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: onSurface,
                            height: 1.25,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: onVar,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else ...[
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'O\'chirish',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: cs.error,
                          size: 22,
                        ),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    if (showChevron)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: cs.outline,
                          size: 22,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
