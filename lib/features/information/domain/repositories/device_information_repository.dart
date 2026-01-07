import 'package:android_tools/features/information/domain/entities/device_battery_information_entity.dart';
import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';

abstract class DeviceInformationRepository {
  Future<DeviceInformationEntity> getDeviceInformation(String deviceId);
  Future<DeviceBatteryInformationEntity?> getDeviceBatteryInformation(
    String deviceId,
  );
}
