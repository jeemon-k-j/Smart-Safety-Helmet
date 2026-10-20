import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/geo_position.dart';
import 'package:smart_safety_helmet/models/phone_location.dart';
import 'package:smart_safety_helmet/services/location/location_service.dart';
import 'package:smart_safety_helmet/services/location/phone_location_resolver.dart';
import 'package:smart_safety_helmet/utils/formatters.dart';

class _FakeLocationService extends LocationService {
  _FakeLocationService({
    this.serviceEnabled = true,
    this.permission = LocationPermissionStatus.granted,
    this.fresh,
    this.cached,
    this.freshError,
  });

  bool serviceEnabled;
  LocationPermissionStatus permission;
  GeoPosition? fresh;
  CachedPhoneLocation? cached;
  Object? freshError;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Future<GeoPosition> getCurrentPosition() => getFreshPosition();

  @override
  Future<GeoPosition> getFreshPosition({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (freshError != null) {
      throw freshError!;
    }
    final value = fresh;
    if (value == null) {
      throw LocationFailure.unavailable;
    }
    return value;
  }

  @override
  Future<CachedPhoneLocation?> getCachedLocation() async => cached;
}

void main() {
  final now = DateTime.utc(2026, 4, 1, 12);

  test('returns fresh precise fix', () async {
    final resolver = PhoneLocationResolver(
      locationService: _FakeLocationService(
        fresh: const GeoPosition(
          latitude: 37.4219983,
          longitude: -122.084,
          accuracyMeters: 12,
        ),
      ),
      clock: () => now,
    );

    final fix = await resolver.resolve();
    expect(fix.quality, PhoneLocationQuality.fresh);
    expect(fix.locationSource, phoneGpsSource);
    expect(fix.position.latitude, closeTo(37.4219983, 0.0001));
  });

  test('rejects inaccurate fresh and uses recent cached fix', () async {
    final resolver = PhoneLocationResolver(
      locationService: _FakeLocationService(
        fresh: const GeoPosition(
          latitude: 37.42,
          longitude: -122.08,
          accuracyMeters: 250,
        ),
        cached: CachedPhoneLocation(
          position: const GeoPosition(
            latitude: 37.4219983,
            longitude: -122.084,
            accuracyMeters: 20,
          ),
          capturedAt: now.subtract(const Duration(minutes: 2)),
        ),
      ),
      clock: () => now,
    );

    final fix = await resolver.resolve();
    expect(fix.quality, PhoneLocationQuality.stale);
    expect(fix.locationSource, phoneGpsStaleSource);
  });

  test('does not use stale cache older than max age', () async {
    final resolver = PhoneLocationResolver(
      locationService: _FakeLocationService(
        freshError: Exception('timeout'),
        cached: CachedPhoneLocation(
          position: const GeoPosition(
            latitude: 37.4219983,
            longitude: -122.084,
            accuracyMeters: 15,
          ),
          capturedAt: now.subtract(const Duration(minutes: 20)),
        ),
      ),
      clock: () => now,
    );

    expect(
      () => resolver.resolve(),
      throwsA(
        isA<LocationFailure>().having(
          (e) => e.kind,
          'kind',
          LocationFailureKind.timeout,
        ),
      ),
    );
  });

  test('throws when location services are disabled', () async {
    final resolver = PhoneLocationResolver(
      locationService: _FakeLocationService(serviceEnabled: false),
      clock: () => now,
    );
    expect(
      () => resolver.resolve(),
      throwsA(
        isA<LocationFailure>().having(
          (e) => e.kind,
          'kind',
          LocationFailureKind.serviceDisabled,
        ),
      ),
    );
  });

  test('throws when permission denied', () async {
    final resolver = PhoneLocationResolver(
      locationService: _FakeLocationService(
        permission: LocationPermissionStatus.denied,
      ),
      clock: () => now,
    );
    expect(
      () => resolver.resolve(),
      throwsA(
        isA<LocationFailure>().having(
          (e) => e.kind,
          'kind',
          LocationFailureKind.permissionDenied,
        ),
      ),
    );
  });

  test('maps link needs no API key', () {
    expect(
      googleMapsUrl(37.4219983, -122.084),
      'https://maps.google.com/?q=37.4219983,-122.084',
    );
  });
}
