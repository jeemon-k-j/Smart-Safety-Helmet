import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_safety_helmet/app.dart';
import 'package:smart_safety_helmet/app_dependencies.dart';
import 'package:smart_safety_helmet/services/accident/pending_notification_store.dart';
import 'package:smart_safety_helmet/services/notifications/recording_emergency_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login UI loads with local dependencies', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final deps = await AppDependencies.create(
      firebaseReady: false,
      preferences: prefs,
      pendingStore: MemoryPendingNotificationStore(),
      notifications: RecordingEmergencyNotificationService(),
    );

    await tester.pumpWidget(SmartSafetyHelmetApp(dependencies: deps));
    await tester.pumpAndSettle();

    expect(find.text('Smart Safety Helmet'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    // AppState.dispose tears down dependencies when the tree unmounts.
  });
}
