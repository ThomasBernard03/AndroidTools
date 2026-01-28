part of 'application_installer_bloc.dart';

@MappableClass()
class ApplicationInstallerState with ApplicationInstallerStateMappable {
  final DeviceEntity? selectedDevice;
  final bool isLoading;
  final List<InstalledApplicationHistoryEntity> installedApplicationHistory;

  ApplicationInstallerState({
    this.selectedDevice,
    this.isLoading = false,
    this.installedApplicationHistory = const [],
  });
}
