import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// FlutterFire CLI `lib/firebase_options.dart` faylini yaratadi / yangilaydi.
Future<void> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      try {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Firebase Crashlytics: $e');
        }
      }
    }
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Analytics: $e');
      }
    }
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firestore settings: $e');
      }
    }
    if (kDebugMode) {
      debugPrint('Firebase: initializeApp muvaffaqiyatli.');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firebase: xato — $e\n$st');
    }
  }
}
