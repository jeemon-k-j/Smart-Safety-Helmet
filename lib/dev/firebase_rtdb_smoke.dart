import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../bootstrap.dart';
import '../config/app_config.dart';
import '../config/app_firebase.dart';

/// One-shot Android check for Firebase init + RTDB read.
///
///   flutter run -d emulator-5554 -t lib/dev/firebase_rtdb_smoke.dart \
///     --dart-define-from-file=dart_defines.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await bootstrapFirebase();
  final active = Firebase.apps.isEmpty ? null : AppFirebase.app.options;
  // ignore: avoid_print
  print(
    'FIREBASE_SMOKE init firebaseReady=${bootstrap.firebaseReady} '
    'apps=${Firebase.apps.length} '
    'expectedProject=${AppConfig.firebaseProjectId} '
    'expectedAppId=${AppConfig.firebaseAppId} '
    'activeProject=${active?.projectId} '
    'activeAppId=${active?.appId} '
    'databaseUrl=${AppConfig.realtimeDatabaseUrl} '
    'deviceId=${AppConfig.defaultDeviceId}',
  );

  if (!bootstrap.firebaseReady) {
    // ignore: avoid_print
    print('FIREBASE_SMOKE failed: Firebase did not initialize');
    return;
  }

  final path = 'devices/${AppConfig.defaultDeviceId}/status';
  final auth = FirebaseAuth.instance;

  try {
    final snapshot = await AppFirebase.database.ref(path).get();
    // ignore: avoid_print
    print(
      'FIREBASE_SMOKE read_ok path=$path '
      'exists=${snapshot.exists} value=${snapshot.value} '
      'authUid=${auth.currentUser?.uid ?? 'signed-out'}',
    );
  } on FirebaseException catch (error) {
    // ignore: avoid_print
    print(
      'FIREBASE_SMOKE read_denied path=$path '
      'code=${error.code} message=${error.message} '
      'authUid=${auth.currentUser?.uid ?? 'signed-out'}',
    );
  } catch (error) {
    // ignore: avoid_print
    print('FIREBASE_SMOKE read_failed path=$path error=$error');
  }
}
