/// Latitude/longitude from the smartphone GPS (not a hardware GPS module).
class GeoPosition {
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in metres when the platform reports it.
  final double? accuracyMeters;
}
