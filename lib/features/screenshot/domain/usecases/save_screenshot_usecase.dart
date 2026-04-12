import 'package:android_tools/features/screenshot/domain/repositories/screenshot_repository.dart';

class SaveScreenshotUsecase {
  final ScreenshotRepository _repository;

  SaveScreenshotUsecase(this._repository);

  Future<void> call(String sourcePath, String destinationPath) async {
    await _repository.saveScreenshot(sourcePath, destinationPath);
  }
}
