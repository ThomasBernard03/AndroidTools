import 'package:android_tools/shared/data/datasources/local/models/app_settings_model.dart';
import 'package:android_tools/shared/data/datasources/local/models/install_history_model.dart';
import 'package:android_tools/shared/data/datasources/local/models/recent_apk_model.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [InstalledApplicationHistoryModel, AppSettingsModel, RecentApkModel])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Set default max history size to 10
          await into(appSettingsModel).insert(
            AppSettingsModelCompanion.insert(
              key: 'max_history_size',
              value: '10',
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1) {
            // Add AppSettingsModel table
            await m.createTable(appSettingsModel);
            // Set default max history size to 10
            await into(appSettingsModel).insert(
              AppSettingsModelCompanion.insert(
                key: 'max_history_size',
                value: '10',
                createdAt: Value(DateTime.now()),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
          if (from <= 2) {
            // Add RecentApkModel table
            await m.createTable(recentApkModel);
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
