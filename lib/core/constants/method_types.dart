/// Interaktiv metod turlari (Firestore `methods.type` bilan mos).
enum MethodType {
  quiz,
  brainstorm,
  caseStudy,
  rolePlay,
  fishbone,
  poll,
  groupWork,
}

extension MethodTypeX on MethodType {
  String get firestoreValue {
    switch (this) {
      case MethodType.quiz:
        return 'quiz';
      case MethodType.poll:
        return 'poll';
      case MethodType.brainstorm:
        return 'brainstorm';
      case MethodType.caseStudy:
        return 'case';
      case MethodType.groupWork:
        return 'group';
      case MethodType.rolePlay:
        return 'role_play';
      case MethodType.fishbone:
        return 'fishbone';
    }
  }
}

MethodType? methodTypeFromFirestore(String? value) {
  switch (value) {
    case 'quiz':
      return MethodType.quiz;
    case 'poll':
      return MethodType.poll;
    case 'brainstorm':
      return MethodType.brainstorm;
    case 'case':
      return MethodType.caseStudy;
    case 'group':
      return MethodType.groupWork;
    case 'role_play':
      return MethodType.rolePlay;
    case 'fishbone':
      return MethodType.fishbone;
    default:
      return null;
  }
}
