import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';

class ListenSelectedDeviceUsecase {
  final DeviceRepository _deviceRepository;

  ListenSelectedDeviceUsecase(this._deviceRepository);

  Stream<DeviceEntity?> call() {
    return _deviceRepository.listenSelectedDevice();
  }
}
