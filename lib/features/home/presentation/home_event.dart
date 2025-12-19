part of 'home_bloc.dart';

sealed class HomeEvent {}

class OnGetVersion extends HomeEvent {}

class OnListenConnectedDevices extends HomeEvent {}

class OnListenSelectedDevice extends HomeEvent {}

class OnDeviceSelected extends HomeEvent {
  final DeviceEntity device;

  OnDeviceSelected({required this.device});
}

class OnRefreshDevices extends HomeEvent {}
