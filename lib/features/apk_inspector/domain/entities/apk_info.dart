import 'package:dart_mappable/dart_mappable.dart';

import 'apk_permission.dart';
import 'apk_signature.dart';

part 'apk_info.mapper.dart';

/// Complete metadata and information about an APK file
@MappableClass()
class ApkInfo with ApkInfoMappable {
  /// Full path to the APK file on disk
  final String filePath;

  /// File name of the APK
  final String fileName;

  /// Size of the APK file in megabytes
  final double sizeInMB;

  /// Android package name (e.g., com.example.app)
  final String packageName;

  /// Application label/name
  final String appLabel;

  /// Version name (e.g., 1.4.0)
  final String version;

  /// Version code (integer)
  final int versionCode;

  /// Minimum SDK version required
  final int minSdk;

  /// Target SDK version
  final int targetSdk;

  /// Compile SDK version
  final int compileSdk;

  /// Whether the APK is debuggable
  final bool isDebuggable;

  /// Supported ABIs (e.g., arm64-v8a, armeabi-v7a)
  final List<String> abis;

  /// Number of supported locales/languages
  final int localesCount;

  /// List of permissions requested by the app
  final List<ApkPermission> permissions;

  /// Signature information (null if unsigned)
  final ApkSignature? signature;

  /// Number of activities in the manifest
  final int activitiesCount;

  /// Number of services in the manifest
  final int servicesCount;

  /// Number of broadcast receivers in the manifest
  final int receiversCount;

  /// Number of content providers in the manifest
  final int providersCount;

  /// Number of DEX files in the APK
  final int dexFilesCount;

  /// Total number of resources
  final int resourcesCount;

  /// Number of assets
  final int assetsCount;

  const ApkInfo({
    required this.filePath,
    required this.fileName,
    required this.sizeInMB,
    required this.packageName,
    required this.appLabel,
    required this.version,
    required this.versionCode,
    required this.minSdk,
    required this.targetSdk,
    required this.compileSdk,
    required this.isDebuggable,
    required this.abis,
    required this.localesCount,
    required this.permissions,
    this.signature,
    required this.activitiesCount,
    required this.servicesCount,
    required this.receiversCount,
    required this.providersCount,
    required this.dexFilesCount,
    required this.resourcesCount,
    required this.assetsCount,
  });
}
