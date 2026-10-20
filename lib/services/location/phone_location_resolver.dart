import 'dart:async';

import '../../models/geo_position.dart';
import '../../models/phone_location.dart';
import 'location_service.dart';

/// Resolves smartphone GPS for an accident (adapted from DeepCrash).
class PhoneLocationResolver {
  PhoneLocationResolver({
    required LocationService locationService,
    this.timeout = defaultTimeout,
    this.maxCachedAge = defaultMaxCachedAge,
    DateTime Function()? clock,
  })  : _locationService = locationService,
        _clock = clock ?? DateTime.now;

  static const Duration defaultTimeout = Duration(seconds: 12);
  static const Duration defaultMaxCachedAge = Duration(minutes: 5);

  final LocationService _locationService;
  final Duration timeout;
  final Duration maxCachedAge;
  final DateTime Function() _clock;

  Future<PhoneLocationFix> resolve() async {
    if (!await _locationService.isServiceEnabled()) {
      throw LocationFailure.serviceDisabled;
    }

    final permission = await _ensurePermission();
    if (permission != LocationPermissionStatus.granted) {
      throw _failureForPermission(permission);
    }

    try {
      final position = await _locationService
          .getFreshPosition(timeout: timeout)
          .timeout(timeout);
      if (_isUsable(position)) {
        return PhoneLocationFix(
          position: position,
          quality: PhoneLocationQuality.fresh,
          capturedAt: _clock(),
        );
      }
    } on LocationFailure {
      rethrow;
    } on TimeoutException {
      return _cachedOrThrow(LocationFailure.timeout);
    } catch (error) {
      if (_isTimeout(error)) {
        return _cachedOrThrow(LocationFailure.timeout);
      }
      return _cachedOrThrow(LocationFailure.unavailable);
    }

    return _cachedOrThrow(LocationFailure.unavailable);
  }

  Future<LocationPermissionStatus> _ensurePermission() async {
    final current = await _locationService.checkPermission();
    if (current == LocationPermissionStatus.granted ||
        current == LocationPermissionStatus.deniedForever) {
      return current;
    }
    if (current == LocationPermissionStatus.denied) {
      return _locationService.requestPermission();
    }
    return current;
  }

  Future<PhoneLocationFix> _cachedOrThrow(LocationFailure failure) async {
    final cached = await _safeCached();
    if (cached != null && _isRecent(cached) && _isUsable(cached.position)) {
      return PhoneLocationFix(
        position: cached.position,
        quality: PhoneLocationQuality.stale,
        capturedAt: cached.capturedAt,
      );
    }
    throw failure;
  }

  Future<CachedPhoneLocation?> _safeCached() async {
    try {
      return await _locationService.getCachedLocation();
    } catch (_) {
      return null;
    }
  }

  bool _isRecent(CachedPhoneLocation cached) {
    final age = _clock().difference(cached.capturedAt);
    return !age.isNegative && age <= maxCachedAge;
  }

  LocationFailure _failureForPermission(LocationPermissionStatus permission) {
    return switch (permission) {
      LocationPermissionStatus.deniedForever =>
        LocationFailure.permissionPermanentlyDenied,
      LocationPermissionStatus.denied => LocationFailure.permissionDenied,
      LocationPermissionStatus.unableToDetermine => LocationFailure.unavailable,
      LocationPermissionStatus.granted => LocationFailure.unavailable,
    };
  }

  bool _isTimeout(Object error) {
    final text = error.toString().toLowerCase();
    return error is TimeoutException || text.contains('timeout');
  }

  static bool _isUsable(GeoPosition position) {
    final latitude = position.latitude;
    final longitude = position.longitude;
    if (!latitude.isFinite || !longitude.isFinite) {
      return false;
    }
    if (latitude.abs() > 90 || longitude.abs() > 180) {
      return false;
    }
    if (latitude == 0 && longitude == 0) {
      return false;
    }
    return true;
  }
}
