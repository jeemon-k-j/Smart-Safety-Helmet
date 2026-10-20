import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/emergency_notification.dart';
import 'emergency_notification_service.dart';

/// Failure talking to the DeepCrash-style local SMTP bridge.
class EmailBridgeException implements Exception {
  EmailBridgeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Posts the emergency payload to the local SMTP bridge (DeepCrash approach).
///
/// The app holds no SMTP credentials. Recipients come from managed emergency
/// contacts in the notification payload; the bridge may fall back to TEST_EMAIL.
class EmailBridgeNotificationService implements EmergencyNotificationService {
  EmailBridgeNotificationService({
    required String bridgeBaseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  })  : _bridgeBaseUrl = bridgeBaseUrl,
        _client = client ?? http.Client();

  final String _bridgeBaseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<void> dispatch(EmergencyNotification notification) async {
    final base = _bridgeBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw EmailBridgeException(
        'Emergency email service is not configured.',
      );
    }

    late final Uri uri;
    try {
      uri = Uri.parse('$base/notify');
    } catch (_) {
      throw EmailBridgeException(
        'Emergency email service address is invalid.',
      );
    }
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw EmailBridgeException(
        'Emergency email service address must use http or https.',
      );
    }

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(notification.toMap()),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      throw EmailBridgeException(
        'Emergency email service returned an error '
        '(${response.statusCode}).',
      );
    } on EmailBridgeException {
      rethrow;
    } on TimeoutException {
      throw EmailBridgeException(
        'Emergency email service timed out. Check the connection and try again.',
      );
    } on SocketException {
      throw EmailBridgeException(
        'Could not reach the emergency email service. '
        'Check the connection and try again.',
      );
    } on http.ClientException {
      throw EmailBridgeException(
        'Emergency email request failed. Check the connection and try again.',
      );
    } catch (_) {
      throw EmailBridgeException(
        'Emergency email request failed. Try again later.',
      );
    }
  }
}
