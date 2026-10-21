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
/// The app holds no SMTP credentials. Delivery uses the bridge's fixed
/// server-side emergency recipient; payload recipient lists are ignored.
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

      _ensureDeliverySucceeded(response);
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

  /// Accepts bridge delivery results (`sent`, `duplicate-skipped`).
  /// Rejects SMTP failures and unexpected payloads.
  void _ensureDeliverySucceeded(http.Response response) {
    final code = response.statusCode;
    String? status;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        status = decoded['status']?.toString();
      }
    } catch (_) {
      status = null;
    }

    if (code >= 200 && code < 300) {
      if (status == 'sent' || status == 'duplicate-skipped') {
        return;
      }
      if (status == 'send-failed') {
        throw EmailBridgeException(
          'Emergency email could not be delivered. Try again later.',
        );
      }
      // Older bridge builds may omit status on success.
      if (status == null || status.isEmpty) {
        return;
      }
      throw EmailBridgeException(
        'Emergency email service returned an unexpected result.',
      );
    }

    if (status == 'send-failed' || code == 502) {
      throw EmailBridgeException(
        'Emergency email could not be delivered. Try again later.',
      );
    }
    if (code == 500) {
      throw EmailBridgeException(
        'Emergency email service is not ready. Try again later.',
      );
    }
    throw EmailBridgeException(
      'Emergency email service returned an error ($code).',
    );
  }
}
