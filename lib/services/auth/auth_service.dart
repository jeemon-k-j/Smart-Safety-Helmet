import 'auth_user.dart';

/// Authentication for emergency-contact and device data access.
abstract class AuthService {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> signOut();
}
