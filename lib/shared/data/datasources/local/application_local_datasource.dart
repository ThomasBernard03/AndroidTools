import 'package:android_tools/shared/data/datasources/local/app_database.dart';
import 'package:drift/drift.dart';

class ApplicationLocalDatasource {
  final AppDatabase _database;

  ApplicationLocalDatasource(this._database);

  Stream<List<InstalledApplicationHistoryModelData>> watchInstalledApplicationHistory() {
    return _database
        .select(_database.installedApplicationHistoryModel)
        .watch();
  }

  Future<void> clearInstalledApplicationHistory() async {
    await _database.delete(_database.installedApplicationHistoryModel).go();
  }

  Future<int> getMaxHistorySize() async {
    final result = await (_database.select(_database.appSettingsModel)
          ..where((tbl) => tbl.key.equals('max_history_size')))
        .getSingleOrNull();

    if (result == null) {
      // Create default setting if it doesn't exist
      await _database.into(_database.appSettingsModel).insert(
            AppSettingsModelCompanion.insert(
              key: 'max_history_size',
              value: '10',
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      return 10;
    }

    return int.tryParse(result.value) ?? 10;
  }

  Future<void> setMaxHistorySize(int size) async {
    final existing = await (_database.select(_database.appSettingsModel)
          ..where((tbl) => tbl.key.equals('max_history_size')))
        .getSingleOrNull();

    if (existing == null) {
      await _database.into(_database.appSettingsModel).insert(
            AppSettingsModelCompanion.insert(
              key: 'max_history_size',
              value: size.toString(),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } else {
      await (_database.update(_database.appSettingsModel)
            ..where((tbl) => tbl.key.equals('max_history_size')))
          .write(
        AppSettingsModelCompanion(
          value: Value(size.toString()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<List<String>> cleanOldHistoryEntries() async {
    final maxSize = await getMaxHistorySize();

    if (maxSize == 0) {
      // If max size is 0, get all paths before clearing
      final allEntries = await _database
          .select(_database.installedApplicationHistoryModel)
          .get();
      final paths = allEntries.map((e) => e.path).toList();

      await clearInstalledApplicationHistory();
      return paths;
    }

    // Get all entries ordered by creation date (newest first)
    final allEntries = await (_database.select(_database.installedApplicationHistoryModel)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    // If we have more entries than the max size, delete the oldest ones
    if (allEntries.length > maxSize) {
      final entriesToDelete = allEntries.skip(maxSize).toList();
      final pathsToDelete = <String>[];

      for (final entry in entriesToDelete) {
        pathsToDelete.add(entry.path);
        await (_database.delete(_database.installedApplicationHistoryModel)
              ..where((tbl) => tbl.id.equals(entry.id)))
            .go();
      }

      return pathsToDelete;
    }

    return [];
  }
}
