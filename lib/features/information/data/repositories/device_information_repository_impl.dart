import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';

class DeviceInformationRepositoryImpl implements DeviceInformationRepository {
  final AdbClient _adbClient;

  DeviceInformationRepositoryImpl(this._adbClient);

  @override
  Future<DeviceInformationEntity> getDeviceInformation(String deviceId) async {
    try {
      final properties = await _adbClient.getProperties(deviceId);

      DisplayInfo? displayInfo;
      try {
        displayInfo = await _adbClient.getDisplayInfo(deviceId);
      } catch (_) {}

      return DeviceInformationEntity(
        manufacturer: properties['ro.product.manufacturer'] ?? "",
        model: properties['ro.product.model'] ?? "",
        version: properties['ro.build.version.release'] ?? "",
        serialNumber: properties['ro.serialno'] ?? "",
        rawInformation: properties,
        screenWidth: displayInfo?.widthPixels,
        screenHeight: displayInfo?.heightPixels,
      );
    } on FormatException catch (e) {
      // Handle UTF-8 decoding errors from ADB output
      throw Exception(
        'Failed to decode device properties (invalid UTF-8 data): ${e.message}',
      );
    }
  }

  @override
  Future<BatteryInfo?> getDeviceBatteryInformation(String deviceId) async {
    try {
      return await _adbClient.getBatteryInfo(deviceId);
    } on FormatException catch (e) {
      // Handle UTF-8 decoding errors from ADB output
      throw Exception(
        'Failed to decode battery info (invalid UTF-8 data): ${e.message}',
      );
    }
  }
}
