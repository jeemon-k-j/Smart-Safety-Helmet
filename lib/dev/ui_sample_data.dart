import '../models/accident_event.dart';
import '../models/accident_severity.dart';
import '../models/device_status.dart';
import '../repositories/local_accident_repository.dart';
import '../repositories/local_device_repository.dart';
import '../services/notifications/recording_emergency_notification_service.dart';
import '../app_dependencies.dart';

/// Temporary on-device sample values for visual UI inspection only.
///
/// Enabled with `--dart-define=UI_SAMPLE_DATA=true`. Does not add simulator
/// controls or change the product UI. Uses [RecordingEmergencyNotificationService]
/// so inspection does not depend on the email bridge.
class UiSampleData {
  UiSampleData._();

  static const bool enabled = bool.fromEnvironment('UI_SAMPLE_DATA');

  static Future<void> apply(AppDependencies deps) async {
    if (!enabled) {
      return;
    }

    try {
      await deps.authService.register(
        email: 'ui.inspect@local.test',
        password: 'inspect1',
      );
    } catch (_) {
      await deps.authService.signIn(
        email: 'ui.inspect@local.test',
        password: 'inspect1',
      );
    }

    final devices = deps.deviceRepository;
    if (devices is LocalDeviceRepository) {
      devices.publish(
        DeviceStatus(
          isAvailable: true,
          alcoholDetected: false,
          helmetClipped: true,
          ignitionAllowed: true,
          ignitionActive: false,
          drowsy: true,
          warningActive: true,
          updatedAt: DateTime.now(),
        ),
      );
    }

    final accidents = deps.accidentRepository;
    if (accidents is LocalAccidentRepository) {
      accidents.publish(
        AccidentEvent(
          eventId: 'ui-sample-acc-1',
          active: true,
          severity: AccidentSeverity.medium,
          detectedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Prefer recording notifications during sample UI runs (no SMTP).
  static RecordingEmergencyNotificationService? notificationOverride() {
    if (!enabled) {
      return null;
    }
    return RecordingEmergencyNotificationService();
  }
}
