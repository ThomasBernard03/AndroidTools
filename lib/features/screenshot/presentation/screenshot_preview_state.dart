part of 'screenshot_preview_bloc.dart';

enum ScreenshotStatus { idle, capturing, loading, success, error }

@MappableClass()
class ScreenshotPreviewState with ScreenshotPreviewStateMappable {
  final ScreenshotStatus status;
  final ScreenshotEntity? screenshot;
  final DeviceEntity? device;
  final String? errorMessage;
  final String? successMessage;

  const ScreenshotPreviewState({
    required this.status,
    this.screenshot,
    this.device,
    this.errorMessage,
    this.successMessage,
  });
}
