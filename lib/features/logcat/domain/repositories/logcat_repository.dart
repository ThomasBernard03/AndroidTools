import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';

abstract class LogcatRepository {
  Stream<List<String>> listenLogcat(String deviceId, LogcatLevel? level);
  Future<void> clearLogcat(String deviceId);
}
