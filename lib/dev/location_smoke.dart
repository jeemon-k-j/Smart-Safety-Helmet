import 'package:flutter/widgets.dart';

import '../services/location/geolocator_location_service.dart';
import '../services/location/phone_location_resolver.dart';
import '../utils/formatters.dart';

/// One-shot emulator/device check for phone GPS.
///
///   flutter run -d emulator-5554 -t lib/dev/location_smoke.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final resolver = PhoneLocationResolver(
    locationService: GeolocatorLocationService(),
  );

  try {
    final fix = await resolver.resolve();
    final maps = googleMapsUrl(
      fix.position.latitude,
      fix.position.longitude,
    );
    // ignore: avoid_print
    print(
      'LOCATION_SMOKE ok source=${fix.locationSource} '
      'lat=${fix.position.latitude} lon=${fix.position.longitude} '
      'accuracy=${fix.position.accuracyMeters} maps=$maps',
    );
  } catch (error) {
    // ignore: avoid_print
    print('LOCATION_SMOKE failed: $error');
  }
}
