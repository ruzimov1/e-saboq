import 'informatika_json_presets.dart';
import 'cluster_template.dart';

/// `fayllar/claster/{n}_sinf_cluster*.json` — sinf bo‘yicha shablonlar.
///
/// Fayl nomlari `InformatikaJsonPresets` ichidagi `cl_*` kalitlar orqali
/// ulangan (masalan, 5-sinf: `5_sinf_cluster_fixed.json`).
abstract final class ClusterJsonService {
  static const List<String> pickerClassKeys = [
    '5',
    '6',
    '7',
    '8',
    '9',
    '10_11',
  ];

  /// Modal / dropdown uchun: `5` → `5-sinf`, `10_11` → `10-sinf`.
  static String classIdForPickerKey(String key) {
    if (key == '10_11') {
      return '10-sinf';
    }
    return '$key-sinf';
  }

  static String labelForPickerKey(String key) {
    if (key == '10_11') {
      return '10–11-sinf';
    }
    return '$key-sinf';
  }

  /// Tanlangan sinf bo‘yicha barcha klaster mavzulari.
  static List<ClusterTemplate> templatesForPickerKey(String pickerKey) {
    final classId = classIdForPickerKey(pickerKey);
    final rows = InformatikaJsonPresets.clusterFileTopicRowsForClass(classId);
    return rows.map(ClusterTemplate.tryParse).whereType<ClusterTemplate>().toList();
  }

  static String? umbrellaGoyaForPickerKey(String pickerKey) {
    return InformatikaJsonPresets.clusterFileUmbrellaGoya(
      classIdForPickerKey(pickerKey),
    );
  }
}
