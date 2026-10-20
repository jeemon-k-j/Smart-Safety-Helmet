import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_helmet/utils/email_validation.dart';
import 'package:smart_safety_helmet/utils/formatters.dart';

void main() {
  test('validates emergency recipient emails', () {
    expect(isValidEmergencyEmail('care@example.com'), isTrue);
    expect(isValidEmergencyEmail(' bad@example.com '), isTrue);
    expect(isValidEmergencyEmail('nodomain@'), isFalse);
    expect(isValidEmergencyEmail('a@b'), isFalse);
    expect(isValidEmergencyEmail('a@b,c@d.com'), isFalse);
    expect(isValidEmergencyEmail(null), isFalse);
  });

  test('builds google maps location link without API key', () {
    expect(
      googleMapsUrl(9.9312, 76.2673),
      'https://maps.google.com/?q=9.9312,76.2673',
    );
  });
}
