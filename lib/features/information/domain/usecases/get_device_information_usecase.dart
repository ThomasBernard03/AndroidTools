import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceInformationUsecase(this._deviceInformationRepository);

  Future<DeviceInformationEntity> call(String deviceId) {
    return _deviceInformationRepository.getDeviceInformation(deviceId);
  }
}
