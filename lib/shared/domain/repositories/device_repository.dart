import 'package:android_tools/shared/domain/entities/device_entity.dart';

abstract class DeviceRepository {
  Future<void> setSelectedDevice(DeviceEntity device);
  Future<void> refreshConnectedDevices();

  Stream<DeviceEntity?> listenSelectedDevice();
  Stream<List<DeviceEntity>> listenConnectedDevice();
}
