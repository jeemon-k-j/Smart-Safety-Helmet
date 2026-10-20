import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'config/app_config.dart';

/// Result of optional Firebase startup.
class BootstrapResult {
  const BootstrapResult({required this.firebaseReady});

  final bool firebaseReady;
}

/// Initializes Firebase only when client credentials are present.
///
/// Does not create projects, enable APIs, or invent keys.
Future<BootstrapResult> bootstrapFirebase() async {
  if (!AppConfig.hasFirebaseConfig) {
    debugPrint(
      'Firebase dart-defines missing; using local repositories until credentials arrive.',
    );
    return const BootstrapResult(firebaseReady: false);
  }

  final options = AppConfig.firebaseOptionsOrNull;
  if (options == null) {
    return const BootstrapResult(firebaseReady: false);
  }

  try {
    await Firebase.initializeApp(options: options);
    return const BootstrapResult(firebaseReady: true);
  } catch (error, stack) {
    debugPrint('Firebase.initializeApp failed; falling back to local data.');
    debugPrint('$error');
    debugPrint('$stack');
    return const BootstrapResult(firebaseReady: false);
  }
}
