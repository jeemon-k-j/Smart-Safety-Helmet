import '../models/device_status.dart';

/// Live helmet / vehicle status from RTDB or a local stand-in.
abstract class DeviceRepository {
  String get deviceId;

  Stream<DeviceStatus> watchStatus();
}
