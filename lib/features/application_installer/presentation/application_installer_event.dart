part of 'application_installer_bloc.dart';

sealed class ApplicationInstallerEvent {}

class OnAppearing extends ApplicationInstallerEvent {}

class OnInstallApk extends ApplicationInstallerEvent {
  final String apkPath;

  OnInstallApk({required this.apkPath});
}
