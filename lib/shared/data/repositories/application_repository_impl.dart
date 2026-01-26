import 'dart:io';

import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/data/datasources/local/app_database.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  final ShellDatasource _shellDatasource;
  final AppDatabase _database;

  ApplicationRepositoryImpl(this._shellDatasource, this._database);

  @override
  Future<void> intallApplication(String apkPath, String deviceId) async {
    final apkFile = File(apkPath);
    final originalFileName = path.basenameWithoutExtension(apkPath);

    // 1. Install the application
    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    await adbClient.installApplication(apkFile, deviceId);

    // 2. Copy APK to cache directory
    final appSupportDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(path.join(appSupportDir.path, 'installed_apks'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${originalFileName}_$timestamp.apk';
    final cachedApkPath = path.join(cacheDir.path, fileName);
    await apkFile.copy(cachedApkPath);

    // 3. Save to database
    await _database.into(_database.installedApplicationHistoryModel).insert(
          InstalledApplicationHistoryModelCompanion(
            applicationName: drift.Value(originalFileName),
            applicationVersionName: const drift.Value('Unknown'),
            applicationVersionCode: const drift.Value(0),
            path: drift.Value(cachedApkPath),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
  }
}
