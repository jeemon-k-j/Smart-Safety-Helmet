import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'auth_user.dart';

/// In-app auth used when Firebase credentials are not configured.
///
/// Accounts are stored only on-device for UI/dev continuity. This is not a
/// production identity provider.
class LocalAuthService implements AuthService {
  LocalAuthService({required SharedPreferences preferences})
      : _preferences = preferences {
    final raw = _preferences.getString(_sessionKey);
    if (raw != null && raw.isNotEmpty) {
      final map = jsonDecode(raw);
      if (map is Map) {
        final uid = map['uid']?.toString();
        final email = map['email']?.toString();
        if (uid != null && email != null) {
          _current = AuthUser(uid: uid, email: email);
        }
      }
    }
    _controller.add(_current);
  }

  static const String _sessionKey = 'ssh.localAuth.session.v1';
  static const String _usersKey = 'ssh.localAuth.users.v1';

  final SharedPreferences _preferences;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _current;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final users = _readUsers();
    final normalized = email.trim().toLowerCase();
    final stored = users[normalized];
    if (stored == null || stored != password) {
      throw StateError('Invalid email or password.');
    }
    await _setSession(AuthUser(uid: 'local:${normalized.hashCode}', email: email.trim()));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final users = _readUsers();
    final normalized = email.trim().toLowerCase();
    if (users.containsKey(normalized)) {
      throw StateError('An account with this email already exists.');
    }
    users[normalized] = password;
    await _preferences.setString(_usersKey, jsonEncode(users));
    await _setSession(AuthUser(uid: 'local:${normalized.hashCode}', email: email.trim()));
  }

  @override
  Future<void> signOut() async {
    _current = null;
    await _preferences.remove(_sessionKey);
    _controller.add(null);
  }

  Future<void> _setSession(AuthUser user) async {
    _current = user;
    await _preferences.setString(
      _sessionKey,
      jsonEncode(<String, String>{'uid': user.uid, 'email': user.email}),
    );
    _controller.add(user);
  }

  Map<String, String> _readUsers() {
    final raw = _preferences.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, String>{};
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
