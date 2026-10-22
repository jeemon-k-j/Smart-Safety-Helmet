import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_event.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/models/emergency_notification.dart';
import 'package:smart_safety_helmet/models/geo_position.dart';
import 'package:smart_safety_helmet/repositories/local_accident_repository.dart';
import 'package:smart_safety_helmet/services/accident/accident_alert_controller.dart';
import 'package:smart_safety_helmet/services/accident/accident_event_gate.dart';
import 'package:smart_safety_helmet/services/accident/pending_notification_store.dart';
import 'package:smart_safety_helmet/services/location/fixed_location_service.dart';
import 'package:smart_safety_helmet/services/location/phone_location_resolver.dart';
import 'package:smart_safety_helmet/services/notifications/email_bridge_notification_service.dart';
import 'package:smart_safety_helmet/services/notifications/emergency_notification_service.dart';
import 'package:smart_safety_helmet/services/notifications/recording_emergency_notification_service.dart';

class _FailingNotifications implements EmergencyNotificationService {
  @override
  Future<void> dispatch(EmergencyNotification notification) async {
    throw EmailBridgeException(
      'Emergency email could not be delivered. Try again later.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancel during countdown prevents email dispatch', () async {
    final accidents = LocalAccidentRepository(deviceId: 'h1');
    final recorder = RecordingEmergencyNotificationService();
    final controller = AccidentAlertController(
      accidentRepository: accidents,
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
    expect(
      controller.statusMessage,
      'Alert cancelled. Emergency email was not sent.',
    );

    controller.dispose();
    accidents.dispose();
  });

  test('hardware clear active:false aborts countdown without email', () async {
    final accidents = LocalAccidentRepository(deviceId: 'h1');
    final recorder = RecordingEmergencyNotificationService();
    final controller = AccidentAlertController(
      accidentRepository: accidents,
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
        eventId: 'acc-hw-clear',
        active: true,
        severity: AccidentSeverity.high,
      ),
    );
    expect(controller.phase, AccidentAlertPhase.countdown);

    // Physical clear may omit cancelled; Flutter must still not email.
    await controller.onAccidentUpdate(
      const AccidentEvent(
        eventId: 'acc-hw-clear',
        active: false,
        severity: AccidentSeverity.high,
        cancelled: false,
      ),
    );
    expect(controller.phase, AccidentAlertPhase.cancelled);
    expect(recorder.dispatched, isEmpty);
    expect(
      controller.statusMessage,
      'Accident cleared. Emergency email was not sent.',
    );

    controller.dispose();
    accidents.dispose();
  });

  test('delayed cancel during locating prevents email dispatch', () async {
    final accidents = LocalAccidentRepository(deviceId: 'h1');
    final recorder = RecordingEmergencyNotificationService();
    var now = DateTime.utc(2026, 10, 21, 12);
    final controller = AccidentAlertController(
      accidentRepository: accidents,
      locationResolver: PhoneLocationResolver(
        locationService: const FixedLocationService(
          position: GeoPosition(latitude: 9.93, longitude: 76.26),
        ),
      ),
      notifications: recorder,
      gate: AccidentEventGate(),
      pendingStore: MemoryPendingNotificationStore(),
      clock: () => now,
    );

    await controller.onAccidentUpdate(
      AccidentEvent(
        eventId: 'acc-late-cancel',
        active: true,
        severity: AccidentSeverity.high,
        detectedAt: now,
      ),
    );
    expect(controller.phase, AccidentAlertPhase.countdown);

    now = now.add(const Duration(seconds: 11));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await controller.onAccidentUpdate(
      const AccidentEvent(
        eventId: 'acc-late-cancel',
        active: false,
        severity: AccidentSeverity.high,
        cancelled: true,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(controller.phase, AccidentAlertPhase.cancelled);
    expect(recorder.dispatched, isEmpty);

    controller.dispose();
    accidents.dispose();
  });

  test('successful bridge dispatch shows email sent without recipient warning',
      () async {
    final accidents = LocalAccidentRepository(deviceId: 'h1');
    final recorder = RecordingEmergencyNotificationService();
    var now = DateTime.utc(2026, 10, 21, 12);
    final controller = AccidentAlertController(
      accidentRepository: accidents,
      locationResolver: PhoneLocationResolver(
        locationService: const FixedLocationService(
          position: GeoPosition(latitude: 9.93, longitude: 76.26),
        ),
      ),
      notifications: recorder,
      gate: AccidentEventGate(),
      pendingStore: MemoryPendingNotificationStore(),
      clock: () => now,
    );

    await controller.onAccidentUpdate(
      AccidentEvent(
        eventId: 'acc-sent',
        active: true,
        severity: AccidentSeverity.high,
        detectedAt: now,
      ),
    );
    expect(controller.phase, AccidentAlertPhase.countdown);

    now = now.add(const Duration(seconds: 11));
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(controller.phase, AccidentAlertPhase.sent);
    expect(recorder.dispatched, hasLength(1));
    expect(recorder.dispatched.single.recipients, isEmpty);
    expect(controller.statusMessage, 'Emergency email sent.');
    expect(
      controller.statusMessage,
      isNot(contains('no alert recipients')),
    );

    controller.dispose();
    accidents.dispose();
  });

  test('bridge failure shows accurate error without recipient warning',
      () async {
    final accidents = LocalAccidentRepository(deviceId: 'h1');
    var now = DateTime.utc(2026, 10, 21, 12);
    final controller = AccidentAlertController(
      accidentRepository: accidents,
      locationResolver: PhoneLocationResolver(
        locationService: const FixedLocationService(
          position: GeoPosition(latitude: 9.93, longitude: 76.26),
        ),
      ),
      notifications: _FailingNotifications(),
      gate: AccidentEventGate(),
      pendingStore: MemoryPendingNotificationStore(),
      clock: () => now,
    );

    await controller.onAccidentUpdate(
      AccidentEvent(
        eventId: 'acc-fail',
        active: true,
        severity: AccidentSeverity.high,
        detectedAt: now,
      ),
    );
    now = now.add(const Duration(seconds: 11));
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(controller.phase, AccidentAlertPhase.failed);
    expect(
      controller.statusMessage,
      'Emergency email could not be delivered. Try again later.',
    );
    expect(
      controller.statusMessage,
      isNot(contains('no alert recipients')),
    );

    controller.dispose();
    accidents.dispose();
  });
}
