import 'dart:async';

import '../models/accident_event.dart';
import '../models/accident_severity.dart';
import 'accident_repository.dart';

/// Local accident state for credential-free runs and unit tests.
class LocalAccidentRepository implements AccidentRepository {
  LocalAccidentRepository({required this.deviceId});

  @override
  final String deviceId;

  AccidentEvent _event = const AccidentEvent(
    eventId: '',
    active: false,
    severity: AccidentSeverity.low,
  );

  final StreamController<AccidentEvent> _controller =
      StreamController<AccidentEvent>.broadcast();

  @override
  Stream<AccidentEvent> watchAccident() async* {
    yield _event;
    yield* _controller.stream;
  }

  /// Test / firmware-integration hook only (no UI control).
  void publish(AccidentEvent event) {
    _event = event;
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  @override
  Future<void> markCancelled(String eventId) async {
    _event = _event.copyWith(
      active: false,
      cancelled: true,
    );
    // Preserve eventId from the active episode when matching.
    if (_event.eventId.isEmpty || _event.eventId == eventId) {
      _event = AccidentEvent(
        eventId: eventId,
        active: false,
        severity: _event.severity,
        detectedAt: _event.detectedAt,
        cancelled: true,
        notificationSent: _event.notificationSent,
        latitude: _event.latitude,
        longitude: _event.longitude,
        mapsUrl: _event.mapsUrl,
        locationSource: _event.locationSource,
      );
    }
    if (!_controller.isClosed) {
      _controller.add(_event);
    }
  }

  @override
  Future<void> markNotificationSent({
    required String eventId,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    String? locationSource,
  }) async {
    _event = AccidentEvent(
      eventId: eventId,
      active: true,
      severity: _event.severity,
      detectedAt: _event.detectedAt,
      cancelled: false,
      notificationSent: true,
      latitude: latitude ?? _event.latitude,
      longitude: longitude ?? _event.longitude,
      mapsUrl: mapsUrl ?? _event.mapsUrl,
      locationSource: locationSource ?? _event.locationSource,
    );
    if (!_controller.isClosed) {
      _controller.add(_event);
    }
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
