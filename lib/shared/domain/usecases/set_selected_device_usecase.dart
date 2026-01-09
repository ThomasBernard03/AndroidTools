import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';

class SetSelectedDeviceUsecase {
  final DeviceRepository _deviceRepository;

  SetSelectedDeviceUsecase(this._deviceRepository);

  Future<void> call(DeviceEntity selectedDevice) {
    return _deviceRepository.setSelectedDevice(selectedDevice);
  }
}
