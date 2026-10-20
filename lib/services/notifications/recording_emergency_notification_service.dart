import '../../models/emergency_notification.dart';
import 'emergency_notification_service.dart';

/// Records dispatches for tests. Does not send email or require SMTP.
class RecordingEmergencyNotificationService
    implements EmergencyNotificationService {
  final List<EmergencyNotification> dispatched = <EmergencyNotification>[];

  @override
  Future<void> dispatch(EmergencyNotification notification) async {
    dispatched.add(notification);
  }
}
