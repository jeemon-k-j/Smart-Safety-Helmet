import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/models/device_status.dart';

void main() {
  test('parses RTDB status map', () {
    final status = DeviceStatus.fromMap(<String, Object?>{
      'alcoholDetected': true,
      'helmetClipped': false,
      'ignitionAllowed': false,
      'ignitionActive': false,
      'drowsy': true,
      'warningActive': true,
      'updatedAt': 1710000000000,
    });

    expect(status.alcoholDetected, isTrue);
    expect(status.helmetClipped, isFalse);
    expect(status.drowsy, isTrue);
    expect(status.updatedAt, isNotNull);
  });
}
