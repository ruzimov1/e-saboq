/// Firebase `initializeApp` chaqirilmagan yoki `firebase_options.dart` stub bo‘lganda.
class FirebaseNotConfiguredException implements Exception {
  const FirebaseNotConfiguredException();

  static const String userMessage = 'Firebase ulangan emas.\n\n'
      'Loyiha ildizida terminalda ketma-ket bajaring:\n'
      '  dart pub global activate flutterfire_cli\n'
      '  flutterfire configure\n\n'
      'Firebase Console’da loyiha yarating, platformalar (Web, Android, iOS, Windows) '
      'ulanishi kerak. So‘ng `lib/firebase_options.dart` (FlutterFire) yangilanadi va '
      'ilovani qayta ishga tushiring.';

  @override
  String toString() => userMessage;
}
