import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_safety_helmet/models/accident_event.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/models/device_status.dart';
import 'package:smart_safety_helmet/repositories/local_accident_repository.dart';
import 'package:smart_safety_helmet/repositories/local_device_repository.dart';
import 'package:smart_safety_helmet/repositories/local_emergency_contact_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local device repository emits published status', () async {
    final repo = LocalDeviceRepository(deviceId: 'helmet-test');
    final events = <DeviceStatus>[];
    final sub = repo.watchStatus().listen(events.add);
    await Future<void>.delayed(Duration.zero);
    repo.publish(
      const DeviceStatus(helmetClipped: true, ignitionAllowed: true),
    );
    await Future<void>.delayed(Duration.zero);
    expect(events.last.helmetClipped, isTrue);
    expect(events.last.ignitionAllowed, isTrue);
    await sub.cancel();
    repo.dispose();
  });

  test('local accident repository supports cancel and notify flags', () async {
    final repo = LocalAccidentRepository(deviceId: 'helmet-test');
    repo.publish(
      const AccidentEvent(
        eventId: 'acc-1',
        active: true,
        severity: AccidentSeverity.high,
      ),
    );
    await repo.markCancelled('acc-1');
    final cancelled = await repo.watchAccident().first;
    expect(cancelled.cancelled, isTrue);
    expect(cancelled.active, isFalse);

    repo.publish(
      const AccidentEvent(
        eventId: 'acc-2',
        active: true,
        severity: AccidentSeverity.medium,
      ),
    );
    await repo.markNotificationSent(
      eventId: 'acc-2',
      latitude: 1.0,
      longitude: 2.0,
      mapsUrl: 'https://maps.google.com/?q=1.0,2.0',
    );
    final sent = await repo.watchAccident().first;
    expect(sent.notificationSent, isTrue);
    expect(sent.latitude, 1.0);
    repo.dispose();
  });

  test('local contacts persist via shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repo = LocalEmergencyContactRepository(preferences: prefs);
    await repo.addContact(name: 'Alex', email: 'alex@example.com');
    final listed = await repo.listContacts();
    expect(listed, hasLength(1));
    expect(listed.first.email, 'alex@example.com');
    await repo.removeContact(listed.first.id);
    expect(await repo.listContacts(), isEmpty);
    repo.dispose();
  });
}
