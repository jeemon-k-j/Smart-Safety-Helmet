import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/accident_event.dart';
import '../../models/accident_severity.dart';
import '../../models/emergency_notification.dart';
import '../../models/geo_position.dart';
import '../../models/phone_location.dart';
import '../../repositories/accident_repository.dart';
import '../../repositories/emergency_contact_repository.dart';
import '../../utils/formatters.dart';
import '../location/phone_location_resolver.dart';
import '../notifications/emergency_notification_service.dart';
import 'accident_event_gate.dart';
import 'pending_notification_store.dart';

enum AccidentAlertPhase {
  idle,
  countdown,
  locating,
  notifying,
  sent,
  cancelled,
  failed,
}

/// False-alert countdown, phone GPS, and emergency email dispatch.
///
/// Severity selects countdown length. The same [eventId] is never emailed twice.
class AccidentAlertController extends ChangeNotifier {
  AccidentAlertController({
    required AccidentRepository accidentRepository,
    required EmergencyContactRepository contactRepository,
    required PhoneLocationResolver locationResolver,
    required EmergencyNotificationService notifications,
    required AccidentEventGate gate,
    required PendingNotificationStore pendingStore,
    DateTime Function()? clock,
  })  : _accidentRepository = accidentRepository,
        _contactRepository = contactRepository,
        _locationResolver = locationResolver,
        _notifications = notifications,
        _gate = gate,
        _pendingStore = pendingStore,
        _clock = clock ?? DateTime.now;

  final AccidentRepository _accidentRepository;
  final EmergencyContactRepository _contactRepository;
  final PhoneLocationResolver _locationResolver;
  final EmergencyNotificationService _notifications;
  final AccidentEventGate _gate;
  final PendingNotificationStore _pendingStore;
  final DateTime Function() _clock;

  AccidentAlertPhase phase = AccidentAlertPhase.idle;
  AccidentEvent? activeEvent;
  Duration remaining = Duration.zero;
  String? statusMessage;
  GeoPosition? lastPosition;
  String? lastMapsUrl;

  Timer? _ticker;
  DateTime? _deadline;
  int _generation = 0;

  bool get canCancel =>
      phase == AccidentAlertPhase.countdown && activeEvent != null;

  /// Called whenever RTDB accident data changes.
  Future<void> onAccidentUpdate(AccidentEvent event) async {
    if (!event.active) {
      if (phase == AccidentAlertPhase.countdown ||
          phase == AccidentAlertPhase.locating ||
          phase == AccidentAlertPhase.notifying) {
        // Device cleared while we were working — stop local countdown only if
        // the same event was cancelled remotely.
        if (event.cancelled && activeEvent?.eventId == event.eventId) {
          await _finishCancelled(remote: true);
        }
      }
      return;
    }

    final existing = await _pendingStore.read(event.eventId);
    if (existing != null &&
        (existing.notificationSent || existing.cancelled)) {
      _gate.markProcessed(event.eventId);
      return;
    }
    if (event.notificationSent || event.cancelled) {
      _gate.markProcessed(event.eventId);
      return;
    }
    if (!_gate.accept(event)) {
      return;
    }

    await _startCountdown(event);
  }

  Future<void> cancel() async {
    if (!canCancel) {
      return;
    }
    final event = activeEvent;
    if (event == null) {
      return;
    }
    _generation++;
    _ticker?.cancel();
    _ticker = null;

    await _pendingStore.save(
      PendingNotificationRecord(
        eventId: event.eventId,
        notificationSent: false,
        cancelled: true,
      ),
    );
    try {
      await _accidentRepository.markCancelled(event.eventId);
    } catch (error) {
      debugPrint('Could not mark accident cancelled in RTDB: $error');
    }
    phase = AccidentAlertPhase.cancelled;
    statusMessage = 'Alert cancelled. Emergency email was not sent.';
    remaining = Duration.zero;
    notifyListeners();
  }

  Future<void> _startCountdown(AccidentEvent event) async {
    _generation++;
    final generation = _generation;
    activeEvent = event;
    phase = AccidentAlertPhase.countdown;
    statusMessage =
        'Accident detected (${event.severity.name}). Cancel if this is a false alert.';
    remaining = event.severity.countdown;
    _deadline = _clock().add(remaining);
    notifyListeners();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (generation != _generation) {
        return;
      }
      final left = _deadline!.difference(_clock());
      if (left <= Duration.zero) {
        remaining = Duration.zero;
        notifyListeners();
        _ticker?.cancel();
        unawaited(_completeAfterCountdown(generation, event));
        return;
      }
      remaining = left;
      notifyListeners();
    });
  }

  Future<void> _completeAfterCountdown(
    int generation,
    AccidentEvent event,
  ) async {
    if (generation != _generation) {
      return;
    }
    phase = AccidentAlertPhase.locating;
    statusMessage = 'Obtaining phone GPS location…';
    notifyListeners();

    PhoneLocationFix? fix;
    String? locationMessage;
    try {
      fix = await _locationResolver.resolve();
    } on LocationFailure catch (failure) {
      locationMessage = failure.message;
    } catch (error) {
      debugPrint('Phone location failed: $error');
      locationMessage = LocationFailure.unavailable.message;
    }
    if (generation != _generation) {
      return;
    }

    lastPosition = fix?.position;
    lastMapsUrl = fix == null
        ? null
        : googleMapsUrl(fix.position.latitude, fix.position.longitude);
    if (fix?.isStale == true) {
      locationMessage =
          'A fresh GPS fix was unavailable; a recent phone location is being used.';
    }

    phase = AccidentAlertPhase.notifying;
    statusMessage = locationMessage ?? 'Sending emergency email…';
    notifyListeners();

    final contacts = await _contactRepository.listContacts();
    final recipients = contacts
        .map((c) => c.email.trim())
        .where(_looksLikeEmail)
        .toSet()
        .toList();

    final notification = EmergencyNotification.forAccident(
      eventId: event.eventId,
      severity: event.severity,
      recipients: recipients,
      position: fix?.position,
      occurredAt: event.detectedAt ?? _clock(),
      locationSource: fix?.locationSource,
    );

    try {
      await _notifications.dispatch(notification);
      if (generation != _generation) {
        return;
      }
      await _pendingStore.save(
        PendingNotificationRecord(
          eventId: event.eventId,
          notificationSent: true,
          cancelled: false,
        ),
      );
      try {
        await _accidentRepository.markNotificationSent(
          eventId: event.eventId,
          latitude: fix?.position.latitude,
          longitude: fix?.position.longitude,
          mapsUrl: lastMapsUrl,
          locationSource: fix?.locationSource,
        );
      } catch (error) {
        debugPrint('Could not update RTDB after email: $error');
      }
      phase = AccidentAlertPhase.sent;
      final locationNote = fix == null
          ? ' Phone location was unavailable.'
          : '';
      statusMessage = recipients.isEmpty
          ? 'Notification processed, but no alert recipients are configured.'
              '$locationNote'
          : 'Emergency email sent to ${recipients.length} recipient(s).'
              '$locationNote';
      notifyListeners();
    } catch (error) {
      debugPrint('Emergency notification failed: $error');
      if (generation != _generation) {
        return;
      }
      phase = AccidentAlertPhase.failed;
      statusMessage =
          'Could not send emergency email: $error';
      await _pendingStore.save(
        PendingNotificationRecord(
          eventId: event.eventId,
          notificationSent: false,
          cancelled: false,
        ),
      );
      notifyListeners();
    }
  }

  bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && value.contains('.', at + 1);
  }

  Future<void> _finishCancelled({required bool remote}) async {
    _generation++;
    _ticker?.cancel();
    _ticker = null;
    phase = AccidentAlertPhase.cancelled;
    remaining = Duration.zero;
    statusMessage = remote
        ? 'Accident cancelled remotely.'
        : 'Alert cancelled. Emergency email was not sent.';
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}

/// Test helper: exposes severity countdown mapping.
Duration countdownForSeverity(AccidentSeverity severity) => severity.countdown;
