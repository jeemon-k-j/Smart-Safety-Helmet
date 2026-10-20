/// Lightweight email checks for emergency recipients (app-side only).
bool isValidEmergencyEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || email.contains(',') || email.contains(';')) {
    return false;
  }
  final at = email.indexOf('@');
  if (at <= 0 || at != email.lastIndexOf('@')) {
    return false;
  }
  final domain = email.substring(at + 1);
  return domain.contains('.') && !domain.startsWith('.') && !domain.endsWith('.');
}
