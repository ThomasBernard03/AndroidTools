import 'package:android_tools/features/screenshot/domain/entities/screenshot_entity.dart';
import 'package:android_tools/features/screenshot/domain/repositories/screenshot_repository.dart';

class TakeScreenshotUsecase {
  final ScreenshotRepository _repository;

  TakeScreenshotUsecase(this._repository);

  Future<ScreenshotEntity> call(String deviceId) async {
    return await _repository.takeScreenshot(deviceId);
  }
}
