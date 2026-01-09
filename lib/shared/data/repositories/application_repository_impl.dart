import 'dart:io';

import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';
import 'package:logger/logger.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  final Logger _logger;
  final ShellDatasource _shellDatasource;

  ApplicationRepositoryImpl(this._logger, this._shellDatasource);

  @override
  Future<void> intallApplication(String apkPath, String deviceId) async {
    if (apkPath.isEmpty) {
      _logger.w("apkPath is empty, can't install apk");
      return;
    }

    if (!apkPath.endsWith(".apk")) {
      _logger.w("apkPath $apkPath is not an apk file");
      return;
    }

    final adbPath = _shellDatasource.getAdbPath();

    final process = await Process.start(adbPath, [
      '-s',
      deviceId,
      'install',
      apkPath,
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
      _logger.e('ADB install error: ${stderrBuffer.toString()}');
      throw Exception("Can't install APK : $apkPath");
    }

    _logger.i('APK installed: ${stdoutBuffer.toString()}');
  }
}
