import 'package:firebase_database/firebase_database.dart';

import '../models/device_status.dart';
import 'device_repository.dart';

class FirebaseDeviceRepository implements DeviceRepository {
  FirebaseDeviceRepository({
    required this.deviceId,
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  @override
  final String deviceId;
  final FirebaseDatabase _database;

  DatabaseReference get _statusRef =>
      _database.ref('devices/$deviceId/status');

  @override
  Stream<DeviceStatus> watchStatus() {
    return _statusRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return DeviceStatus.fromMap(Map<dynamic, dynamic>.from(value));
      }
      return DeviceStatus.empty;
    });
  }
}
