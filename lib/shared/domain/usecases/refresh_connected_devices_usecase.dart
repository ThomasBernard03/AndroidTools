import 'package:android_tools/shared/domain/repositories/device_repository.dart';

class RefreshConnectedDevicesUsecase {
  final DeviceRepository _deviceRepository;

  RefreshConnectedDevicesUsecase(this._deviceRepository);

  Future<void> call() {
    return _deviceRepository.refreshConnectedDevices();
  }
}
