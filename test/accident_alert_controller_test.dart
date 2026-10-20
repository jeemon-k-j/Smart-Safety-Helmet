import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_event.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/models/geo_position.dart';
import 'package:smart_safety_helmet/repositories/local_accident_repository.dart';
import 'package:smart_safety_helmet/repositories/local_emergency_contact_repository.dart';
import 'package:smart_safety_helmet/services/accident/accident_alert_controller.dart';
import 'package:smart_safety_helmet/services/accident/accident_event_gate.dart';
import 'package:smart_safety_helmet/services/accident/pending_notification_store.dart';
import 'package:smart_safety_helmet/services/location/fixed_location_service.dart';
import 'package:smart_safety_helmet/services/location/phone_location_resolver.dart';
import 'package:smart_safety_helmet/services/notifications/recording_emergency_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancel during countdown prevents email dispatch', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final accidents = LocalAccidentRepository(deviceId: 'h1');
    final contacts = LocalEmergencyContactRepository(preferences: prefs);
    await contacts.addContact(name: 'Care', email: 'care@example.com');
    final recorder = RecordingEmergencyNotificationService();
    final controller = AccidentAlertController(
      accidentRepository: accidents,
      contactRepository: contacts,
      locationResolver: PhoneLocationResolver(
        locationService: const FixedLocationService(
          position: GeoPosition(latitude: 9.93, longitude: 76.26),
        ),
      ),
      notifications: recorder,
      gate: AccidentEventGate(),
      pendingStore: MemoryPendingNotificationStore(),
    );

    await controller.onAccidentUpdate(
      const AccidentEvent(
        eventId: 'acc-cancel',
        active: true,
        severity: AccidentSeverity.high,
      ),
    );
    expect(controller.phase, AccidentAlertPhase.countdown);
    await controller.cancel();
    expect(controller.phase, AccidentAlertPhase.cancelled);
    expect(recorder.dispatched, isEmpty);

    controller.dispose();
    accidents.dispose();
    contacts.dispose();
  });
}
