import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_contact.dart';
import 'emergency_contact_repository.dart';

/// On-device emergency contacts when RTDB credentials are unavailable.
class LocalEmergencyContactRepository implements EmergencyContactRepository {
  LocalEmergencyContactRepository({required SharedPreferences preferences})
      : _preferences = preferences {
    _contacts = _read();
  }

  static const String _storageKey = 'ssh.localContacts.v1';

  final SharedPreferences _preferences;
  final StreamController<List<EmergencyContact>> _controller =
      StreamController<List<EmergencyContact>>.broadcast();

  List<EmergencyContact> _contacts = const <EmergencyContact>[];

  @override
  Stream<List<EmergencyContact>> watchContacts() async* {
    yield List<EmergencyContact>.unmodifiable(_contacts);
    yield* _controller.stream;
  }

  @override
  Future<List<EmergencyContact>> listContacts() async {
    return List<EmergencyContact>.unmodifiable(_contacts);
  }

  @override
  Future<void> addContact({required String name, required String email}) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final next = <EmergencyContact>[
      ..._contacts,
      EmergencyContact(
        id: id,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    _contacts = next;
    await _write();
    _emit();
  }

  @override
  Future<void> removeContact(String id) async {
    _contacts = _contacts.where((c) => c.id != id).toList();
    await _write();
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<EmergencyContact>.unmodifiable(_contacts));
    }
  }

  List<EmergencyContact> _read() {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const <EmergencyContact>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <EmergencyContact>[];
    }
    final contacts = <EmergencyContact>[];
    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      final id = map['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }
      contacts.add(EmergencyContact.fromMap(id, map));
    }
    contacts.sort((a, b) => a.name.compareTo(b.name));
    return contacts;
  }

  Future<void> _write() {
    final encoded = _contacts
        .map(
          (c) => <String, Object?>{
            'id': c.id,
            ...c.toMap(),
          },
        )
        .toList();
    return _preferences.setString(_storageKey, jsonEncode(encoded));
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
