import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/username_taken_exception.dart';

/// FirebaseAuth xabarlarini foydalanuvchi tushunadigan matnga aylantiradi.
String mapAuthErrorToMessage(Object error) {
  if (error is UsernameTakenException) {
    return error.toString();
  }
  // FirebaseAuthException FirebaseException dan meros oladi — avval auth xatolarini ajratamiz.
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'configuration-not-found':
        return 'Firebase Authentication loyihada yoqilmagan. '
            'console.firebase.google.com → Authentication → Boshlash, '
            'keyin Sign-in method → Email/Password ni yoqing. '
            'Google Cloud → APIs → Identity Toolkit API yoqilganini tekshiring.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Login yoki parolni xato kiritdingiz';
      case 'email-already-in-use':
        return 'Bu login bilan allaqachon ro‘yxatdan o‘tilgan.';
      case 'weak-password':
        return 'Parol juda kuchsiz.';
      case 'invalid-email':
        return 'Login noto‘g‘ri.';
      case 'network-request-failed':
        return 'Internet aloqasi yo‘q yoki server javob bermadi.';
      default:
        return _fallbackAuthMessage(error);
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
        return 'Firestore ga ulanib bo‘lmadi (tarmoq yoki server). '
            'Internetni tekshiring. Firebase Console → Firestore → '
            'ma’lumotlar bazasi yaratilganini tekshiring.';
      case 'permission-denied':
        return 'Firestore ruxsati yo‘q. Firebase Console → Firestore → Rules: '
            'kirgan foydalanuvchi users va usernames ga yozishi kerak.';
      case 'failed-precondition':
        return 'Firestore sozlamasi to‘liq emas (masalan, indeks kerak).';
      default:
        return error.message?.isNotEmpty == true
            ? error.message!
            : '[${error.plugin}/${error.code}]';
    }
  }
  return error.toString();
}

String _fallbackAuthMessage(FirebaseAuthException error) {
  final m = (error.message ?? '').toLowerCase();
  if (m.contains('credential') &&
      (m.contains('incorrect') ||
          m.contains('malformed') ||
          m.contains('expired'))) {
    return 'Login yoki parolni xato kiritdingiz';
  }
  if (error.message?.isNotEmpty == true) {
    return error.message!;
  }
  return '[${error.code}]';
}
