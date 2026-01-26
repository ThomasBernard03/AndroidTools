import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';

class DeviceInformationRepositoryImpl implements DeviceInformationRepository {
  final ShellDatasource _shellDatasource;

  DeviceInformationRepositoryImpl(this._shellDatasource);

  @override
  Future<StorageInfo?> getDeviceStorageInformation(String deviceId) async {
    final adbPath = _shellDatasource.getAdbPath();
    final adbClient = AdbClient(adbExecutablePath: adbPath);
    final info = await adbClient.getStorageInfo(deviceId);
    return info.firstOrNull;
  }

  @override
  Future<DeviceInformationEntity> getDeviceInformation(String deviceId) async {
    final adbPath = _shellDatasource.getAdbPath();
    final adbClient = AdbClient(adbExecutablePath: adbPath);
    final properties = await adbClient.getProperties(deviceId);

    return DeviceInformationEntity(
      manufacturer: properties['ro.product.manufacturer'] ?? "",
      model: properties['ro.product.model'] ?? "",
      version: properties['ro.build.version.release'] ?? "",
      serialNumber: properties['ro.serialno'] ?? "",
      rawInformation: properties,
    );
  }

  @override
  Future<BatteryInfo?> getDeviceBatteryInformation(String deviceId) {
    final adbPath = _shellDatasource.getAdbPath();
    final adbClient = AdbClient(adbExecutablePath: adbPath);
    return adbClient.getBatteryInfo(deviceId);
  }
}
