import 'package:dart_mappable/dart_mappable.dart';

part 'screenshot_entity.mapper.dart';

@MappableClass()
class ScreenshotEntity with ScreenshotEntityMappable {
  final String filePath;
  final DateTime timestamp;
  final int width;
  final int height;
  final int sizeInBytes;

  ScreenshotEntity({
    required this.filePath,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.sizeInBytes,
  });
}
