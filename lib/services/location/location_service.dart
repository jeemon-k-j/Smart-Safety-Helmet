import '../../models/geo_position.dart';
import '../../models/phone_location.dart';

/// Phone location interface (adapted from DeepCrash).
abstract class LocationService {
  const LocationService();

  Future<GeoPosition> getCurrentPosition();

  Future<bool> isServiceEnabled() async => true;

  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;

  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.granted;

  Future<GeoPosition> getFreshPosition({
    Duration timeout = const Duration(seconds: 12),
  }) {
    return getCurrentPosition();
  }

  Future<CachedPhoneLocation?> getCachedLocation() async => null;
}
