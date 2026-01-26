import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceDisplayInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceDisplayInformationUsecase(this._deviceInformationRepository);

  Future<DisplayInfo?> call(String deviceId) {
    return _deviceInformationRepository.getDeviceDisplayInformation(deviceId);
  }
}
