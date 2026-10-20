import '../../models/emergency_notification.dart';

abstract class EmergencyNotificationService {
  Future<void> dispatch(EmergencyNotification notification);
}
