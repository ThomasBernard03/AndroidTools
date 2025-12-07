import 'dart:convert';
import 'dart:io';

import 'package:android_tools/domain/entities/logcat_level.dart';
import 'package:android_tools/domain/repositories/logcat_repository.dart';

class LogcatRepositoryImpl implements LogcatRepository {
  @override
  Stream<String> listenLogcat(LogcatLevel? level) async* {
    final adbPath = _getAdbPath();

    final args = <String>['logcat'];

    if (level != null) {
      final letter = _mapLevel(level);
      args.add('*:$letter');
    }

    final process = await Process.start(adbPath, args);

    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }

  String _mapLevel(LogcatLevel level) {
    switch (level) {
      case LogcatLevel.verbose:
        return 'V';
      case LogcatLevel.debug:
        return 'D';
      case LogcatLevel.info:
        return 'I';
      case LogcatLevel.warning:
        return 'W';
      case LogcatLevel.error:
        return 'E';
      case LogcatLevel.fatal:
        return 'F';
    }
  }

  String _getAdbPath() {
    final execDir = Directory(Platform.resolvedExecutable).parent;
    final contents = execDir.parent;
    final resources = Directory("${contents.path}/Resources");
    return "${resources.path}/adb";
  }

  @override
  Future<void> clearLogcat() async {
    try {
      final adbPath = _getAdbPath();
      // Execute la commande pour clear le logcat sur l'appareil
      final process = await Process.run(adbPath, ['logcat', '-c']);
      if (process.exitCode != 0) {
        print('Erreur lors du clear logcat : ${process.stderr}');
      } else {
        print('Logcat cleared successfully');
      }
    } catch (e) {
      print('Exception clearing logcat: $e');
    }
  }
}
