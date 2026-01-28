import 'package:android_tools/shared/domain/entities/installed_application_history_entity.dart';

abstract class ApplicationRepository {
  Future<void> intallApplication(String apkPath, String deviceId);
  Stream<List<InstalledApplicationHistoryEntity>> watchInstalledApplicationHistory();
  Future<void> clearInstalledApplicationHistory();
  Future<int> getMaxHistorySize();
  Future<void> setMaxHistorySize(int size);
}
