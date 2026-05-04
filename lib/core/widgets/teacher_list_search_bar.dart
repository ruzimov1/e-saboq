import 'package:flutter/material.dart';

/// O'qituvchi ro'yxatlarida qidiruv maydoni.
class TeacherListSearchBar extends StatefulWidget {
  const TeacherListSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  State<TeacherListSearchBar> createState() => _TeacherListSearchBarState();
}

class _TeacherListSearchBarState extends State<TeacherListSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant TeacherListSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hintClr = cs.onSurface.withValues(alpha: isLight ? 0.46 : 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: hintClr,
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: cs.onSurface.withValues(alpha: 0.45)),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Tozalash',
                  icon: Icon(Icons.clear_rounded, color: cs.onSurface.withValues(alpha: 0.45)),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                  },
                )
              : null,
          filled: true,
          fillColor: isLight ? cs.surface : cs.surfaceContainerHighest.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: isLight ? 0.65 : 0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.65), width: 1.6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: isLight ? 0.65 : 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
