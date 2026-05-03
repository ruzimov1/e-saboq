/// JSON `topics[]`dagi bitta mavzu: nom va 5 (yoki boshqa son) savol.
class BrainstormTopicModel {
  const BrainstormTopicModel({
    required this.index,
    required this.name,
    required this.questions,
  });

  final int index;
  final String name;
  final List<String> questions;
}

/// Sinf (5–7 vs 8–11) bo‘yicha UI farqi.
enum BrainstormGradeBand {
  /// 5–7: sodda, vizual
  lower,

  /// 8–11: professional
  upper,
}

BrainstormGradeBand brainstormBandForClassId(String classId) {
  final m = RegExp(r'\d+').firstMatch(classId);
  final n = int.tryParse(m?.group(0) ?? '') ?? 5;
  if (n >= 5 && n <= 7) {
    return BrainstormGradeBand.lower;
  }
  return BrainstormGradeBand.upper;
}
