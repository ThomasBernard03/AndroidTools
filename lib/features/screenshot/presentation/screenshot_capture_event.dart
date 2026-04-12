part of 'screenshot_capture_bloc.dart';

sealed class ScreenshotCaptureEvent {}

class OnCaptureScreenshot extends ScreenshotCaptureEvent {
  final String deviceId;

  OnCaptureScreenshot(this.deviceId);
}

class OnResetState extends ScreenshotCaptureEvent {}
