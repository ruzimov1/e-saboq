import 'informatika_json_presets.dart';

/// Lokal `fayllar/claster/*.json` dagi bitta klaster mavzusi.
class ClusterTemplate {
  const ClusterTemplate({
    this.id,
    required this.mavzuNomi,
    required this.markaziyGoya,
    required this.kalitSozlar,
  });

  final int? id;
  final String mavzuNomi;
  final String markaziyGoya;
  final List<String> kalitSozlar;

  /// `markaziy_goya` bo‘sh bo‘lsa — `mavzu_nomi`.
  String get centerForEditor {
    final g = markaziyGoya.trim();
    if (g.isNotEmpty) {
      return g;
    }
    return mavzuNomi.trim();
  }

  static List<String> _klist(dynamic v) {
    if (v is! List) {
      return const [];
    }
    return v.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
  }

  static String _titleFromMap(Map<String, dynamic> e) {
    for (final k in const ['mavzu_nomi', 'mavzu', 'topic', 'name', 'center']) {
      final t = '${e[k] ?? ''}'.trim();
      if (t.isNotEmpty) {
        return t;
      }
    }
    return '';
  }

  static ClusterTemplate? tryParse(Map<String, dynamic> e) {
    final keys = _klist(e['kalit_sozlar']);
    if (keys.isEmpty) {
      return null;
    }
    final m = _titleFromMap(e);
    final g = '${e['markaziy_goya'] ?? ''}'.trim();
    if (g.isEmpty && m.isEmpty) {
      return null;
    }
    int? id;
    final idRaw = e['id'];
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is num) {
      id = idRaw.toInt();
    }
    return ClusterTemplate(
      id: id,
      mavzuNomi: m,
      markaziyGoya: g,
      kalitSozlar: keys,
    );
  }
}

/// Input va JSON dagi `etalon` matnni solishtirish (o‘qituvchi validatsiya).
bool clusterStringsMatchEtalon(String? user, String etalon) {
  final a = InformatikaJsonPresets.normForClusterCompare(user ?? '');
  final b = InformatikaJsonPresets.normForClusterCompare(etalon);
  return a.isNotEmpty && a == b;
}
