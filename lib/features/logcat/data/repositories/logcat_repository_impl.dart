import 'dart:async';
import 'dart:io';

import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';
import 'package:logger/logger.dart';

class LogcatRepositoryImpl implements LogcatRepository {
  final Logger _logger;
  final ShellDatasource _shellDatasource;

  LogcatRepositoryImpl(this._logger, this._shellDatasource);

  @override
  Stream<Iterable<String>> listenLogcat(
    String deviceId,
    LogcatLevel? level,
    int? processId,
  ) {
    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    return adbClient.listenLogcat(deviceId, level: level, processId: processId);
  }

  @override
  Future<void> clearLogcat(String deviceId) async {
    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    adbClient.clearLogcat(deviceId);
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
