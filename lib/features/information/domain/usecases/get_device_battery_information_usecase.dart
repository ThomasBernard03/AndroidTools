import 'package:android_tools/features/information/domain/entities/device_battery_information_entity.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceBatteryInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceBatteryInformationUsecase(this._deviceInformationRepository);

  Future<DeviceBatteryInformationEntity?> call(String deviceId) {
    return _deviceInformationRepository.getDeviceBatteryInformation(deviceId);
  }
}
