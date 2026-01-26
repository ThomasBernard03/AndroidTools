import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class GetDeviceBatteryInformationUsecase {
  final DeviceInformationRepository _deviceInformationRepository;

  GetDeviceBatteryInformationUsecase(this._deviceInformationRepository);

  Future<BatteryInfo?> call(String deviceId) {
    return _deviceInformationRepository.getDeviceBatteryInformation(deviceId);
  }
}
