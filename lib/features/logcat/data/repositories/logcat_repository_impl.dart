import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';
import 'package:logger/logger.dart';

class LogcatRepositoryImpl implements LogcatRepository {
  final Logger logger;
  final ShellDatasource shellDatasource;

  LogcatRepositoryImpl({required this.logger, required this.shellDatasource});

  @override
  Stream<List<String>> listenLogcat(
    String deviceId,
    LogcatLevel? level,
  ) async* {
    if (deviceId.isEmpty) {
      logger.w("Device id can't be empty, can't listen for logs");
      return;
    }

    final adbPath = shellDatasource.getAdbPath();
    final args = <String>['-s', deviceId, 'logcat'];

    if (level != null) {
      args.add('*:${_mapLevel(level)}');
    }

    final process = await Process.start(adbPath, args);

    final buffer = <String>[];
    final controller = StreamController<List<String>>();

    Timer? timer;

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            buffer.add(line);

            if (timer == null || !timer!.isActive) {
              timer = Timer.periodic(Duration(milliseconds: 500), (_) {
                if (buffer.isNotEmpty) {
                  controller.add(List.from(buffer));
                  buffer.clear();
                }
              });
            }
          },
          onDone: () {
            timer?.cancel();
            if (buffer.isNotEmpty) {
              controller.add(List.from(buffer));
            }
            controller.close();
          },
        );

    yield* controller.stream;
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

  @override
  Future<void> clearLogcat(String deviceId) async {
    try {
      logger.i("Cleaning logcat");
      final adbPath = shellDatasource.getAdbPath();
      final process = await Process.run(adbPath, [
        '-s',
        deviceId,
        'logcat',
        '-c',
      ]);
      if (process.exitCode != 0) {
        logger.w("Error when clearing logcat : ${process.stderr}");
      } else {
        logger.i("Logcat cleared successfully");
      }
    } catch (e) {
      logger.w('Exception clearing logcat: $e');
    }
  }
}
