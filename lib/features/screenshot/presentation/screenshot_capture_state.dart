part of 'screenshot_capture_bloc.dart';

enum ScreenshotCaptureStatus { idle, capturing, success, error }

@MappableClass()
class ScreenshotCaptureState with ScreenshotCaptureStateMappable {
  final ScreenshotCaptureStatus status;
  final ScreenshotEntity? screenshot;
  final String? errorMessage;

  const ScreenshotCaptureState({
    required this.status,
    this.screenshot,
    this.errorMessage,
  });
}
