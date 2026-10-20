import '../models/accident_event.dart';

/// Accident node access (RTDB or local).
abstract class AccidentRepository {
  String get deviceId;

  Stream<AccidentEvent> watchAccident();

  Future<void> markCancelled(String eventId);

  Future<void> markNotificationSent({
    required String eventId,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? locationSource,
  });
}
