import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';

abstract class DeviceInformationRepository {
  Future<DeviceInformationEntity> getDeviceInformation(String deviceId);
}
