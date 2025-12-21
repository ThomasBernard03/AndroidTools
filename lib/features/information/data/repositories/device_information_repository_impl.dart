import 'dart:io';

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

    String extractValue(String key) {
      final line = lines.firstWhere((l) => l.contains(key), orElse: () => '');

      if (line.isEmpty || !line.contains(':')) {
        return '';
      }

      return line.split(':')[1].replaceAll('[', '').replaceAll(']', '').trim();
    }

    final manufacturer = extractValue('ro.product.manufacturer');
    final model = extractValue('ro.product.model');
    final version = extractValue('ro.build.version.release');
    final serial = extractValue('ro.serialno');

    return DeviceInformationEntity(
      manufacturer: manufacturer,
      model: model,
      version: version,
      serialNumber: serial,
    );
  }
}
