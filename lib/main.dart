import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'bootstrap.dart';
import 'dev/ui_sample_data.dart';
import 'services/accident/pending_notification_store.dart';
import 'services/notifications/recording_emergency_notification_service.dart';

/// When true, emergency dispatches are recorded in-memory (no SMTP / bridge).
const bool _recordNotifications =
    bool.fromEnvironment('RECORD_NOTIFICATIONS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await bootstrapFirebase();
  final prefs = await SharedPreferences.getInstance();
  final pendingStore = SharedPreferencesPendingNotificationStore(
    preferences: prefs,
  );
  final dependencies = await AppDependencies.create(
    firebaseReady: bootstrap.firebaseReady,
    preferences: prefs,
    pendingStore: pendingStore,
    notifications: UiSampleData.notificationOverride() ??
        (_recordNotifications
            ? RecordingEmergencyNotificationService()
            : null),
  );
  await UiSampleData.apply(dependencies);
  await _integrationAutoLogin(dependencies);

  runApp(SmartSafetyHelmetApp(dependencies: dependencies));
}

/// Optional integration-only sign-in via dart-defines (no UI typing).
Future<void> _integrationAutoLogin(AppDependencies dependencies) async {
  const email = String.fromEnvironment('INTEGRATION_EMAIL');
  const password = String.fromEnvironment('INTEGRATION_PASSWORD');
  if (email.isEmpty || password.isEmpty) {
    return;
  }
  try {
    await dependencies.authService.register(email: email, password: password);
  } catch (_) {
    await dependencies.authService.signIn(email: email, password: password);
  }
}
