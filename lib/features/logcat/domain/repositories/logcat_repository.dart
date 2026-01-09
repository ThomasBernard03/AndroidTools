import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';

abstract class LogcatRepository {
  Stream<List<String>> listenLogcat(
    String deviceId,
    LogcatLevel? level,
    int? processId,
  );
  Future<void> clearLogcat(String deviceId);
  Future<List<ProcessEntity>> getProcesses(String deviceId);
}
