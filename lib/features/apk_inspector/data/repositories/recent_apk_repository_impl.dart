import 'dart:io';

import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/domain/repositories/recent_apk_repository.dart';
import 'package:android_tools/shared/data/datasources/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

class RecentApkRepositoryImpl implements RecentApkRepository {
  final AppDatabase _database;
  final Logger _logger;

  RecentApkRepositoryImpl(this._database, this._logger);

  @override
  Future<List<ApkInfo>> getRecentApks({int limit = 10}) async {
    _logger.d('Getting recent APKs with limit: $limit');

    final recentApks = await (_database.select(_database.recentApkModel)
          ..orderBy([
            (t) => OrderingTerm(expression: t.lastInspectedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();

    final apkInfoList = <ApkInfo>[];

    for (final apk in recentApks) {
      final file = File(apk.filePath);
      if (await file.exists()) {
        apkInfoList.add(
          ApkInfo(
            filePath: apk.filePath,
            fileName: apk.fileName,
            sizeInMB: apk.sizeInMB,
            packageName: apk.packageName,
            appLabel: apk.appLabel,
            version: apk.version,
            versionCode: apk.versionCode,
            minSdk: apk.minSdk,
            targetSdk: apk.targetSdk,
            compileSdk: 0,
            isDebuggable: false,
            abis: [],
            localesCount: 0,
            permissions: [],
            signature: null,
            activitiesCount: 0,
            servicesCount: 0,
            receiversCount: 0,
            providersCount: 0,
            dexFilesCount: 0,
            resourcesCount: 0,
            assetsCount: 0,
          ),
        );
      } else {
        _logger.w('APK file not found, removing from history: ${apk.filePath}');
        await removeRecentApk(apk.filePath);
      }
    }

    _logger.d('Found ${apkInfoList.length} valid recent APKs');
    return apkInfoList;
  }

  @override
  Future<void> saveRecentApk(ApkInfo apkInfo) async {
    _logger.d('Saving recent APK: ${apkInfo.packageName}');

    await _database.transaction(() async {
      final existing = await (_database.select(_database.recentApkModel)
            ..where((t) => t.filePath.equals(apkInfo.filePath)))
          .getSingleOrNull();

      if (existing != null) {
        await (_database.update(_database.recentApkModel)
              ..where((t) => t.id.equals(existing.id)))
            .write(
          RecentApkModelCompanion(
            lastInspectedAt: Value(DateTime.now()),
            appLabel: Value(apkInfo.appLabel),
            version: Value(apkInfo.version),
            versionCode: Value(apkInfo.versionCode),
            sizeInMB: Value(apkInfo.sizeInMB),
          ),
        );
        _logger.d('Updated existing recent APK entry');
      } else {
        await _database.into(_database.recentApkModel).insert(
              RecentApkModelCompanion.insert(
                filePath: apkInfo.filePath,
                fileName: apkInfo.fileName,
                sizeInMB: apkInfo.sizeInMB,
                packageName: apkInfo.packageName,
                appLabel: apkInfo.appLabel,
                version: apkInfo.version,
                versionCode: apkInfo.versionCode,
                minSdk: apkInfo.minSdk,
                targetSdk: apkInfo.targetSdk,
                lastInspectedAt: DateTime.now(),
              ),
            );
        _logger.d('Inserted new recent APK entry');

        final count = await _database.recentApkModel.count().getSingle();
        if (count > 10) {
          final oldestEntries = await (_database.select(_database.recentApkModel)
                ..orderBy([
                  (t) => OrderingTerm(expression: t.lastInspectedAt, mode: OrderingMode.asc),
                ])
                ..limit(count - 10))
              .get();

          for (final entry in oldestEntries) {
            await (_database.delete(_database.recentApkModel)
                  ..where((t) => t.id.equals(entry.id)))
                .go();
          }

          _logger.d('Removed ${oldestEntries.length} old entries to maintain limit');
        }
      }
    });
  }

  @override
  Future<void> removeRecentApk(String filePath) async {
    _logger.d('Removing recent APK: $filePath');

    await (_database.delete(_database.recentApkModel)
          ..where((t) => t.filePath.equals(filePath)))
        .go();
  }

  @override
  Future<void> clearRecentApks() async {
    _logger.d('Clearing all recent APKs');

    await _database.delete(_database.recentApkModel).go();
  }
}
