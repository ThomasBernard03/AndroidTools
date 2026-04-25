part of 'apk_inspector_bloc.dart';

/// Base class for all APK Inspector events
sealed class ApkInspectorEvent {}

/// Event triggered when user selects an APK file (via picker or drag-drop)
class OnSelectApkFile extends ApkInspectorEvent {
  final String apkPath;

  OnSelectApkFile({required this.apkPath});
}

/// Event triggered to reset the view back to the import screen
class OnResetView extends ApkInspectorEvent {}

/// Event triggered to install the current APK to a device
class OnInstallApk extends ApkInspectorEvent {
  final String deviceId;

  OnInstallApk({required this.deviceId});
}

/// Event triggered to load recent APKs
class OnLoadRecentApks extends ApkInspectorEvent {}

/// Event triggered when user selects a recent APK from the list
class OnSelectRecentApk extends ApkInspectorEvent {
  final String apkPath;

  OnSelectRecentApk({required this.apkPath});
}
