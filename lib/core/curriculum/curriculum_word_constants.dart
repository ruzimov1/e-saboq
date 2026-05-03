/// Word/JSON manbasi: [assets/fayllar] (asosiy) va loyiha ildizidagi [fayllar] (zaxira).
abstract final class CurriculumWordConstants {
  static const topicToken = '{topic}';
  static const subjectToken = '{subject}';

  static const informatikaAssignmentsAssetPath =
      'assets/fayllar/informatika_method_assignments.json';
  static const informatikaQuizMethodAssetPath =
      'assets/fayllar/informatika_quiz_presets.json';
  static const informatikaFishboneMethodAssetPath =
      'assets/fayllar/informatika_fishbone_klaster_sxema_presets.json';

  /// Veb/embadded manifest ba’zida [assets/fayllar/] yoki [fayllar/] bo‘yicha qidiradi.
  static List<String> methodAssetPathVariants(String path) {
    if (path.startsWith('assets/fayllar/')) {
      return <String>[path, path.substring(7)];
    }
    if (path.startsWith('fayllar/')) {
      return <String>['assets/$path', path];
    }
    return <String>[path];
  }
}
