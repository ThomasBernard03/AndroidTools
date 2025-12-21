part of 'information_bloc.dart';

sealed class InformationEvent {}

class OnAppearing extends InformationEvent {}

class OnRefreshDevices extends InformationEvent {}

class OnInstallApplication extends InformationEvent {
  final String applicationFilePath;

  OnInstallApplication({required this.applicationFilePath});
}
