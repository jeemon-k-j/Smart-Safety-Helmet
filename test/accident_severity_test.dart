import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';

void main() {
  test('severity countdown durations', () {
    expect(AccidentSeverity.low.countdown, const Duration(seconds: 30));
    expect(AccidentSeverity.medium.countdown, const Duration(seconds: 20));
    expect(AccidentSeverity.high.countdown, const Duration(seconds: 10));
  });

  test('fromWire parsing', () {
    expect(AccidentSeverity.fromWire('HIGH'), AccidentSeverity.high);
    expect(AccidentSeverity.fromWire('medium'), AccidentSeverity.medium);
    expect(AccidentSeverity.fromWire(null), AccidentSeverity.low);
  });
}
