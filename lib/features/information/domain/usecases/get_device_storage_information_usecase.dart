import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceStorageInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceStorageInformationUsecase(this._deviceInformationRepository);

  Future<StorageInfo?> call(String deviceId) {
    return _deviceInformationRepository.getDeviceStorageInformation(deviceId);
  }
}
