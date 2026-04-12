part of 'screenshot_preview_bloc.dart';

sealed class ScreenshotPreviewEvent {}

class OnSaveScreenshot extends ScreenshotPreviewEvent {}

class OnCopyToClipboard extends ScreenshotPreviewEvent {}

class OnDeleteScreenshot extends ScreenshotPreviewEvent {}
