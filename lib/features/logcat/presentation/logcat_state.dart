part of 'logcat_bloc.dart';

@MappableClass()
class LogcatState with LogcatStateMappable {
  final List<String> logs;
  final bool isSticky;
  final bool isPaused;
  final int maxLogcatLines;
  final LogcatLevel minimumLogLevel;
  final List<DeviceEntity> devices;
  final DeviceEntity? selectedDevice;
  final List<ProcessEntity> processes;
  final ProcessEntity? selectedProcess;

  LogcatState({
    this.logs = const [],
    this.isSticky = true,
    this.isPaused = false,
    this.minimumLogLevel = LogcatLevel.debug,
    this.maxLogcatLines = 500,
    this.devices = const [],
    this.selectedDevice,
    this.processes = const [],
    this.selectedProcess,
  });
}
