import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/features/logcat/domain/entities/logcat_level.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';
import 'package:logger/logger.dart';

class LogcatRepositoryImpl implements LogcatRepository {
  final Logger _logger;
  final ShellDatasource _shellDatasource;

  LogcatRepositoryImpl(this._logger, this._shellDatasource);

  @override
  Stream<List<String>> listenLogcat(
    String deviceId,
    LogcatLevel? level,
    int? processId,
  ) async* {
    if (deviceId.isEmpty) {
      _logger.w("Device id can't be empty, can't listen for logs");
      return;
    }

    final adbPath = _shellDatasource.getAdbPath();

    final args = <String>['-s', deviceId, 'logcat'];

    if (level != null) {
      args.add('*:${_mapLevel(level)}');
    }

    if (processId != null) {
      args.addAll(['--pid', processId.toString()]);
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
              timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
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
      _logger.i("Cleaning logcat");
      final adbPath = _shellDatasource.getAdbPath();
      final process = await Process.run(adbPath, [
        '-s',
        deviceId,
        'logcat',
        '-c',
      ]);
      if (process.exitCode != 0) {
        _logger.w("Error when clearing logcat : ${process.stderr}");
      } else {
        _logger.i("Logcat cleared successfully");
      }
    } catch (e) {
      _logger.w('Exception clearing logcat: $e');
    }
  }

  @override
  Future<List<ProcessEntity>> getProcesses(String deviceId) async {
    try {
      final adbPath = _shellDatasource.getAdbPath();

      final result = await Process.run(adbPath, [
        '-s',
        deviceId,
        'shell',
        'sh',
        '-c',
        'ps -A',
      ]);

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return [];

      final lines = output.split('\n');
      final processes = <ProcessEntity>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.contains('PID') || line.contains('USER')) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;

        // PID
        final pid = int.tryParse(parts[1]);
        if (pid == null) continue;

        final processName = parts.last;

        // Filtrer les process inutiles
        if (_shouldIgnoreProcess(processName)) continue;

        processes.add(ProcessEntity(processId: pid, packageName: processName));
      }

      return processes;
    } catch (e) {
      _logger.w('Exception getting processes: $e');
      return [];
    }
  }

  bool _shouldIgnoreProcess(String name) {
    // 1. Threads noyau
    if (name.startsWith('[') && name.endsWith(']')) return true;

    // 2. HAL / vendor
    if (name.startsWith('vendor.')) return true;
    if (name.startsWith('android.hardware.')) return true;

    // 3. Binaires natifs connus (non exhaustif, mais efficace)
    const ignoreList = [
      'init',
      'logd',
      'adbd',
      'ps',
      'wpa_supplicant',
      'sh',
      'ip6tables-restore',
      'iptables-restore',
      'thermal',
      'rild',
      'artd',
      'pageboostd',
    ];
    if (ignoreList.contains(name)) return true;

    // 4. Ce ne sont PAS des apps → noms sans point
    // (ex: kworker, netd, system_server…)
    if (!name.contains('.')) return true;

    return false;
  }
}
