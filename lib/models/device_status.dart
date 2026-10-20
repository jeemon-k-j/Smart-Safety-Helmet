/// Live helmet / vehicle status mirrored from Firebase RTDB (`devices/{id}/status`).
///
/// Values are reported by ESP32. The Flutter app displays them and does not
/// perform sensor detection. Ignition allow/deny is decided on the ESP32.
class DeviceStatus {
  const DeviceStatus({
    required this.isAvailable,
    this.alcoholDetected = false,
    this.helmetClipped = false,
    this.ignitionAllowed = false,
    this.ignitionActive = false,
    this.drowsy = false,
    this.warningActive = false,
    this.updatedAt,
  });

  /// False when no status payload has been received yet (unknown / unavailable).
  final bool isAvailable;
  final bool alcoholDetected;
  final bool helmetClipped;
  final bool ignitionAllowed;
  final bool ignitionActive;
  final bool drowsy;
  final bool warningActive;
  final DateTime? updatedAt;

  /// No ESP32 status reading available for display.
  static const DeviceStatus unavailable = DeviceStatus(isAvailable: false);

  @Deprecated('Use DeviceStatus.unavailable')
  static const DeviceStatus empty = unavailable;

  factory DeviceStatus.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return DeviceStatus.unavailable;
    }
    return DeviceStatus(
      isAvailable: true,
      alcoholDetected: map['alcoholDetected'] == true,
      helmetClipped: map['helmetClipped'] == true,
      ignitionAllowed: map['ignitionAllowed'] == true,
      ignitionActive: map['ignitionActive'] == true,
      drowsy: map['drowsy'] == true,
      warningActive: map['warningActive'] == true,
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'alcoholDetected': alcoholDetected,
        'helmetClipped': helmetClipped,
        'ignitionAllowed': ignitionAllowed,
        'ignitionActive': ignitionActive,
        'drowsy': drowsy,
        'warningActive': warningActive,
        if (updatedAt != null) 'updatedAt': updatedAt!.millisecondsSinceEpoch,
      };

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
}
