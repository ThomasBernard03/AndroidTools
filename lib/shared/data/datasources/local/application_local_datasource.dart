import 'package:android_tools/shared/data/datasources/local/app_database.dart';

class ApplicationLocalDatasource {
  final AppDatabase _database;

  ApplicationLocalDatasource(this._database);

  Stream<List<InstalledApplicationHistoryModelData>> watchInstalledApplicationHistory() {
    return _database
        .select(_database.installedApplicationHistoryModel)
        .watch();
  }
}
