part of 'information_bloc.dart';

@MappableClass()
class InformationState with InformationStateMappable {
  final bool isLoading;
  final DeviceInformationEntity? deviceInformation;
  final BatteryInfo? deviceBatteryInformation;
  final StorageInfo? deviceStorageInformation;
  final DeviceEntity? device;

  InformationState({
    this.isLoading = true,
    this.deviceInformation,
    this.device,
    this.deviceBatteryInformation,
    this.deviceStorageInformation,
  });
}
