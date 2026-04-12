part of 'screenshot_preview_bloc.dart';

enum ScreenshotStatus { idle, loading, success, error }

@MappableClass()
class ScreenshotPreviewState with ScreenshotPreviewStateMappable {
  final ScreenshotStatus status;
  final ScreenshotEntity screenshot;
  final DeviceEntity device;
  final String? errorMessage;
  final String? successMessage;

  ScreenshotPreviewState({
    required this.status,
    required this.screenshot,
    required this.device,
    this.errorMessage,
    this.successMessage,
  });
}
