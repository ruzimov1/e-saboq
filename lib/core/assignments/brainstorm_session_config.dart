/// Aqliy hujum topshirig‘i: vaqt, g‘oyalar chegarasi, anonimlik (sinfdoshlar oldida).
class BrainstormSessionConfig {
  const BrainstormSessionConfig({
    required this.durationMinutes,
    required this.minIdeasPerStudent,
    required this.maxIdeasPerStudent,
    required this.isAnonymous,
  });

  final int durationMinutes;
  final int minIdeasPerStudent;
  final int maxIdeasPerStudent;
  final bool isAnonymous;

  static const BrainstormSessionConfig fallback = BrainstormSessionConfig(
    durationMinutes: 5,
    minIdeasPerStudent: 1,
    maxIdeasPerStudent: 8,
    isAnonymous: false,
  );

  /// `assignments/{id}` hujjati: `brainstormSession` yoki (eski) bo‘lmasa — default.
  static BrainstormSessionConfig fromAssignmentData(
    Map<String, dynamic> data,
  ) {
    final raw = data['brainstormSession'];
    if (raw is! Map) {
      return fallback;
    }
    final m = Map<String, dynamic>.from(raw);
    int iv(dynamic v, int d) {
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return d;
    }
    var d = iv(
      m['durationMinutes'] ?? m['durationInMinutes'],
      fallback.durationMinutes,
    );
    if (d < 0) {
      d = 0;
    } else if (d > 120) {
      d = 120;
    }
    var minI = iv(
      m['minIdeasPerStudent'] ?? m['minIdeas'],
      fallback.minIdeasPerStudent,
    );
    if (minI < 1) {
      minI = 1;
    } else if (minI > 30) {
      minI = 30;
    }
    var maxI = iv(
      m['maxIdeasPerStudent'] ?? m['maxIdeas'],
      fallback.maxIdeasPerStudent,
    );
    if (maxI < 1) {
      maxI = 1;
    } else if (maxI > 30) {
      maxI = 30;
    }
    if (maxI < minI) {
      maxI = minI;
    }
    return BrainstormSessionConfig(
      durationMinutes: d,
      minIdeasPerStudent: minI,
      maxIdeasPerStudent: maxI,
      isAnonymous: m['isAnonymous'] as bool? ?? false,
    );
  }

  /// Saqlash uchun Firestore-ga mos `Map` (boshqich: `set` / `update`).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'durationMinutes': durationMinutes,
      'minIdeasPerStudent': minIdeasPerStudent,
      'maxIdeasPerStudent': maxIdeasPerStudent,
      'isAnonymous': isAnonymous,
    };
  }
}
