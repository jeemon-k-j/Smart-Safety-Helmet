/// Live helmet / vehicle status mirrored from Firebase RTDB (`devices/{id}/status`).
///
/// Ignition allow/deny is decided on the ESP32 from alcohol + helmet clip
/// sensors and does not require internet.
class DeviceStatus {
  const DeviceStatus({
    this.alcoholDetected = false,
    this.helmetClipped = false,
    this.ignitionAllowed = false,
    this.ignitionActive = false,
    this.drowsy = false,
    this.warningActive = false,
    this.updatedAt,
  });

  final bool alcoholDetected;
  final bool helmetClipped;
  final bool ignitionAllowed;
  final bool ignitionActive;
  final bool drowsy;
  final bool warningActive;
  final DateTime? updatedAt;

  static const DeviceStatus empty = DeviceStatus();

  factory DeviceStatus.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return DeviceStatus.empty;
    }
    return DeviceStatus(
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
