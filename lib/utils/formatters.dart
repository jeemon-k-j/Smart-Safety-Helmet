/// Small formatting helpers adapted from DeepCrash (no intl dependency).
library;

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatCoordinate(double value) => value.toStringAsFixed(5);

String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = _monthNames[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '$day $month ${local.year}, $hour:$minute:$second';
}

/// Formats a UTC/local instant for display in India Standard Time (UTC+5:30),
/// 12-hour clock with am/pm. Stored timestamps are unchanged.
String formatDateTimeIst(DateTime dateTime) {
  final ist = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
  final day = ist.day.toString().padLeft(2, '0');
  final month = _monthNames[ist.month - 1];
  final hour24 = ist.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = ist.minute.toString().padLeft(2, '0');
  final second = ist.second.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'am' : 'pm';
  return '$day $month ${ist.year}, $hour12:$minute:$second $period IST';
}

/// Google Maps link for an accident location (phone GPS).
String googleMapsUrl(double latitude, double longitude) {
  return 'https://maps.google.com/?q=$latitude,$longitude';
}
