import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';

class ListenConnectedDevicesUsecase {
  final DeviceRepository _deviceRepository;
  ListenConnectedDevicesUsecase(this._deviceRepository);
  Stream<List<DeviceEntity>> call() {
    return _deviceRepository.listenConnectedDevice();
  }
}
