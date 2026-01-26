import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';

class ListenLogcatUsecase {
  final LogcatRepository logcatRepository;
  const ListenLogcatUsecase({required this.logcatRepository});

  Stream<Iterable<String>> call(
    String deviceId,
    LogcatLevel? level,
    int? processId,
  ) {
    return logcatRepository.listenLogcat(deviceId, level, processId);
  }
}
