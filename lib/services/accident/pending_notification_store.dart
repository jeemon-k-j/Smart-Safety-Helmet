import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local record of accident notification outcomes (idempotency across restarts).
class PendingNotificationRecord {
  const PendingNotificationRecord({
    required this.eventId,
    required this.notificationSent,
    required this.cancelled,
  });

  final String eventId;
  final bool notificationSent;
  final bool cancelled;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'eventId': eventId,
        'notificationSent': notificationSent,
        'cancelled': cancelled,
      };

  static PendingNotificationRecord? fromJson(Map<String, dynamic> json) {
    final id = json['eventId'];
    if (id is! String || id.isEmpty) {
      return null;
    }
    return PendingNotificationRecord(
      eventId: id,
      notificationSent: json['notificationSent'] == true,
      cancelled: json['cancelled'] == true,
    );
  }
}

abstract class PendingNotificationStore {
  Future<void> save(PendingNotificationRecord record);

  Future<PendingNotificationRecord?> read(String eventId);
}

class MemoryPendingNotificationStore implements PendingNotificationStore {
  final Map<String, PendingNotificationRecord> _records =
      <String, PendingNotificationRecord>{};

  @override
  Future<void> save(PendingNotificationRecord record) async {
    _records[record.eventId] = record;
  }

  @override
  Future<PendingNotificationRecord?> read(String eventId) async {
    return _records[eventId];
  }
}

class SharedPreferencesPendingNotificationStore
    implements PendingNotificationStore {
  SharedPreferencesPendingNotificationStore({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  static const String storageKey = 'ssh.pendingNotifications.v1';

  final SharedPreferences _preferences;

  @override
  Future<void> save(PendingNotificationRecord record) async {
    final all = _readAll();
    all[record.eventId] = record;
    await _writeAll(all);
  }

  @override
  Future<PendingNotificationRecord?> read(String eventId) async {
    return _readAll()[eventId];
  }

  Map<String, PendingNotificationRecord> _readAll() {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, PendingNotificationRecord>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, PendingNotificationRecord>{};
    }
    final records = <String, PendingNotificationRecord>{};
    for (final value in decoded.values) {
      if (value is! Map) {
        continue;
      }
      final record = PendingNotificationRecord.fromJson(
        Map<String, dynamic>.from(value),
      );
      if (record != null) {
        records[record.eventId] = record;
      }
    }
    return records;
  }

  Future<void> _writeAll(Map<String, PendingNotificationRecord> records) {
    final encoded = <String, dynamic>{
      for (final record in records.values) record.eventId: record.toJson(),
    };
    return _preferences.setString(storageKey, jsonEncode(encoded));
  }
}
