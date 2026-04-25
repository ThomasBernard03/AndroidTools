import '../entities/apk_info.dart';
import '../repositories/apk_repository.dart';

/// Use case for parsing an APK file and extracting metadata
class ParseApkUsecase {
  final ApkRepository _repository;

  ParseApkUsecase(this._repository);

  /// Parse the APK at [apkPath] and return complete metadata
  Future<ApkInfo> call(String apkPath) {
    return _repository.parseApk(apkPath);
  }
}
