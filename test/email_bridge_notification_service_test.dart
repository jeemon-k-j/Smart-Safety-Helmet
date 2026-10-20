import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_safety_helmet/models/accident_severity.dart';
import 'package:smart_safety_helmet/models/emergency_notification.dart';
import 'package:smart_safety_helmet/services/notifications/email_bridge_notification_service.dart';

void main() {
  final note = EmergencyNotification.forAccident(
    eventId: 'acc-bridge',
    severity: AccidentSeverity.low,
    recipients: const ['care@example.com'],
  );

  test('dispatch succeeds on 200', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/notify');
      expect(jsonDecode(request.body)['eventId'], 'acc-bridge');
      return http.Response('{"status":"sent"}', 200);
    });

    final service = EmailBridgeNotificationService(
      bridgeBaseUrl: 'http://10.0.2.2:3000',
      client: client,
    );
    await service.dispatch(note);
  });

  test('dispatch maps non-2xx to EmailBridgeException', () async {
    final client = MockClient((request) async {
      return http.Response('nope', 502);
    });
    final service = EmailBridgeNotificationService(
      bridgeBaseUrl: 'http://10.0.2.2:3000',
      client: client,
    );
    expect(
      () => service.dispatch(note),
      throwsA(isA<EmailBridgeException>()),
    );
  });
}
