import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// T-sxema stikeri — `id` barqaror (Firestore / draft uchun).
class TSchemaStickerDef {
  const TSchemaStickerDef({
    required this.id,
    required this.text,
    this.isUserAdded = false,
  });

  final String id;
  final String text;
  final bool isUserAdded;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (isUserAdded) 'userAdded': true,
      };

  factory TSchemaStickerDef.fromDynamic(dynamic e) {
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      var id = '${m['id'] ?? ''}'.trim();
      final text = '${m['text'] ?? m['label'] ?? ''}'.trim();
      if (id.isEmpty) {
        id = _uuid.v4();
      }
      final ua = m['userAdded'] == true;
      return TSchemaStickerDef(id: id, text: text, isUserAdded: ua);
    }
    final text = '$e'.trim();
    return TSchemaStickerDef(id: _uuid.v4(), text: text);
  }

  TSchemaStickerDef copyWith({String? id, String? text, bool? isUserAdded}) {
    return TSchemaStickerDef(
      id: id ?? this.id,
      text: text ?? this.text,
      isUserAdded: isUserAdded ?? this.isUserAdded,
    );
  }
}

/// O‘qituvchi `method.config` dan o‘qiladigan interaktiv T-sxema sozlamalari.
class TSchemaMethodConfig {
  const TSchemaMethodConfig({
    required this.center,
    required this.leftTitle,
    required this.rightTitle,
    required this.leftItems,
    required this.rightItems,
    required this.durationMinutes,
    required this.maxUserStickers,
    this.sxemaHelper,
  });

  final String center;
  final String leftTitle;
  final String rightTitle;
  final List<TSchemaStickerDef> leftItems;
  final List<TSchemaStickerDef> rightItems;
  final int durationMinutes;
  final int maxUserStickers;
  final String? sxemaHelper;

  int get totalPresetCount => leftItems.length + rightItems.length;

  /// `tSchemaInteractive == true` yoki strukturalangan ro‘yxatlar bo‘lsa, interaktiv rejim.
  static TSchemaMethodConfig? tryParse(Map<String, dynamic>? config) {
    if (config == null) {
      return null;
    }
    final leftRaw = config['tSchemaLeftItems'] ?? config['tSchemaLeft'];
    final rightRaw = config['tSchemaRightItems'] ?? config['tSchemaRight'];
    final left = <TSchemaStickerDef>[];
    final right = <TSchemaStickerDef>[];
    if (leftRaw is List) {
      for (final e in leftRaw) {
        final d = TSchemaStickerDef.fromDynamic(e).copyWith(isUserAdded: false);
        if (d.text.isNotEmpty) {
          left.add(d);
        }
      }
    }
    if (rightRaw is List) {
      for (final e in rightRaw) {
        final d = TSchemaStickerDef.fromDynamic(e).copyWith(isUserAdded: false);
        if (d.text.isNotEmpty) {
          right.add(d);
        }
      }
    }
    if (left.isEmpty && right.isEmpty) {
      return null;
    }
    var center =
        '${config['tSchemaCenter'] ?? config['problem'] ?? ''}'.trim();
    if (center.isEmpty) {
      center = 'Mavzu';
    }
    final lt =
        '${config['tSchemaLeftTitle'] ?? 'Afzalliklar'}'.trim().ifEmptyThen('Afzalliklar');
    final rt =
        '${config['tSchemaRightTitle'] ?? 'Kamchiliklar'}'.trim().ifEmptyThen('Kamchiliklar');
    final dm = (config['tSchemaDurationMinutes'] as num?)?.toInt() ??
        (config['tSchemaDuration'] as num?)?.toInt() ??
        15;
    final mu = (config['tSchemaMaxUserStickers'] as num?)?.toInt() ?? 3;
    final sx = '${config['sxema'] ?? ''}'.trim();

    return TSchemaMethodConfig(
      center: center,
      leftTitle: lt,
      rightTitle: rt,
      leftItems: left,
      rightItems: right,
      durationMinutes: dm.clamp(0, 120),
      maxUserStickers: mu.clamp(0, 20),
      sxemaHelper: sx.isEmpty ? null : sx,
    );
  }
}

extension _TSchemaStringExt on String {
  String ifEmptyThen(String fallback) => trim().isEmpty ? fallback : trim();
}
