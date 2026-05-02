import 'dart:async';

import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';
import 'package:logger/logger.dart';

class LogcatRepositoryImpl implements LogcatRepository {
  final Logger _logger;
  final AdbClient _adbClient;

  LogcatRepositoryImpl(this._logger, this._adbClient);

  @override
  Stream<Iterable<String>> listenLogcat(
    String deviceId,
    LogcatLevel? level,
    int? processId,
  ) {
    return _adbClient.listenLogcat(deviceId, level: level, processId: processId);
  }

  @override
  Future<void> clearLogcat(String deviceId) async {
    _adbClient.clearLogcat(deviceId);
  }

  @override
  Future<List<ProcessEntity>> getProcesses(String deviceId) async {
    try {
      final processes = await _adbClient.getProcesses(deviceId);

      return processes
          .where((p) => !_shouldIgnoreProcess(p.packageName))
          .map((p) => ProcessEntity(
                processId: p.processId,
                packageName: p.packageName,
              ))
          .toList();
    } catch (e) {
      _logger.w('Exception getting processes: $e');
      return [];
    }
  }

  bool _shouldIgnoreProcess(String name) {
    // Kernel threads
    if (name.startsWith('[') && name.endsWith(']')) return true;

    // HAL / vendor processes
    if (name.startsWith('vendor.')) return true;
    if (name.startsWith('android.hardware.')) return true;

    // Known native binaries that are not apps
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

    // Non-app processes have no dot in their name (e.g., kworker, netd)
    if (!name.contains('.')) return true;

    return false;
  }
}
