import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// `users/{uid}` hujjatini kuzatish (maydonlar ixtiyoriy to'ldiriladi).
  Stream<UserProfile?> watchProfile(String uid) {
    if (!_hasFirebase || uid.isEmpty) {
      return Stream.value(null);
    }
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfile.fromMap(snap.data()!, uid);
    });
  }

  /// Profil maydonlarini yangilash (merge).
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? email,
    String? phone,
    String? organization,
  }) async {
    if (!_hasFirebase || uid.isEmpty) return;
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name.trim();
    if (email != null) map['email'] = email.trim().isEmpty ? null : email.trim();
    if (phone != null) map['phone'] = phone.trim().isEmpty ? null : phone.trim();
    if (organization != null) {
      map['organization'] =
          organization.trim().isEmpty ? null : organization.trim();
    }
    map.removeWhere((k, v) => v == null);
    if (map.isEmpty) return;
    await _db.collection('users').doc(uid).set(map, SetOptions(merge: true));
  }
}
