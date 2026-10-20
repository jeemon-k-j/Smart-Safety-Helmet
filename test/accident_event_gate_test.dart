import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_event.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/services/accident/accident_event_gate.dart';

void main() {
  test('accepts an actionable event once', () {
    final gate = AccidentEventGate();
    final event = AccidentEvent(
      eventId: 'acc-1',
      active: true,
      severity: AccidentSeverity.medium,
    );
    expect(gate.accept(event), isTrue);
    expect(gate.accept(event), isFalse);
  });

  test('ignores cancelled or already notified events', () {
    final gate = AccidentEventGate();
    expect(
      gate.accept(
        const AccidentEvent(
          eventId: 'acc-2',
          active: true,
          severity: AccidentSeverity.low,
          cancelled: true,
        ),
      ),
      isFalse,
    );
    expect(
      gate.accept(
        const AccidentEvent(
          eventId: 'acc-3',
          active: true,
          severity: AccidentSeverity.low,
          notificationSent: true,
        ),
      ),
      isFalse,
    );
  });
}
