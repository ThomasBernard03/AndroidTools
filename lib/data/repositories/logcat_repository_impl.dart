import 'dart:convert';
import 'dart:io';

import 'package:android_tools/domain/repositories/logcat_repository.dart';

class LogcatRepositoryImpl implements LogcatRepository {
  @override
  Stream<String> listenLogcat() async* {
    final adbPath = _getAdbPath();
    final process = await Process.start(adbPath, ['logcat']);
    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
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
