import '../repositories/apk_repository.dart';

/// Use case for installing an APK to a connected device
class InstallApkUsecase {
  final ApkRepository _repository;

  InstallApkUsecase(this._repository);

  /// Install APK from [apkPath] to the device with [deviceId]
  Future<void> call(String apkPath, String deviceId) {
    return _repository.installApk(apkPath, deviceId);
  }
}
