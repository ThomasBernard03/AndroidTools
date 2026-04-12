import 'package:android_tools/features/screenshot/domain/repositories/screenshot_repository.dart';

class CopyScreenshotUsecase {
  final ScreenshotRepository _repository;

  CopyScreenshotUsecase(this._repository);

  Future<void> call(String filePath) async {
    await _repository.copyToClipboard(filePath);
  }
}
