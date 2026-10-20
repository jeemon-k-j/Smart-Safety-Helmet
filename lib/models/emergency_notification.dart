import '../utils/formatters.dart';
import 'accident_severity.dart';
import 'geo_position.dart';

/// Emergency email payload (adapted from DeepCrash; RTDB + Maps link).
class EmergencyNotification {
  const EmergencyNotification({
    required this.title,
    required this.body,
    required this.eventId,
    required this.severity,
    required this.recipients,
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.occurredAt,
    this.trigger,
    this.locationSource,
  });

  static const String type = 'smartSafetyHelmetEmergency';

  final String title;
  final String body;
  final String eventId;
  final AccidentSeverity severity;
  final List<String> recipients;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final DateTime? occurredAt;
  final String? trigger;
  final String? locationSource;

  factory EmergencyNotification.forAccident({
    required String eventId,
    required AccidentSeverity severity,
    required List<String> recipients,
    GeoPosition? position,
    DateTime? occurredAt,
    String? trigger,
    String? locationSource,
  }) {
    final maps = position == null
        ? null
        : googleMapsUrl(position.latitude, position.longitude);
    final location = position == null
        ? 'Location unavailable'
        : '${formatCoordinate(position.latitude)}, '
            '${formatCoordinate(position.longitude)}';
    final time = occurredAt == null
        ? 'Time unknown'
        : formatDateTime(occurredAt);
    return EmergencyNotification(
      title: 'Smart Safety Helmet emergency alert',
      body: 'Accident (${severity.name}) · $location · $time'
          '${maps == null ? '' : ' · $maps'}',
      eventId: eventId,
      severity: severity,
      recipients: recipients,
      latitude: position?.latitude,
      longitude: position?.longitude,
      mapsUrl: maps,
      occurredAt: occurredAt,
      trigger: trigger ?? 'esp32Accident',
      locationSource: locationSource,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'title': title,
        'body': body,
        'eventId': eventId,
        'severity': severity.wireValue,
        'recipients': recipients,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (mapsUrl != null) 'mapsUrl': mapsUrl,
        if (occurredAt != null)
          'occurredAt': occurredAt!.toUtc().toIso8601String(),
        if (trigger != null) 'trigger': trigger,
        if (locationSource != null) 'locationSource': locationSource,
        'idempotencyKey': eventId,
      };
}
