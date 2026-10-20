/// Build-time configuration for Smart Safety Helmet.
///
/// Inject values with:
///   flutter run --dart-define-from-file=dart_defines.json
///
/// See `dart_defines.example.json`. Real secrets stay out of source control.
class AppConfig {
  AppConfig._();

  /// Default linked ESP32 / helmet device id used by the dashboard stream.
  static const String defaultDeviceId = String.fromEnvironment(
    'DEVICE_ID',
    defaultValue: 'helmet-001',
  );

  /// Local development SMTP email bridge URL (adapted from DeepCrash).
  ///
  /// Android emulator loopback default: `http://10.0.2.2:3000`.
  /// On a physical device, point at your PC LAN IP.
  static const String emailBridgeUrl = String.fromEnvironment(
    'EMAIL_BRIDGE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
