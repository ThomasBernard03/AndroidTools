import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final ShellDatasource _shellDatasource;

  PackageRepositoryImpl(this._shellDatasource);

  @override
  Future<Iterable<String>> getAllPackages(String deviceId) {
    final adbPath = _shellDatasource.getAdbPath();
    final adbClient = AdbClient(adbExecutablePath: adbPath);
    return adbClient.getAllPackages(deviceId);
  }
}
