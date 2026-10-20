import 'package:firebase_database/firebase_database.dart';

import '../models/accident_event.dart';
import '../models/accident_severity.dart';

/// Reads/writes accident nodes under `devices/{deviceId}/accident`.
class AccidentRepository {
  AccidentRepository({
    required this.deviceId,
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  final String deviceId;
  final FirebaseDatabase _database;

  DatabaseReference get _accidentRef =>
      _database.ref('devices/$deviceId/accident');

  Stream<AccidentEvent> watchAccident() {
    return _accidentRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return AccidentEvent.fromMap(Map<dynamic, dynamic>.from(value));
      }
      return const AccidentEvent(
        eventId: '',
        active: false,
        severity: AccidentSeverity.low,
      );
    });
  }

  Future<void> markCancelled(String eventId) async {
    await _accidentRef.update(<String, Object?>{
      'eventId': eventId,
      'cancelled': true,
      'active': false,
    });
  }

  Future<void> markNotificationSent({
    required String eventId,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? locationSource,
  }) async {
    await _accidentRef.update(<String, Object?>{
      'eventId': eventId,
      'notificationSent': true,
      'active': true,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'mapsUrl': ?mapsUrl,
      'locationSource': ?locationSource,
    });
  }
}
