import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'app_config.dart';

/// Shared Firebase helpers for the active RTDB instance.
class AppFirebase {
  AppFirebase._();

  /// Named app used when platform DEFAULT was initialized from a mismatched
  /// google-services.json and dart-defines target a different project.
  static const String primaryAppName = 'sshPrimary';

  /// Firebase app that best matches [AppConfig.firebaseProjectId].
  static FirebaseApp get app {
    for (final candidate in Firebase.apps) {
      if (candidate.name == primaryAppName) {
        return candidate;
      }
    }
    for (final candidate in Firebase.apps) {
      if (candidate.options.projectId == AppConfig.firebaseProjectId) {
        return candidate;
      }
    }
    return Firebase.app();
  }

  /// RTDB handle pinned to [AppConfig.realtimeDatabaseUrl].
  static FirebaseDatabase get database {
    return FirebaseDatabase.instanceFor(
      app: app,
      databaseURL: AppConfig.realtimeDatabaseUrl,
    );
  }
}
