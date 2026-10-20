import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';

void main() {
  test('project test harness loads', () {
    expect(AccidentSeverity.low.wireValue, 'low');
  });
}
