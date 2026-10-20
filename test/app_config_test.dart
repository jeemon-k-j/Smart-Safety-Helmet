import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/config/app_config.dart';

void main() {
  test('Firebase is unconfigured without dart-defines', () {
    expect(AppConfig.hasFirebaseConfig, isFalse);
    expect(AppConfig.firebaseOptionsOrNull, isNull);
  });

  test('default device id and email bridge URL are non-secret defaults', () {
    expect(AppConfig.defaultDeviceId, isNotEmpty);
    expect(AppConfig.emailBridgeUrl, contains('http'));
  });
}
