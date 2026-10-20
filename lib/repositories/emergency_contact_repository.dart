import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/emergency_contact.dart';

/// CRUD for `users/{uid}/emergencyContacts` in RTDB.
class EmergencyContactRepository {
  EmergencyContactRepository({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance;

  final FirebaseAuth _auth;
  final FirebaseDatabase _database;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    return user.uid;
  }

  DatabaseReference get _contactsRef =>
      _database.ref('users/$_uid/emergencyContacts');

  Stream<List<EmergencyContact>> watchContacts() {
    return _contactsRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return const <EmergencyContact>[];
      }
      final contacts = <EmergencyContact>[];
      value.forEach((key, raw) {
        if (raw is Map) {
          contacts.add(
            EmergencyContact.fromMap(
              key.toString(),
              Map<dynamic, dynamic>.from(raw),
            ),
          );
        }
      });
      contacts.sort((a, b) => a.name.compareTo(b.name));
      return contacts;
    });
  }

  Future<List<EmergencyContact>> listContacts() async {
    final snapshot = await _contactsRef.get();
    final value = snapshot.value;
    if (value is! Map) {
      return const <EmergencyContact>[];
    }
    final contacts = <EmergencyContact>[];
    value.forEach((key, raw) {
      if (raw is Map) {
        contacts.add(
          EmergencyContact.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(raw),
          ),
        );
      }
    });
    return contacts;
  }

  Future<void> addContact({required String name, required String email}) async {
    final ref = _contactsRef.push();
    await ref.set(<String, Object?>{
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> removeContact(String id) async {
    await _contactsRef.child(id).remove();
  }
}
