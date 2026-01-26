import 'dart:io';

import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  final ShellDatasource _shellDatasource;

  ApplicationRepositoryImpl(this._shellDatasource);

  @override
  Future<void> intallApplication(String apkPath, String deviceId) {
    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    final apkFile = File(apkPath);
    return adbClient.installApplication(apkFile, deviceId);
  }
}
