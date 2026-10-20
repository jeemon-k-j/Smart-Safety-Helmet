import 'geo_position.dart';

/// How a phone location fix was obtained (adapted from DeepCrash).
enum PhoneLocationQuality { fresh, stale }

class PhoneLocationFix {
  const PhoneLocationFix({
    required this.position,
    required this.quality,
    required this.capturedAt,
  });

  final GeoPosition position;
  final PhoneLocationQuality quality;
  final DateTime capturedAt;

  bool get isStale => quality == PhoneLocationQuality.stale;

  String get locationSource => isStale ? phoneGpsStaleSource : phoneGpsSource;
}

class CachedPhoneLocation {
  const CachedPhoneLocation({required this.position, required this.capturedAt});

  final GeoPosition position;
  final DateTime capturedAt;
}

const String phoneGpsSource = 'phoneGps';
const String phoneGpsStaleSource = 'phoneGpsStale';

enum LocationFailureKind {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.kind, this.message);

  final LocationFailureKind kind;
  final String message;

  static const LocationFailure serviceDisabled = LocationFailure(
    LocationFailureKind.serviceDisabled,
    'Location services are turned off. Turn on GPS to record the accident location.',
  );

  static const LocationFailure permissionDenied = LocationFailure(
    LocationFailureKind.permissionDenied,
    'Location permission was denied. Allow location access to record the accident location.',
  );

  static const LocationFailure permissionPermanentlyDenied = LocationFailure(
    LocationFailureKind.permissionPermanentlyDenied,
    'Location permission is permanently denied. Enable location in system settings.',
  );

  static const LocationFailure timeout = LocationFailure(
    LocationFailureKind.timeout,
    'The phone could not get a GPS fix in time.',
  );

  static const LocationFailure unavailable = LocationFailure(
    LocationFailureKind.unavailable,
    'The phone location could not be read.',
  );

  @override
  String toString() => message;
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  unableToDetermine,
}
