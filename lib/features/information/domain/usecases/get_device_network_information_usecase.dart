import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceNetworkInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceNetworkInformationUsecase(this._deviceInformationRepository);

  Future<NetworkInfo?> call(String deviceId) {
    return _deviceInformationRepository.getDeviceNetworkInformation(deviceId);
  }
}
