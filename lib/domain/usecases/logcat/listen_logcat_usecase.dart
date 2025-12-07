import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/domain/repositories/logcat_repository.dart';

class ListenLogcatUsecase {
  final LogcatRepository logcatRepository;
  const ListenLogcatUsecase({required this.logcatRepository});

  Stream<List<String>> call(String deviceId, LogcatLevel? level) {
    return logcatRepository.listenLogcat(deviceId, level);
  }
}
