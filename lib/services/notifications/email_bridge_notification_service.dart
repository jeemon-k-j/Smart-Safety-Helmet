import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/emergency_notification.dart';
import 'emergency_notification_service.dart';

/// Posts the emergency payload to the local SMTP bridge (DeepCrash approach).
///
/// The app holds no SMTP credentials. Recipients come from managed emergency
/// contacts in the notification payload; the bridge may fall back to TEST_EMAIL.
class EmailBridgeNotificationService implements EmergencyNotificationService {
  EmailBridgeNotificationService({
    required String bridgeBaseUrl,
    http.Client? client,
  })  : _bridgeBaseUrl = bridgeBaseUrl,
        _client = client ?? http.Client();

  final String _bridgeBaseUrl;
  final http.Client _client;

  @override
  Future<void> dispatch(EmergencyNotification notification) async {
    final base = _bridgeBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/notify');

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(notification.toMap()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Email bridge returned ${response.statusCode}: ${response.body}',
      );
    }
  }
}
