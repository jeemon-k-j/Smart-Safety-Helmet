import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_service.dart';
import 'auth_user.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(uid: user.uid, email: user.email ?? '');
  }
}
