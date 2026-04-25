import 'package:android_tools/shared/data/datasources/local/models/app_settings_model.dart';
import 'package:android_tools/shared/data/datasources/local/models/recent_apk_model.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [AppSettingsModel, RecentApkModel])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1) {
            await m.createTable(appSettingsModel);
          }
          if (from <= 2) {
            await m.createTable(recentApkModel);
          }
          if (from <= 3) {
            await m.database.customStatement(
              'DROP TABLE IF EXISTS installed_application_history_model',
            );
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'android_tools.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
