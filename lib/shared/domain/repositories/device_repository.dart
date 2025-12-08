import 'package:android_tools/shared/domain/entities/device_entity.dart';

abstract class DeviceRepository {
  Future<List<DeviceEntity>> getConnectedDevices();
}
