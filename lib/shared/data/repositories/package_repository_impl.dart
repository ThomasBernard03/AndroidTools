import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final AdbClient _adbClient;

  PackageRepositoryImpl(this._adbClient);

  @override
  Future<Iterable<String>> getAllPackages(String deviceId) {
    return _adbClient.getAllPackages(deviceId);
  }
}
