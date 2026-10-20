import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/firebase_options.dart';
import 'services/accident/pending_notification_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final pendingStore = SharedPreferencesPendingNotificationStore(
    preferences: prefs,
  );

  runApp(SmartSafetyHelmetApp(pendingStore: pendingStore));
}
