import 'dart:io';

import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/screenshot/domain/entities/screenshot_entity.dart';
import 'package:android_tools/features/screenshot/domain/repositories/screenshot_repository.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

class ScreenshotRepositoryImpl implements ScreenshotRepository {
  final AdbClient _adbClient;
  final Logger _logger;

  ScreenshotRepositoryImpl(this._adbClient, this._logger);

  @override
  Future<ScreenshotEntity> takeScreenshot(String deviceId) async {
    try {
      _logger.i('Taking screenshot for device: $deviceId');

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final screenshotDir = Directory(p.join(tempDir.path, 'screenshots'));

      // Create directory if it doesn't exist
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(recursive: true);
        _logger.d('Created screenshots directory: ${screenshotDir.path}');
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now();
      final filename = 'screenshot_${timestamp.millisecondsSinceEpoch}.png';
      final filePath = p.join(screenshotDir.path, filename);

      // Capture screenshot using adb_dart 1.2.5
      // takeScreenshot(deviceId, outputPath) writes directly to file
      await _adbClient.takeScreenshot(deviceId, filePath);

      // Read the file to get dimensions and size
      final file = File(filePath);
      final screenshotBytes = await file.readAsBytes();

      // Get image dimensions
      final image = img.decodeImage(screenshotBytes);
      final width = image?.width ?? 0;
      final height = image?.height ?? 0;

      _logger.i(
        'Screenshot captured: $filePath (${width}x$height, ${screenshotBytes.length} bytes)',
      );

      return ScreenshotEntity(
        filePath: filePath,
        timestamp: timestamp,
        width: width,
        height: height,
        sizeInBytes: screenshotBytes.length,
      );
    } catch (e, stackTrace) {
      _logger.e('Error taking screenshot', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> saveScreenshot(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      _logger.i('Saving screenshot from $sourcePath to $destinationPath');
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      _logger.i('Screenshot saved successfully');
    } catch (e, stackTrace) {
      _logger.e('Error saving screenshot', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> copyToClipboard(String filePath) async {
    try {
      _logger.i('Copying screenshot to clipboard: $filePath');
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Create clipboard item with PNG image
      final item = DataWriterItem();
      item.add(Formats.png(bytes));

      // Write to system clipboard
      await SystemClipboard.instance?.write([item]);

      _logger.i('Screenshot copied to clipboard successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'Error copying to clipboard',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteScreenshot(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('Screenshot deleted: $filePath');
      }
    } catch (e, stackTrace) {
      _logger.e('Error deleting screenshot', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
