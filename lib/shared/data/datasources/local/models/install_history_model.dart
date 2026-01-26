import 'package:drift/drift.dart';

class InstallHistoryModel extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get applicationName => text()();
  TextColumn get applicationVersionName => text()();
  IntColumn get applicationVersionCode => integer()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
