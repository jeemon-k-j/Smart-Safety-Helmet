import '../models/emergency_contact.dart';

/// Emergency contact CRUD (RTDB or local persistence).
abstract class EmergencyContactRepository {
  Stream<List<EmergencyContact>> watchContacts();

  Future<List<EmergencyContact>> listContacts();

  Future<void> addContact({required String name, required String email});

  Future<void> removeContact(String id);
}
