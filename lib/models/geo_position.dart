/// Latitude/longitude from the smartphone GPS (not a hardware GPS module).
class GeoPosition {
  const GeoPosition({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
