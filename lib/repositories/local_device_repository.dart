import 'dart:async';

import '../models/device_status.dart';
import 'device_repository.dart';

/// Holds the last known status without Firebase.
///
/// Starts as [DeviceStatus.unavailable]. Tests / UI inspection may call
/// [publish]; the product UI has no simulator controls.
class LocalDeviceRepository implements DeviceRepository {
  LocalDeviceRepository({
    required this.deviceId,
    DeviceStatus initial = DeviceStatus.unavailable,
  }) : _status = initial;

  @override
  final String deviceId;

  DeviceStatus _status;
  final StreamController<DeviceStatus> _controller =
      StreamController<DeviceStatus>.broadcast();

  @override
  Stream<DeviceStatus> watchStatus() async* {
    yield _status;
    yield* _controller.stream;
  }

  void publish(DeviceStatus status) {
    _status = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
