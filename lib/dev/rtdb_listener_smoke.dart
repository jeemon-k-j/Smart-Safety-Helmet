import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../bootstrap.dart';
import '../config/app_config.dart';
import '../config/app_firebase.dart';
import '../models/accident_event.dart';
import '../models/device_status.dart';
import '../repositories/firebase_accident_repository.dart';
import '../repositories/firebase_device_repository.dart';

/// Watches live RTDB status/accident for a short window (no UI).
///
///   flutter run -d emulator-5554 -t lib/dev/rtdb_listener_smoke.dart \
///     --dart-define-from-file=dart_defines.json \
///     --dart-define=INTEGRATION_EMAIL=... \
///     --dart-define=INTEGRATION_PASSWORD=...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await bootstrapFirebase();
  // ignore: avoid_print
  print(
    'RTDB_LISTEN init firebaseReady=${bootstrap.firebaseReady} '
    'project=${AppConfig.firebaseProjectId} '
    'url=${AppConfig.realtimeDatabaseUrl}',
  );
  if (!bootstrap.firebaseReady) {
    // ignore: avoid_print
    print('RTDB_LISTEN failed: firebase not ready');
    return;
  }

  const email = String.fromEnvironment('INTEGRATION_EMAIL');
  const password = String.fromEnvironment('INTEGRATION_PASSWORD');
  if (email.isNotEmpty && password.isNotEmpty) {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // ignore: avoid_print
      print('RTDB_LISTEN auth registered');
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // ignore: avoid_print
        print('RTDB_LISTEN auth signed-in');
      } else {
        // ignore: avoid_print
        print('RTDB_LISTEN auth_error code=${error.code} ${error.message}');
      }
    }
  }

  final deviceId = AppConfig.defaultDeviceId;
  final devices = FirebaseDeviceRepository(
    deviceId: deviceId,
    database: AppFirebase.database,
  );
  final accidents = FirebaseAccidentRepository(
    deviceId: deviceId,
    database: AppFirebase.database,
  );

  // ignore: avoid_print
  print('RTDB_LISTEN watching devices/$deviceId/status and accident');

  final statusSub = devices.watchStatus().listen((DeviceStatus status) {
    // ignore: avoid_print
    print(
      'RTDB_LISTEN status available=${status.isAvailable} '
      'alcohol=${status.alcoholDetected} helmet=${status.helmetClipped} '
      'ignitionAllowed=${status.ignitionAllowed} '
      'ignitionActive=${status.ignitionActive} '
      'drowsy=${status.drowsy} warning=${status.warningActive}',
    );
  });
  final accidentSub = accidents.watchAccident().listen((AccidentEvent event) {
    // ignore: avoid_print
    print(
      'RTDB_LISTEN accident eventId=${event.eventId} active=${event.active} '
      'severity=${event.severity.name} cancelled=${event.cancelled} '
      'sent=${event.notificationSent}',
    );
  });

  await Future<void>.delayed(const Duration(seconds: 45));
  await statusSub.cancel();
  await accidentSub.cancel();
  // ignore: avoid_print
  print('RTDB_LISTEN done');
}
