part of 'information_bloc.dart';

@MappableClass()
class InformationState with InformationStateMappable {
  final DeviceInformationEntity? deviceInformation;
  final DeviceBatteryInformationEntity? deviceBatteryInformation;
  final DeviceEntity? device;

  InformationState({
    this.deviceInformation,
    this.device,
    this.deviceBatteryInformation,
  });
}
