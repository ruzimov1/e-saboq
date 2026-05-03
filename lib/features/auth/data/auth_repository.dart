import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/errors/firebase_not_configured_exception.dart';
import '../../../core/errors/username_taken_exception.dart';
import 'auth_model.dart';
import 'auth_username.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _authOverride = firebaseAuth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth {
    if (!_hasFirebase) {
      throw StateError(
        'Firebase sozlanmagan: `flutterfire configure` va `Firebase.initializeApp`',
      );
    }
    return _authOverride ?? FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    if (!_hasFirebase) {
      throw StateError(
        'Firebase sozlanmagan: `flutterfire configure` va `Firebase.initializeApp`',
      );
    }
    return _firestoreOverride ?? FirebaseFirestore.instance;
  }

  AuthUser _userFromFirebase(User u, {String? role}) {
    return AuthUser(
      id: u.uid,
      username: usernameFromAuthEmail(u.email),
      name: u.displayName,
      role: role,
    );
  }

  Stream<User?> get authStateChanges =>
      _hasFirebase ? _auth.authStateChanges() : const Stream<User?>.empty();

  AuthUser? get currentAuthUser {
    if (!_hasFirebase) return null;
    final u = _auth.currentUser;
    if (u == null) return null;
    return _userFromFirebase(u);
  }

  Future<AuthUser> _hydrateUser(User u) async {
    try {
      final doc = await _firestore.collection('users').doc(u.uid).get();
      final d = doc.data();
      return AuthUser(
        id: u.uid,
        username: usernameFromAuthEmail(u.email),
        name: (d?['name'] as String?) ?? u.displayName,
        role: d?['role'] as String?,
      );
    } catch (_) {
      return _userFromFirebase(u);
    }
  }

  Future<AuthUser> signInWithUsername({
    required String username,
    required String password,
  }) async {
    if (!_hasFirebase) {
      throw const FirebaseNotConfiguredException();
    }
    final email = authEmailFromUsername(username);
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _hydrateUser(cred.user!);
  }

  Future<AuthUser> registerWithUsername({
    required String username,
    required String password,
    required String name,
    required String role,
  }) async {
    if (!_hasFirebase) {
      throw const FirebaseNotConfiguredException();
    }
    final norm = normalizeUsername(username);
    final email = authEmailFromUsername(username);

    // Avval Auth — Firestore o'qimaymiz (qoidalar anonim o'qishni taqiqlashi mumkin).
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final u = cred.user!;
    await u.updateDisplayName(name);

    try {
      await _firestore.runTransaction((tx) async {
        final unameRef = _firestore.collection('usernames').doc(norm);
        final unameSnap = await tx.get(unameRef);
        if (unameSnap.exists) {
          final existing = unameSnap.data()?['uid'] as String?;
          if (existing != null && existing != u.uid) {
            throw const UsernameTakenException();
          }
        }
        tx.set(
          _firestore.collection('users').doc(u.uid),
          {
            'name': name.trim(),
            'username': norm,
            'role': role,
          },
        );
        tx.set(unameRef, {'uid': u.uid});
      });
    } catch (_) {
      await u.delete();
      rethrow;
    }

    return AuthUser(
      id: u.uid,
      username: norm,
      name: name.trim(),
      role: role,
    );
  }

  Future<void> signOut() async {
    if (!_hasFirebase) return;
    await _auth.signOut();
  }

  /// Firebase `sendPasswordResetEmail` — login `@eduinteractive.auth` manziliga.
  Future<void> sendPasswordResetEmail(String username) async {
    if (!_hasFirebase) {
      throw const FirebaseNotConfiguredException();
    }
    final email = authEmailFromUsername(username);
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Firebase Auth `displayName` (profil ismi bilan sinxron).
  Future<void> updateDisplayName(String name) async {
    if (!_hasFirebase) return;
    final u = _auth.currentUser;
    if (u == null) return;
    final t = name.trim();
    if (t.isEmpty) return;
    await u.updateDisplayName(t);
  }
}
