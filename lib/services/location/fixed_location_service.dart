import '../../models/geo_position.dart';
import '../../models/phone_location.dart';
import 'location_service.dart';

/// Deterministic GPS for unit tests (not wired into the product UI).
class FixedLocationService extends LocationService {
  const FixedLocationService({
    required this.position,
    this.cached,
  });

  final GeoPosition position;
  final CachedPhoneLocation? cached;

  @override
  Future<GeoPosition> getCurrentPosition() async => position;

  @override
  Future<GeoPosition> getFreshPosition({
    Duration timeout = const Duration(seconds: 12),
  }) async =>
      position;

  @override
  Future<CachedPhoneLocation?> getCachedLocation() async => cached;
}
