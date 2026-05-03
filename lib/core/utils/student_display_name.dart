import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firestore `users/{uid}` → o‘qituvchiga qulay sarlavha.
abstract final class StudentDisplayNameResolver {
  static final Map<String, String> _cache = {};

  static void clearCache() => _cache.clear();

  static Future<String> forUid(String uid) async {
    if (Firebase.apps.isNotEmpty && _cache.containsKey(uid)) {
      return _cache[uid]!;
    }
    if (Firebase.apps.isEmpty) {
      return uid;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists) {
      _cache[uid] = uid;
      return uid;
    }
    final d = snap.data() ?? {};
    final name = (d['name'] as String?)?.trim() ?? '';
    final un = (d['username'] as String?)?.trim() ?? '';
    String label;
    if (name.isNotEmpty) {
      label = un.isNotEmpty ? '$name · @$un' : name;
    } else if (un.isNotEmpty) {
      label = '@$un';
    } else {
      label = uid;
    }
    _cache[uid] = label;
    return label;
  }

  static Future<Map<String, String>> forUids(Iterable<String> uids) async {
    final out = <String, String>{};
    final need = uids.toSet()..removeWhere((u) => u.isEmpty);
    for (final u in need) {
      out[u] = await forUid(u);
    }
    return out;
  }
}
