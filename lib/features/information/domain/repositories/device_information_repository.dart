import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';

abstract class DeviceInformationRepository {
  Future<DeviceInformationEntity> getDeviceInformation(String deviceId);
  Future<BatteryInfo?> getDeviceBatteryInformation(String deviceId);
  Future<StorageInfo?> getDeviceStorageInformation(String deviceId);
  Future<DisplayInfo?> getDeviceDisplayInformation(String deviceId);
  Future<NetworkInfo?> getDeviceNetworkInformation(String deviceId);
}
