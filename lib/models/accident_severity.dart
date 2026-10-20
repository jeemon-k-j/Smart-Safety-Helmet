/// Accident severity reported by ESP32; drives false-alert countdown length.
enum AccidentSeverity {
  low,
  medium,
  high;

  /// Countdown before emergency emails are sent.
  Duration get countdown {
    return switch (this) {
      AccidentSeverity.low => const Duration(seconds: 30),
      AccidentSeverity.medium => const Duration(seconds: 20),
      AccidentSeverity.high => const Duration(seconds: 10),
    };
  }

  static AccidentSeverity fromWire(Object? value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    return switch (text) {
      'high' => AccidentSeverity.high,
      'medium' || 'med' => AccidentSeverity.medium,
      _ => AccidentSeverity.low,
    };
  }

  String get wireValue => name;
}
