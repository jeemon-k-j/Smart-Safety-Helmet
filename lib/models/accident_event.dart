import 'accident_severity.dart';

/// Accident payload under `devices/{deviceId}/accident` in RTDB.
class AccidentEvent {
  const AccidentEvent({
    required this.eventId,
    required this.active,
    required this.severity,
    this.detectedAt,
    this.cancelled = false,
    this.notificationSent = false,
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.locationSource,
  });

  final String eventId;
  final bool active;
  final AccidentSeverity severity;
  final DateTime? detectedAt;
  final bool cancelled;
  final bool notificationSent;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final String? locationSource;

  bool get isActionable =>
      active && !cancelled && !notificationSent && eventId.trim().isNotEmpty;

  factory AccidentEvent.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const AccidentEvent(
        eventId: '',
        active: false,
        severity: AccidentSeverity.low,
      );
    }
    return AccidentEvent(
      eventId: (map['eventId'] ?? '').toString(),
      active: map['active'] == true,
      severity: AccidentSeverity.fromWire(map['severity']),
      detectedAt: _toDate(map['detectedAt']),
      cancelled: map['cancelled'] == true,
      notificationSent: map['notificationSent'] == true,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      mapsUrl: map['mapsUrl'] as String?,
      locationSource: map['locationSource'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'eventId': eventId,
        'active': active,
        'severity': severity.wireValue,
        if (detectedAt != null)
          'detectedAt': detectedAt!.millisecondsSinceEpoch,
        'cancelled': cancelled,
        'notificationSent': notificationSent,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (mapsUrl != null) 'mapsUrl': mapsUrl,
        if (locationSource != null) 'locationSource': locationSource,
      };

  AccidentEvent copyWith({
    bool? active,
    bool? cancelled,
    bool? notificationSent,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? locationSource,
  }) {
    return AccidentEvent(
      eventId: eventId,
      active: active ?? this.active,
      severity: severity,
      detectedAt: detectedAt,
      cancelled: cancelled ?? this.cancelled,
      notificationSent: notificationSent ?? this.notificationSent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      locationSource: locationSource ?? this.locationSource,
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
