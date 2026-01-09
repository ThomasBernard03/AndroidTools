import 'dart:convert';
import 'dart:io';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';
import 'package:logger/logger.dart';

class PackageRepositoryImpl implements PackageRepository {
  final Logger _logger;
  final ShellDatasource _shellDatasource;

  PackageRepositoryImpl(this._logger, this._shellDatasource);

  @override
  Future<Iterable<String>> getAllPackages(String deviceId) async {
    final adbPath = _shellDatasource.getAdbPath();

    try {
      final process = await Process.start(adbPath, [
        '-s',
        deviceId,
        'shell',
        'pm',
        'list',
        'packages',
        '-3',
      ]);

      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      if (stderr.isNotEmpty) {
        _logger.w(stderr.trim());
      }

      if (exitCode != 0) {
        _logger.e('Failed to list packages (exitCode=$exitCode)');
        return const [];
      }

      return stdout
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.startsWith('package:'))
          .map((line) => line.substring('package:'.length))
          .where((pkg) => pkg.isNotEmpty)
          .toList();
    } catch (e, stack) {
      _logger.e(
        'Exception while listing packages for device $deviceId',
        error: e,
        stackTrace: stack,
      );
      return const [];
    }
  }
}
