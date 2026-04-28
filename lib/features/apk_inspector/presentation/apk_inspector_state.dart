part of 'apk_inspector_bloc.dart';

/// Status of the APK Inspector feature
enum ApkInspectorStatus {
  /// Initial state, showing import view
  idle,

  /// Parsing APK file
  parsing,

  /// APK parsed successfully, showing report
  ready,

  /// Installing APK to device
  installing,

  /// APK installed successfully
  installed,

  /// Error occurred
  error,
}

/// State for the APK Inspector feature
@MappableClass()
class ApkInspectorState with ApkInspectorStateMappable {
  final ApkInspectorStatus status;
  final ApkInfo? apkInfo;
  final String? errorMessage;
  final List<ApkInfo> recentApks;
  final DeviceEntity? selectedDevice;

  const ApkInspectorState({
    this.status = ApkInspectorStatus.idle,
    this.apkInfo,
    this.errorMessage,
    this.recentApks = const [],
    this.selectedDevice,
  });

  factory ApkInspectorState.initial() => const ApkInspectorState();
}
