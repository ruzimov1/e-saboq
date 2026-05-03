import 'package:flutter/material.dart';

import '../../../../core/curriculum/cluster_json_service.dart';
import '../../../../core/curriculum/cluster_template.dart';
import '../../../../core/curriculum/informatika_json_presets.dart';

/// «Tayyor fayldan olish» — sinf + mavzu + ixtiyoriy chalg'ituvchilar.
class ClusterTemplatePickerResult {
  const ClusterTemplatePickerResult({
    required this.template,
    required this.pickerKey,
    required this.templatesInSameFile,
    this.umbrellaGoya,
    this.addDistractors = false,
  });

  final ClusterTemplate template;
  final String pickerKey;
  final List<ClusterTemplate> templatesInSameFile;
  final String? umbrellaGoya;
  final bool addDistractors;
}

Future<ClusterTemplatePickerResult?> showClusterTemplatePickerSheet(
  BuildContext context, {
  String? initialPickerKey,
}) {
  final c = Theme.of(context).colorScheme;
  return showModalBottomSheet<ClusterTemplatePickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.surfaceContainerHighest.withValues(alpha: 0.95),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _ClusterTemplatePickerBody(
        initialPickerKey: initialPickerKey,
        primary: c.primary,
        onSurfaceVariant: c.onSurfaceVariant,
      );
    },
  );
}

class _ClusterTemplatePickerBody extends StatefulWidget {
  const _ClusterTemplatePickerBody({
    this.initialPickerKey,
    required this.primary,
    required this.onSurfaceVariant,
  });

  final String? initialPickerKey;
  final Color primary;
  final Color onSurfaceVariant;

  @override
  State<_ClusterTemplatePickerBody> createState() =>
      _ClusterTemplatePickerBodyState();
}

class _ClusterTemplatePickerBodyState extends State<_ClusterTemplatePickerBody> {
  late String _pickerKey;
  bool _addDistractors = false;
  ClusterTemplate? _selected;
  bool _busy = false; // qisqa yuklanish (sinf o‘zgarishi) animatsiyasi

  @override
  void initState() {
    super.initState();
    _pickerKey = widget.initialPickerKey ?? ClusterJsonService.pickerClassKeys.first;
  }

  List<ClusterTemplate> get _list =>
      ClusterJsonService.templatesForPickerKey(_pickerKey);

  void _onApply() {
    final t = _selected;
    if (t == null) {
      return;
    }
    final all = _list;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      ClusterTemplatePickerResult(
        template: t,
        pickerKey: _pickerKey,
        templatesInSameFile: all,
        umbrellaGoya: ClusterJsonService.umbrellaGoyaForPickerKey(_pickerKey),
        addDistractors: _addDistractors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    if (!InformatikaJsonPresets.isReady) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: widget.primary,
                  strokeWidth: 2.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Informatika JSON shablonlari yuklanmoqda…',
                style: th.textTheme.bodyMedium?.copyWith(
                  color: widget.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.cloud_download, color: widget.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tayyor fayldan olish (JSON)',
                      style: th.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: th.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Yopish',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sinfni tanlang, so‘ng mavzuni — markaziy tushuncha va tarmoqlar '
                'JSON bo‘yicha to‘ldiriladi.',
                style: th.textTheme.bodySmall?.copyWith(
                  color: widget.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sinf',
                    style: th.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _pickerKey,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          for (final k in ClusterJsonService.pickerClassKeys)
                            DropdownMenuItem(
                              value: k,
                              child: Text(ClusterJsonService.labelForPickerKey(k)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) {
                            return;
                          }
                          setState(() {
                            _pickerKey = v;
                            _selected = null;
                            _busy = true;
                          });
                          Future<void>.delayed(const Duration(milliseconds: 120), () {
                            if (mounted) {
                              setState(() => _busy = false);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy)
              SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: widget.primary,
                      strokeWidth: 2.4,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CheckboxListTile(
                  value: _addDistractors,
                  onChanged: (v) =>
                      setState(() => _addDistractors = v ?? false),
                  title: const Text("Chalg'ituvchilarni avto-taklif (2–3 ta)"),
                  subtitle: const Text(
                    "JSONda alohida bo‘lmasa, boshqa mavzulardan va statik ro‘yxatdan to‘ldiradi.",
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: _list.isEmpty
                    ? Center(
                        child: Text(
                          'Ushbu sinf faylida shablonlar topilmadi.',
                          style: th.textTheme.bodyMedium?.copyWith(
                            color: widget.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        itemCount: _list.length,
                        itemBuilder: (c, i) {
                          final t = _list[i];
                          final sel = _selected;
                          final isSel = sel != null &&
                              (sel.id != null && t.id != null
                                  ? sel.id == t.id
                                  : sel.mavzuNomi == t.mavzuNomi &&
                                      sel.centerForEditor == t.centerForEditor);
                          return Card(
                            color: isSel
                                ? widget.primary.withValues(alpha: 0.12)
                                : th.colorScheme.surface,
                            child: ListTile(
                              onTap: () {
                                setState(() => _selected = t);
                              },
                              title: Text(
                                t.mavzuNomi.isNotEmpty
                                    ? t.mavzuNomi
                                    : t.centerForEditor,
                                style: th.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  t.centerForEditor,
                                  'Kalit: ${t.kalitSozlar.length} ta',
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isSel
                                  ? Icon(Icons.check_circle, color: widget.primary)
                                  : const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: FilledButton.icon(
                  onPressed: _selected == null ? null : _onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.download_done, size: 22),
                  label: const Text("Shablonni maydonga o‘tkazish"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
