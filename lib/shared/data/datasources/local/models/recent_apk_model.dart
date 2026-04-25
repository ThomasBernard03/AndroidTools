import 'package:drift/drift.dart';

class RecentApkModel extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  RealColumn get sizeInMB => real()();
  TextColumn get packageName => text()();
  TextColumn get appLabel => text()();
  TextColumn get version => text()();
  IntColumn get versionCode => integer()();
  IntColumn get minSdk => integer()();
  IntColumn get targetSdk => integer()();

  DateTimeColumn get lastInspectedAt => dateTime()();
}
