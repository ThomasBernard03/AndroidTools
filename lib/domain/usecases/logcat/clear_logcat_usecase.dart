import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';

class ClearLogcatUsecase {
  final LogcatRepository logcatRepository;
  const ClearLogcatUsecase({required this.logcatRepository});

  Future<void> call(String deviceId) {
    return logcatRepository.clearLogcat(deviceId);
  }
}
