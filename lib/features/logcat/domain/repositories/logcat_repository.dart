import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';

abstract class LogcatRepository {
  Stream<Iterable<String>> listenLogcat(
    String deviceId,
    LogcatLevel? level,
    int? processId,
  );
  Future<void> clearLogcat(String deviceId);
  Future<List<ProcessEntity>> getProcesses(String deviceId);
}
