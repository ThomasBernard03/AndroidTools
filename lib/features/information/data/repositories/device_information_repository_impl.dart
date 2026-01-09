import 'dart:io';

import 'package:android_tools/features/information/domain/entities/device_battery_information_entity.dart';
import 'package:android_tools/features/information/domain/entities/device_information_entity.dart';
import 'package:android_tools/features/information/domain/repositories/device_information_repository.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:logger/logger.dart';

class DeviceInformationRepositoryImpl implements DeviceInformationRepository {
  final Logger _logger;
  final ShellDatasource _shellDatasource;

  DeviceInformationRepositoryImpl(this._logger, this._shellDatasource);

  @override
  Future<DeviceInformationEntity> getDeviceInformation(String deviceId) async {
    final adbPath = _shellDatasource.getAdbPath();

    final process = await Process.start(adbPath, [
      '-s',
      deviceId,
      'shell',
      'getprop',
    ]);

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    process.stdout
        .transform(SystemEncoding().decoder)
        .listen(stdoutBuffer.write);
    process.stderr
        .transform(SystemEncoding().decoder)
        .listen(stderrBuffer.write);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      _logger.e('ADB error: ${stderrBuffer.toString()}');
      throw Exception('Impossible de récupérer les informations du device');
    }

    final output = stdoutBuffer.toString();
    return parseDeviceInformation(output);
  }

  DeviceInformationEntity parseDeviceInformation(String output) {
    final lines = output.split('\n');

    final Map<String, String> rawInformation = {};
    final regex = RegExp(r'^\[(.+?)\]: \[(.*?)\]$');

    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;

      final key = match.group(1);
      final value = match.group(2);

      if (key != null && value != null) {
        rawInformation[key] = value;
      }
    }

    String valueOrEmpty(String key) => rawInformation[key] ?? '';

    return DeviceInformationEntity(
      manufacturer: valueOrEmpty('ro.product.manufacturer'),
      model: valueOrEmpty('ro.product.model'),
      version: valueOrEmpty('ro.build.version.release'),
      serialNumber: valueOrEmpty('ro.serialno'),
      rawInformation: rawInformation,
    );
  }

  @override
  Future<DeviceBatteryInformationEntity?> getDeviceBatteryInformation(
    String deviceId,
  ) async {
    final adbPath = _shellDatasource.getAdbPath();

    final process = await Process.start(adbPath, [
      '-s',
      deviceId,
      'shell',
      'dumpsys',
      'battery',
    ]);

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    process.stdout
        .transform(SystemEncoding().decoder)
        .listen(stdoutBuffer.write);
    process.stderr
        .transform(SystemEncoding().decoder)
        .listen(stderrBuffer.write);

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      _logger.e('ADB error: ${stderrBuffer.toString()}');
      return null;
    }

    final output = stdoutBuffer.toString();
    return _parseBatteryInformation(output);
  }

  DeviceBatteryInformationEntity? _parseBatteryInformation(String output) {
    final lines = output.split('\n');

    int extractInt(String key) {
      final line = lines.firstWhere(
        (l) => l.trim().startsWith(key),
        orElse: () => '',
      );

      if (line.isEmpty || !line.contains(':')) {
        return -1;
      }

      return int.tryParse(line.split(':')[1].trim()) ?? -1;
    }

    final level = extractInt('level');
    final status = extractInt('status');

    if (level < 0 || status < 0) {
      _logger.w('Impossible de parser les infos batterie');
      return null;
    }

    final isCharging = status == 2 || status == 5;

    return DeviceBatteryInformationEntity(isCharging: isCharging, level: level);
  }
}
