import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'config/app_config.dart';
import 'config/app_firebase.dart';

/// Result of optional Firebase startup.
class BootstrapResult {
  const BootstrapResult({required this.firebaseReady});

  final bool firebaseReady;
}

/// Initializes Firebase from dart-defines and/or platform config files.
///
/// Does not create projects, enable APIs, or invent keys. RTDB access uses
/// [AppConfig.realtimeDatabaseUrl] via repository helpers.
Future<BootstrapResult> bootstrapFirebase() async {
  try {
    final options = AppConfig.firebaseOptionsOrNull;

    if (Firebase.apps.isEmpty) {
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
      return const BootstrapResult(firebaseReady: true);
    }

    // Platform google-services.json may have already created DEFAULT.
    // If dart-defines target a different project, attach a named app.
    if (options != null &&
        Firebase.app().options.projectId != options.projectId) {
      final hasPrimary = Firebase.apps.any(
        (app) => app.name == AppFirebase.primaryAppName,
      );
      if (!hasPrimary) {
        try {
          await Firebase.initializeApp(
            name: AppFirebase.primaryAppName,
            options: options,
          );
        } catch (error) {
          debugPrint(
            'Could not create ${AppFirebase.primaryAppName} for '
            '${options.projectId}; using DEFAULT app with RTDB URL override. '
            'Replace android/app/google-services.json if it is stale. ($error)',
          );
        }
      }
    }

    return const BootstrapResult(firebaseReady: true);
  } on FirebaseException catch (error, stack) {
    if (_isDuplicateApp(error) && Firebase.apps.isNotEmpty) {
      return const BootstrapResult(firebaseReady: true);
    }
    debugPrint('Firebase.initializeApp failed; falling back to local data.');
    debugPrint('$error');
    debugPrint('$stack');
    return const BootstrapResult(firebaseReady: false);
  } catch (error, stack) {
    if (Firebase.apps.isNotEmpty) {
      return const BootstrapResult(firebaseReady: true);
    }
    if (!AppConfig.hasFirebaseConfig) {
      debugPrint(
        'Firebase credentials missing; using local repositories until '
        'dart-defines / google-services are available.',
      );
      return const BootstrapResult(firebaseReady: false);
    }
    debugPrint('Firebase.initializeApp failed; falling back to local data.');
    debugPrint('$error');
    debugPrint('$stack');
    return const BootstrapResult(firebaseReady: false);
  }
}

bool _isDuplicateApp(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('duplicate-app') || text.contains('already exists');
}
