// Firebase options are supplied only through dart-defines (see AppConfig).
// This file remains so older imports resolve; it does not embed client secrets.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'app_config.dart';

/// Prefer [AppConfig.firebaseOptionsOrNull]. Returns null when credentials are
/// not configured — callers must not invent placeholder keys.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions? get currentPlatformOrNull =>
      AppConfig.firebaseOptionsOrNull;

  /// Throws if credentials are missing. Prefer [currentPlatformOrNull].
  static FirebaseOptions get currentPlatform {
    final options = currentPlatformOrNull;
    if (options == null) {
      throw StateError(
        'Firebase credentials are not configured. '
        'Provide dart-defines (see docs/CREDENTIALS.md) or run without Firebase '
        'using the local data layer.',
      );
    }
    return options;
  }
}
