part of 'home_bloc.dart';

@MappableClass()
class HomeState with HomeStateMappable {
  final String version;
  final Iterable<DeviceEntity> devices;
  final DeviceEntity? selectedDevice;

  HomeState({this.version = "", this.devices = const [], this.selectedDevice});
}
