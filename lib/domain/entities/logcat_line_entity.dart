import 'package:android_tools/domain/entities/logcat_level.dart';

class LogcatLineEntity {
  final DateTime dateTime;
  final LogcatLevel level;

  final int processId;
  final int threadId;

  final String packageName;

  const LogcatLineEntity({
    required this.dateTime,
    required this.level,
    required this.processId,
    required this.threadId,
    required this.packageName,
  });
}
