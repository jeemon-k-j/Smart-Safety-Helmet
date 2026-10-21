import 'package:firebase_database/firebase_database.dart';

import '../config/app_firebase.dart';
import '../models/accident_event.dart';
import '../models/accident_severity.dart';
import 'accident_repository.dart';

class FirebaseAccidentRepository implements AccidentRepository {
  FirebaseAccidentRepository({
    required this.deviceId,
    FirebaseDatabase? database,
  }) : _database = database ?? AppFirebase.database;

  @override
  final String deviceId;
  final FirebaseDatabase _database;

  DatabaseReference get _accidentRef =>
      _database.ref('devices/$deviceId/accident');

  @override
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

  @override
  Future<void> markCancelled(String eventId) async {
    await _accidentRef.update(<String, Object?>{
      'eventId': eventId,
      'cancelled': true,
      'active': false,
    });
  }

  @override
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
