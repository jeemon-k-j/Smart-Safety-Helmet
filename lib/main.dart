import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'bootstrap.dart';
import 'dev/ui_sample_data.dart';
import 'services/accident/pending_notification_store.dart';

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
    notifications: UiSampleData.notificationOverride(),
  );
  await UiSampleData.apply(dependencies);

  runApp(SmartSafetyHelmetApp(dependencies: dependencies));
}
