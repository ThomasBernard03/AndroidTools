import 'package:drift/drift.dart';

class InstalledApplicationHistoryModel extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get applicationName => text()();
  TextColumn get applicationVersionName => text()();
  IntColumn get applicationVersionCode => integer()();
  TextColumn get path => text()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
