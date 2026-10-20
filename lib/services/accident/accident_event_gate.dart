import '../../models/accident_event.dart';

/// Prevents duplicate processing of the same accident [eventId].
///
/// Adapted from DeepCrash `CrashEventGate`, simplified for RTDB accident nodes.
class AccidentEventGate {
  final Set<String> _processedIds = <String>{};

  /// Returns true once per actionable [event.eventId].
  bool accept(AccidentEvent event) {
    if (!event.isActionable) {
      if (!event.active) {
        // Device cleared the accident; allow a later new eventId.
      }
      return false;
    }
    final id = event.eventId.trim();
    if (_processedIds.contains(id)) {
      return false;
    }
    _processedIds.add(id);
    return true;
  }

  /// Marks an id as processed without starting a workflow (e.g. already emailed).
  void markProcessed(String eventId) {
    final id = eventId.trim();
    if (id.isNotEmpty) {
      _processedIds.add(id);
    }
  }

  bool wasProcessed(String eventId) =>
      _processedIds.contains(eventId.trim());
}
