part of 'information_bloc.dart';

@MappableClass()
class InformationState with InformationStateMappable {
  final DeviceInformationEntity? deviceInformation;

  InformationState({this.deviceInformation});
}
