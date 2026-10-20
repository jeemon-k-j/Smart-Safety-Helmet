import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'repositories/accident_repository.dart';
import 'repositories/device_repository.dart';
import 'repositories/emergency_contact_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/accident/accident_alert_controller.dart';
import 'services/accident/accident_event_gate.dart';
import 'services/accident/pending_notification_store.dart';
import 'services/auth/auth_service.dart';
import 'services/location/geolocator_location_service.dart';
import 'services/location/phone_location_resolver.dart';
import 'services/notifications/email_bridge_notification_service.dart';
import 'theme/app_theme.dart';

class SmartSafetyHelmetApp extends StatefulWidget {
  const SmartSafetyHelmetApp({
    super.key,
    required this.pendingStore,
    this.deviceId = AppConfig.defaultDeviceId,
  });

  final PendingNotificationStore pendingStore;
  final String deviceId;

  @override
  State<SmartSafetyHelmetApp> createState() => _SmartSafetyHelmetAppState();
}

class _SmartSafetyHelmetAppState extends State<SmartSafetyHelmetApp> {
  late final AuthService _auth = AuthService();
  late final DeviceRepository _deviceRepository =
      DeviceRepository(deviceId: widget.deviceId);
  late final AccidentRepository _accidentRepository =
      AccidentRepository(deviceId: widget.deviceId);
  late final EmergencyContactRepository _contactRepository =
      EmergencyContactRepository();
  late final AccidentAlertController _alertController = AccidentAlertController(
    accidentRepository: _accidentRepository,
    contactRepository: _contactRepository,
    locationResolver: PhoneLocationResolver(
      locationService: GeolocatorLocationService(),
    ),
    notifications: EmailBridgeNotificationService(
      bridgeBaseUrl: AppConfig.emailBridgeUrl,
    ),
    gate: AccidentEventGate(),
    pendingStore: widget.pendingStore,
  );

  @override
  void dispose() {
    _alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Safety Helmet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          if (user == null) {
            return LoginScreen(authService: _auth);
          }
          return DashboardScreen(
            authService: _auth,
            deviceRepository: _deviceRepository,
            accidentRepository: _accidentRepository,
            contactRepository: _contactRepository,
            alertController: _alertController,
          );
        },
      ),
    );
  }
}
