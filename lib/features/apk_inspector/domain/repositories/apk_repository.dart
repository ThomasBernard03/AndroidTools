import '../entities/apk_info.dart';

/// Repository interface for APK inspection operations
abstract class ApkRepository {
  /// Parse an APK file and extract all metadata
  ///
  /// Returns complete [ApkInfo] with all extracted data
  /// Throws an exception if the APK is invalid or cannot be parsed
  Future<ApkInfo> parseApk(String apkPath);

  /// Install an APK to a connected Android device
  ///
  /// [apkPath] is the local path to the APK file
  /// [deviceId] is the ADB device identifier
  Future<void> installApk(String apkPath, String deviceId);
}
