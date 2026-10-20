import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../models/geo_position.dart';
import '../../models/phone_location.dart';
import 'location_service.dart';

const Duration deviceLocationTimeout = Duration(seconds: 12);

/// Device GPS via geolocator (adapted from DeepCrash).
///
/// Requests a high-accuracy / precise fix when permitted. Does not use Maps or
/// Places APIs.
class GeolocatorLocationService extends LocationService {
  GeolocatorLocationService({this.timeout = deviceLocationTimeout});

  final Duration timeout;

  @override
  Future<GeoPosition> getCurrentPosition() =>
      getFreshPosition(timeout: timeout);

  @override
  Future<bool> isServiceEnabled() => geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await geo.Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await geo.Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  @override
  Future<GeoPosition> getFreshPosition({
    Duration timeout = deviceLocationTimeout,
  }) async {
    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: _locationSettings(timeout),
    );
    return GeoPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }

  @override
  Future<CachedPhoneLocation?> getCachedLocation() async {
    final position = await geo.Geolocator.getLastKnownPosition();
    if (position == null) {
      return null;
    }
    return CachedPhoneLocation(
      position: GeoPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      ),
      capturedAt: position.timestamp,
    );
  }

  geo.LocationSettings _locationSettings(Duration timeout) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        timeLimit: timeout,
        // Prefer precise location when the user grants fine permission.
        forceLocationManager: false,
      );
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return geo.AppleSettings(
        accuracy: geo.LocationAccuracy.best,
        timeLimit: timeout,
      );
    }
    return geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      timeLimit: timeout,
    );
  }

  LocationPermissionStatus _mapPermission(geo.LocationPermission permission) {
    return switch (permission) {
      geo.LocationPermission.always ||
      geo.LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      geo.LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      geo.LocationPermission.denied => LocationPermissionStatus.denied,
      geo.LocationPermission.unableToDetermine =>
        LocationPermissionStatus.unableToDetermine,
    };
  }
}
