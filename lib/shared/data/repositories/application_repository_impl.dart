import 'dart:io';

import 'package:aapt_dart/aapt_dart.dart';
import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/data/datasources/local/app_database.dart';
import 'package:android_tools/shared/data/datasources/local/application_local_datasource.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/data/mappers/installed_application_history_mapper.dart';
import 'package:android_tools/shared/domain/entities/installed_application_history_entity.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ApplicationRepositoryImpl implements ApplicationRepository {
  final ShellDatasource _shellDatasource;
  final AppDatabase _database;
  final ApplicationLocalDatasource _applicationLocalDatasource;
  final AaptClient _aaptClient;
  final Logger _logger;

  ApplicationRepositoryImpl(
    this._shellDatasource,
    this._database,
    this._applicationLocalDatasource,
    this._aaptClient,
    this._logger,
  );

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

    // 3. Get apk information
    ApkInfo? apkInfo;
    try {
      apkInfo = await _aaptClient.getApkInfo(cachedApkPath);
    } catch (e) {
      _logger.e("Error when retrieving apk info $e");
    }

    // 3. Save to database
    await _database
        .into(_database.installedApplicationHistoryModel)
        .insert(
          InstalledApplicationHistoryModelCompanion(
            applicationName: Value(
              apkInfo?.applicationLabel ?? originalFileName,
            ),
            applicationVersionName: apkInfo == null
                ? Value.absent()
                : Value(apkInfo.versionName),
            applicationVersionCode: apkInfo == null
                ? Value.absent()
                : Value(apkInfo.versionCode),
            path: Value(cachedApkPath),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // 4. Clean old entries if max history size is exceeded
    final pathsToDelete = await _applicationLocalDatasource.cleanOldHistoryEntries();

    // 5. Delete the APK files that were removed from history
    for (final filePath in pathsToDelete) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          _logger.i("Deleted old APK file: $filePath");
        }
      } catch (e) {
        _logger.e("Error deleting APK file $filePath: $e");
      }
    }
  }

  @override
  Stream<List<InstalledApplicationHistoryEntity>> watchInstalledApplicationHistory() {
    return _applicationLocalDatasource
        .watchInstalledApplicationHistory()
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<void> clearInstalledApplicationHistory() async {
    try {
      // 1. Clear database records
      await _applicationLocalDatasource.clearInstalledApplicationHistory();

      // 2. Delete all files in installed_apks directory
      final appSupportDir = await getApplicationSupportDirectory();
      final installedApksDir = Directory(path.join(appSupportDir.path, 'installed_apks'));

      if (await installedApksDir.exists()) {
        await installedApksDir.delete(recursive: true);
        // Recreate the directory for future installations
        await installedApksDir.create(recursive: true);
      }

      _logger.i("Installed application history cleared successfully");
    } catch (e) {
      _logger.e("Error clearing installed application history: $e");
      rethrow;
    }
  }

  @override
  Future<int> getMaxHistorySize() async {
    return await _applicationLocalDatasource.getMaxHistorySize();
  }

  @override
  Future<void> setMaxHistorySize(int size) async {
    await _applicationLocalDatasource.setMaxHistorySize(size);
    // Clean old entries immediately if the new size is smaller than current count
    final pathsToDelete = await _applicationLocalDatasource.cleanOldHistoryEntries();

    // Delete the APK files that were removed from history
    for (final filePath in pathsToDelete) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          _logger.i("Deleted old APK file: $filePath");
        }
      } catch (e) {
        _logger.e("Error deleting APK file $filePath: $e");
      }
    }
  }
}
