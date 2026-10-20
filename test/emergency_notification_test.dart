import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/models/emergency_notification.dart';
import 'package:smart_safety_helmet/models/geo_position.dart';

void main() {
  test('builds maps url and payload for phone GPS', () {
    final note = EmergencyNotification.forAccident(
      eventId: 'acc-9',
      severity: AccidentSeverity.high,
      recipients: const ['care@example.com'],
      position: const GeoPosition(latitude: 9.9312, longitude: 76.2673),
      occurredAt: DateTime.utc(2026, 4, 1, 12),
    );

    expect(EmergencyNotification.type, 'smartSafetyHelmetEmergency');
    expect(note.toMap()['type'], 'smartSafetyHelmetEmergency');
    expect(note.mapsUrl, contains('maps.google.com'));
    expect(note.toMap()['idempotencyKey'], 'acc-9');
    expect(note.toMap()['recipients'], ['care@example.com']);
  });
}
