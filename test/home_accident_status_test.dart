import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_event.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/screens/dashboard/dashboard_screen.dart';
import 'package:smart_safety_helmet/theme/app_theme.dart';
import 'package:smart_safety_helmet/utils/formatters.dart';

void main() {
  group('formatDateTimeIst', () {
    test('formats UTC instants as 12-hour IST', () {
      // 2026-04-01T12:00:00.000Z => 5:30:00 pm IST
      final text = formatDateTimeIst(DateTime.utc(2026, 4, 1, 12));
      expect(text, '01 Apr 2026, 5:30:00 pm IST');
      expect(text, isNot(contains('�')));
    });
  });

  group('describeHomeAccidentStatus', () {
    test('active uncancelled accident is Danger / Active with severity', () {
      final view = describeHomeAccidentStatus(
        AccidentEvent(
          eventId: 'acc-finalize-20261021165734',
          active: true,
          severity: AccidentSeverity.high,
          cancelled: false,
          notificationSent: false,
          detectedAt: DateTime.utc(2026, 10, 21, 11, 27, 34),
        ),
      );
      expect(view.tone, SafetyTone.danger);
      expect(view.value, 'Active (high)');
      expect(view.subtitle, contains('Detected'));
      expect(view.subtitle, contains('IST'));
      expect(view.subtitle, contains('pm'));
      expect(view.value, isNot(contains('acc-finalize')));
      expect(view.subtitle, isNot(contains('acc-finalize')));
      expect(view.subtitle, isNot(contains('Event:')));
    });

    test('cancelled accident is Safe / Clear without warning', () {
      final view = describeHomeAccidentStatus(
        const AccidentEvent(
          eventId: 'acc-finalize-20261021165734',
          active: false,
          severity: AccidentSeverity.high,
          cancelled: true,
          notificationSent: false,
        ),
      );
      expect(view.tone, SafetyTone.safe);
      expect(view.value, 'Clear');
      expect(view.tone, isNot(SafetyTone.warning));
      expect(view.tone, isNot(SafetyTone.danger));
      expect(view.subtitle, contains('cancelled'));
      expect(view.subtitle, isNot(contains('acc-finalize')));
      expect(view.subtitle, isNot(contains('Event:')));
    });

    test('resolved notificationSent accident is Safe / Clear', () {
      final view = describeHomeAccidentStatus(
        AccidentEvent(
          eventId: 'acc-sent-1',
          active: true,
          severity: AccidentSeverity.medium,
          cancelled: false,
          notificationSent: true,
          detectedAt: DateTime.utc(2026, 10, 21, 6, 0),
        ),
      );
      expect(view.tone, SafetyTone.safe);
      expect(view.value, 'Clear');
      expect(view.subtitle, contains('resolved'));
      expect(view.subtitle, contains('11:30:00 am IST'));
      expect(view.subtitle, isNot(contains('acc-sent')));
    });

    test('inactive accident is Safe / Clear', () {
      final view = describeHomeAccidentStatus(
        const AccidentEvent(
          eventId: 'acc-idle-1',
          active: false,
          severity: AccidentSeverity.low,
          cancelled: false,
          notificationSent: false,
        ),
      );
      expect(view.tone, SafetyTone.safe);
      expect(view.value, 'Clear');
      expect(view.subtitle, 'No active accident');
      expect(view.subtitle, isNot(contains('acc-idle')));
    });

    test('empty accident is Unknown', () {
      final view = describeHomeAccidentStatus(
        const AccidentEvent(
          eventId: '',
          active: false,
          severity: AccidentSeverity.low,
        ),
      );
      expect(view.tone, SafetyTone.unknown);
      expect(view.value, 'Unknown');
    });
  });
}
