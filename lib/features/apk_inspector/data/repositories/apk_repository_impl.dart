import 'dart:io';

import 'package:aapt_dart/aapt_dart.dart' as aapt;
import 'package:adb_dart/adb_dart.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/apk_info.dart';
import '../../domain/entities/apk_permission.dart';
import '../../domain/entities/apk_signature.dart';
import '../../domain/repositories/apk_repository.dart';

/// Repository implementation for APK inspection using AAPT and apksigner
class ApkRepositoryImpl implements ApkRepository {
  final aapt.AaptClient _aaptClient;
  final AdbClient _adbClient;
  final Logger _logger;

  ApkRepositoryImpl(
    this._aaptClient,
    this._adbClient,
    this._logger,
  );

  @override
  Future<ApkInfo> parseApk(String apkPath) async {
    _logger.i('Parsing APK: $apkPath');

    final file = File(apkPath);
    if (!await file.exists()) {
      throw Exception('APK file not found: $apkPath');
    }

    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    final apkInfo = await _aaptClient.getApkInfo(apkPath);
    _logger.d('AAPT badging output parsed');

    final permissions = apkInfo.permissions.map((name) {
      final level = _categorizePermissionLevel(name);
      return ApkPermission(name: name, level: level);
    }).toList();

    final resourcesOutput = await _aaptClient.dumpResources(apkPath);
    final resourcesCount = _countResources(resourcesOutput);

    final dexCount = await _countDexFiles(apkPath);
    final assetsCount = await _countAssets(apkPath);

    ApkSignature? signature;
    try {
      final signatureInfo = await _aaptClient.getApkSignature(apkPath);
      if (signatureInfo != null) {
        signature = ApkSignature(
          scheme: signatureInfo.scheme,
          sha256: signatureInfo.sha256,
          issuer: signatureInfo.issuer,
          validFrom: signatureInfo.validFrom,
          validTo: signatureInfo.validTo,
          algorithm: signatureInfo.algorithm,
          keySize: signatureInfo.keySize,
        );
      }
    } catch (e) {
      _logger.w('Could not extract signature: $e');
    }

    return ApkInfo(
      filePath: apkPath,
      fileName: p.basename(apkPath),
      sizeInMB: double.parse(sizeInMB.toStringAsFixed(1)),
      packageName: apkInfo.packageName,
      appLabel: apkInfo.applicationLabel ?? 'Unknown App',
      version: apkInfo.versionName,
      versionCode: apkInfo.versionCode,
      minSdk: apkInfo.sdkVersion ?? 21,
      targetSdk: apkInfo.targetSdkVersion ?? 31,
      compileSdk: apkInfo.compileSdkVersion ?? apkInfo.targetSdkVersion ?? 31,
      isDebuggable: apkInfo.isDebuggable,
      abis: apkInfo.nativeLibraries,
      localesCount: apkInfo.locales.length,
      permissions: permissions,
      signature: signature,
      activitiesCount: apkInfo.launchableActivities.length,
      servicesCount: apkInfo.services.length,
      receiversCount: apkInfo.receivers.length,
      providersCount: apkInfo.providers.length,
      dexFilesCount: dexCount,
      resourcesCount: resourcesCount,
      assetsCount: assetsCount,
    );
  }

  @override
  Future<void> installApk(String apkPath, String deviceId) async {
    _logger.i('Installing APK: $apkPath to device: $deviceId');
    final apkFile = File(apkPath);
    await _adbClient.installApplication(apkFile, deviceId);
    _logger.i('APK installed successfully');
  }

  String _categorizePermissionLevel(String permissionName) {
    const dangerousPermissions = [
      'CAMERA',
      'RECORD_AUDIO',
      'READ_CONTACTS',
      'WRITE_CONTACTS',
      'READ_CALENDAR',
      'WRITE_CALENDAR',
      'READ_CALL_LOG',
      'WRITE_CALL_LOG',
      'PROCESS_OUTGOING_CALLS',
      'READ_PHONE_STATE',
      'CALL_PHONE',
      'USE_SIP',
      'SEND_SMS',
      'RECEIVE_SMS',
      'READ_SMS',
      'RECEIVE_WAP_PUSH',
      'RECEIVE_MMS',
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
      'ACCESS_FINE_LOCATION',
      'ACCESS_COARSE_LOCATION',
      'ACCESS_BACKGROUND_LOCATION',
      'BODY_SENSORS',
      'READ_MEDIA_IMAGES',
      'READ_MEDIA_VIDEO',
      'READ_MEDIA_AUDIO',
      'POST_NOTIFICATIONS',
      'BLUETOOTH_CONNECT',
      'BLUETOOTH_SCAN',
      'BLUETOOTH_ADVERTISE',
    ];

    final shortName = permissionName.split('.').last;
    if (dangerousPermissions.contains(shortName)) {
      return 'dangerous';
    }

    if (permissionName.contains('c2dm.permission') ||
        permissionName.contains('BIND_')) {
      return 'signature';
    }

    return 'normal';
  }

  int _countResources(String resourcesOutput) {
    final matches = RegExp(r"resource 0x[0-9a-f]+").allMatches(resourcesOutput);
    return matches.length;
  }

  Future<int> _countDexFiles(String apkPath) async {
    try {
      final files = await _aaptClient.listApkFiles(apkPath);
      return files.where((f) => RegExp(r'classes\d*\.dex').hasMatch(f)).length;
    } catch (e) {
      _logger.w('Could not count DEX files: $e');
      return 1;
    }
  }

  Future<int> _countAssets(String apkPath) async {
    try {
      final files = await _aaptClient.listApkFiles(apkPath);
      return files.where((f) => f.startsWith('assets/')).length;
    } catch (e) {
      _logger.w('Could not count assets: $e');
      return 0;
    }
  }
}
