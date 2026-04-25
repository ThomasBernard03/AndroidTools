import 'package:android_tools/features/screenshot/domain/entities/screenshot_entity.dart';

abstract class ScreenshotRepository {
  /// Captures screenshot from device and saves to temp directory
  Future<ScreenshotEntity> takeScreenshot(String deviceId);

  /// Saves screenshot from temp to user-selected location
  Future<void> saveScreenshot(String sourcePath, String destinationPath);

  /// Copies screenshot image to system clipboard
  Future<void> copyToClipboard(String filePath);

  /// Deletes screenshot file
  Future<void> deleteScreenshot(String filePath);
}
