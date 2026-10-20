/// App-level signed-in user (Firebase or local).
class AuthUser {
  const AuthUser({required this.uid, required this.email});

  final String uid;
  final String email;
}
