/// User-managed emergency contact stored under `users/{uid}/emergencyContacts`.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  factory EmergencyContact.fromMap(String id, Map<dynamic, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString().trim(),
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'email': email,
        if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
      };

  static DateTime? _toDate(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }
}
