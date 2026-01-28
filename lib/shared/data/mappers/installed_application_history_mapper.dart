import 'package:android_tools/shared/data/datasources/local/app_database.dart';
import 'package:android_tools/shared/domain/entities/installed_application_history_entity.dart';

extension InstalledApplicationHistoryMapper
    on InstalledApplicationHistoryModelData {
  InstalledApplicationHistoryEntity toEntity() {
    return InstalledApplicationHistoryEntity(
      id: id,
      applicationName: applicationName,
      applicationVersionName: applicationVersionName,
      applicationVersionCode: applicationVersionCode,
      path: path,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
