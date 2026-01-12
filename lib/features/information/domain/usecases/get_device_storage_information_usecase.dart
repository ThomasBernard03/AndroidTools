import 'package:android_tools/features/information/domain/entities/device_storage_information_entity.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceStorageInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceStorageInformationUsecase(this._deviceInformationRepository);

  Future<DeviceStorageInformationEntity?> call(String deviceId) {
    return _deviceInformationRepository.getDeviceStorageInformation(deviceId);
  }
}
