import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';

class GetConnectedDevicesUsecase {
  final DeviceRepository deviceRepository;
  const GetConnectedDevicesUsecase({required this.deviceRepository});

  Future<List<DeviceEntity>> call() {
    return deviceRepository.getConnectedDevices();
  }
}
