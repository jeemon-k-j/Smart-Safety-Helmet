import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Build-time configuration. Secrets are never hardcoded — inject via:
///
///   flutter run --dart-define-from-file=dart_defines.json
///
/// See `dart_defines.example.json` and `docs/CREDENTIALS.md`.
class AppConfig {
  AppConfig._();

  static const String defaultDeviceId = String.fromEnvironment(
    'DEVICE_ID',
    defaultValue: 'helmet-001',
  );

  /// Local SMTP bridge URL (DeepCrash approach). The app never holds SMTP
  /// passwords; those live only in `local-email-bridge/.env`.
  static const String emailBridgeUrl = String.fromEnvironment(
    'EMAIL_BRIDGE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Active Firebase / RTDB project identifiers.
  static const String firebaseProjectIdDefault = 'smart-safety-helmet-93f6d';
  static const String realtimeDatabaseUrlDefault =
      'https://smart-safety-helmet-93f6d-default-rtdb.firebaseio.com/';

  // --- Firebase (inject via dart-defines; see dart_defines.example.json) ---

  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: firebaseProjectIdDefault,
  );
  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: realtimeDatabaseUrlDefault,
  );
  static const String firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.cynosylix.smartSafetyHelmet',
  );

  /// Normalized RTDB URL used by repositories and connectivity checks.
  static String get realtimeDatabaseUrl {
    final raw = firebaseDatabaseUrl.trim();
    if (raw.isEmpty) {
      return realtimeDatabaseUrlDefault;
    }
    return raw.endsWith('/') ? raw : '$raw/';
  }

  /// True only when the minimum Firebase client credentials are present.
  static bool get hasFirebaseConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      realtimeDatabaseUrl.isNotEmpty;

  static FirebaseOptions? get firebaseOptionsOrNull {
    if (!hasFirebaseConfig) {
      return null;
    }
    return FirebaseOptions(
      apiKey: firebaseApiKey,
      appId: firebaseAppId,
      messagingSenderId: firebaseMessagingSenderId,
      projectId: firebaseProjectId,
      databaseURL: realtimeDatabaseUrl,
      storageBucket:
          firebaseStorageBucket.isEmpty ? null : firebaseStorageBucket,
      authDomain: firebaseAuthDomain.isEmpty ? null : firebaseAuthDomain,
      iosBundleId: _iosBundleIdIfNeeded,
    );
  }

  static String? get _iosBundleIdIfNeeded {
    if (kIsWeb) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return firebaseIosBundleId;
    }
    return null;
  }
}
