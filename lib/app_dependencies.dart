import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'repositories/accident_repository.dart';
import 'repositories/device_repository.dart';
import 'repositories/firebase_accident_repository.dart';
import 'repositories/firebase_device_repository.dart';
import 'repositories/local_accident_repository.dart';
import 'repositories/local_device_repository.dart';
import 'services/accident/accident_alert_controller.dart';
import 'services/accident/accident_event_gate.dart';
import 'services/accident/pending_notification_store.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/firebase_auth_service.dart';
import 'services/auth/local_auth_service.dart';
import 'services/location/geolocator_location_service.dart';
import 'services/location/location_service.dart';
import 'services/location/phone_location_resolver.dart';
import 'services/notifications/email_bridge_notification_service.dart';
import 'services/notifications/emergency_notification_service.dart';

/// Wired services for the running app (Firebase or local).
class AppDependencies {
  AppDependencies({
    required this.firebaseReady,
    required this.authService,
    required this.deviceRepository,
    required this.accidentRepository,
    required this.alertController,
    required this.locationService,
    required this.notifications,
  });

  final bool firebaseReady;
  final AuthService authService;
  final DeviceRepository deviceRepository;
  final AccidentRepository accidentRepository;
  final AccidentAlertController alertController;
  final LocationService locationService;
  final EmergencyNotificationService notifications;

  static Future<AppDependencies> create({
    required bool firebaseReady,
    required SharedPreferences preferences,
    required PendingNotificationStore pendingStore,
    String deviceId = AppConfig.defaultDeviceId,
    LocationService? locationService,
    EmergencyNotificationService? notifications,
  }) async {
    final AuthService auth;
    final DeviceRepository devices;
    final AccidentRepository accidents;

    if (firebaseReady) {
      auth = FirebaseAuthService();
      devices = FirebaseDeviceRepository(deviceId: deviceId);
      accidents = FirebaseAccidentRepository(deviceId: deviceId);
    } else {
      auth = LocalAuthService(preferences: preferences);
      devices = LocalDeviceRepository(deviceId: deviceId);
      accidents = LocalAccidentRepository(deviceId: deviceId);
    }

    final LocationService location =
        locationService ?? GeolocatorLocationService();

    // DeepCrash-style bridge client is always the production path. SMTP secrets
    // and the fixed emergency recipient remain on the bridge host.
    final EmergencyNotificationService mail = notifications ??
        EmailBridgeNotificationService(bridgeBaseUrl: AppConfig.emailBridgeUrl);

    final alertController = AccidentAlertController(
      accidentRepository: accidents,
      locationResolver: PhoneLocationResolver(locationService: location),
      notifications: mail,
      gate: AccidentEventGate(),
      pendingStore: pendingStore,
    );

    return AppDependencies(
      firebaseReady: firebaseReady,
      authService: auth,
      deviceRepository: devices,
      accidentRepository: accidents,
      alertController: alertController,
      locationService: location,
      notifications: mail,
    );
  }

  bool _disposed = false;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    alertController.dispose();
    final auth = authService;
    if (auth is LocalAuthService) {
      auth.dispose();
    }
    final devices = deviceRepository;
    if (devices is LocalDeviceRepository) {
      devices.dispose();
    }
    final accidents = accidentRepository;
    if (accidents is LocalAccidentRepository) {
      accidents.dispose();
    }
  }
}
