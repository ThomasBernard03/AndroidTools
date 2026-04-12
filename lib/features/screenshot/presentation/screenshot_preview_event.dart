part of 'screenshot_preview_bloc.dart';

sealed class ScreenshotPreviewEvent {}

class OnCaptureScreenshot extends ScreenshotPreviewEvent {
  final String deviceId;
  final DeviceEntity device;

  OnCaptureScreenshot({required this.deviceId, required this.device});
}

class OnResetState extends ScreenshotPreviewEvent {}

class OnSaveScreenshot extends ScreenshotPreviewEvent {}

class OnCopyToClipboard extends ScreenshotPreviewEvent {}

class OnDeleteScreenshot extends ScreenshotPreviewEvent {}
