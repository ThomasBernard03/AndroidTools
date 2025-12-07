import 'package:android_tools/domain/repositories/logcat_repository.dart';

class ClearLogcatUsecase {
  final LogcatRepository logcatRepository;
  const ClearLogcatUsecase({required this.logcatRepository});

  Future<void> call() {
    return logcatRepository.clearLogcat();
  }
}
