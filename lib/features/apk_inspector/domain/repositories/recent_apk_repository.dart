import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';

abstract class RecentApkRepository {
  /// Get list of recently inspected APKs, ordered by most recent first
  Future<List<ApkInfo>> getRecentApks({int limit = 10});

  /// Save an APK to the recent history
  Future<void> saveRecentApk(ApkInfo apkInfo);

  /// Remove an APK from the recent history by file path
  Future<void> removeRecentApk(String filePath);

  /// Clear all recent APKs
  Future<void> clearRecentApks();
}
