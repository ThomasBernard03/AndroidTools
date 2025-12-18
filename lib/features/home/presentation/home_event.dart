part of 'home_bloc.dart';

sealed class HomeEvent {}

class OnAppearing extends HomeEvent {}

class OnDeviceSelected extends HomeEvent {
  final DeviceEntity device;

  OnDeviceSelected({required this.device});
}
