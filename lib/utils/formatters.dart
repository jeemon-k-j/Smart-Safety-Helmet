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

/// Google Maps link for an accident location (phone GPS).
String googleMapsUrl(double latitude, double longitude) {
  return 'https://maps.google.com/?q=$latitude,$longitude';
}
