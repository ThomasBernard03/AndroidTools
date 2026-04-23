import 'dart:io';

import 'package:aapt_dart/aapt_dart.dart' as aapt;
import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/core/constants.dart';
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

    // Get file size
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    // Parse using AAPT dump badging
    final aaptPath = Constants.getAaptPath();
    final badgingResult = await Process.run(
      aaptPath,
      ['dump', 'badging', apkPath],
    );

    if (badgingResult.exitCode != 0) {
      _logger.e('AAPT badging failed: ${badgingResult.stderr}');
      throw Exception('Failed to parse APK: ${badgingResult.stderr}');
    }

    final badgingOutput = badgingResult.stdout.toString();
    _logger.d('AAPT badging output parsed');

    // Parse basic info
    final packageName = _extractPackageName(badgingOutput);
    final versionName = _extractVersionName(badgingOutput);
    final versionCode = _extractVersionCode(badgingOutput);
    final appLabel = _extractAppLabel(badgingOutput);
    final minSdk = _extractMinSdk(badgingOutput);
    final targetSdk = _extractTargetSdk(badgingOutput);
    final compileSdk = _extractCompileSdk(badgingOutput);
    final isDebuggable = _extractDebuggable(badgingOutput);
    final abis = _extractAbis(badgingOutput);
    final localesCount = _extractLocalesCount(badgingOutput);
    final permissions = _extractPermissions(badgingOutput);
    final activitiesCount = _extractActivitiesCount(badgingOutput);
    final servicesCount = _extractServicesCount(badgingOutput);
    final receiversCount = _extractReceiversCount(badgingOutput);
    final providersCount = _extractProvidersCount(badgingOutput);

    // Count resources
    final resourcesResult = await Process.run(
      aaptPath,
      ['dump', 'resources', apkPath],
    );
    final resourcesCount = _countResources(resourcesResult.stdout.toString());

    // Count DEX and assets (using zipinfo or basic file listing)
    final dexCount = await _countDexFiles(apkPath);
    final assetsCount = await _countAssets(apkPath);

    // Parse signature if available
    ApkSignature? signature;
    try {
      signature = await _extractSignature(apkPath);
    } catch (e) {
      _logger.w('Could not extract signature: $e');
    }

    return ApkInfo(
      filePath: apkPath,
      fileName: p.basename(apkPath),
      sizeInMB: double.parse(sizeInMB.toStringAsFixed(1)),
      packageName: packageName,
      appLabel: appLabel,
      version: versionName,
      versionCode: versionCode,
      minSdk: minSdk,
      targetSdk: targetSdk,
      compileSdk: compileSdk,
      isDebuggable: isDebuggable,
      abis: abis,
      localesCount: localesCount,
      permissions: permissions,
      signature: signature,
      activitiesCount: activitiesCount,
      servicesCount: servicesCount,
      receiversCount: receiversCount,
      providersCount: providersCount,
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

  // Extraction helper methods

  String _extractPackageName(String badgingOutput) {
    final match = RegExp(r"package: name='([^']+)'").firstMatch(badgingOutput);
    return match?.group(1) ?? 'Unknown';
  }

  String _extractVersionName(String badgingOutput) {
    final match = RegExp(r"versionName='([^']+)'").firstMatch(badgingOutput);
    return match?.group(1) ?? '1.0';
  }

  int _extractVersionCode(String badgingOutput) {
    final match = RegExp(r"versionCode='(\d+)'").firstMatch(badgingOutput);
    return int.tryParse(match?.group(1) ?? '1') ?? 1;
  }

  String _extractAppLabel(String badgingOutput) {
    final match = RegExp(r"application-label:'([^']+)'").firstMatch(badgingOutput);
    return match?.group(1) ?? 'Unknown App';
  }

  int _extractMinSdk(String badgingOutput) {
    final match = RegExp(r"sdkVersion:'(\d+)'").firstMatch(badgingOutput);
    return int.tryParse(match?.group(1) ?? '21') ?? 21;
  }

  int _extractTargetSdk(String badgingOutput) {
    final match = RegExp(r"targetSdkVersion:'(\d+)'").firstMatch(badgingOutput);
    return int.tryParse(match?.group(1) ?? '31') ?? 31;
  }

  int _extractCompileSdk(String badgingOutput) {
    // compileSdk is often same as targetSdk if not explicitly specified
    final match = RegExp(r"compileSdkVersion:'(\d+)'").firstMatch(badgingOutput);
    return int.tryParse(match?.group(1) ?? '0') ?? _extractTargetSdk(badgingOutput);
  }

  bool _extractDebuggable(String badgingOutput) {
    return badgingOutput.contains("application-debuggable");
  }

  List<String> _extractAbis(String badgingOutput) {
    final matches = RegExp(r"native-code: '([^']+)'").firstMatch(badgingOutput);
    if (matches == null) return [];

    final abisString = matches.group(1) ?? '';
    return abisString.split("' '").where((abi) => abi.isNotEmpty).toList();
  }

  int _extractLocalesCount(String badgingOutput) {
    final matches = RegExp(r"locales: '([^']+)'").firstMatch(badgingOutput);
    if (matches == null) return 1;

    final localesString = matches.group(1) ?? '';
    return localesString.split("' '").where((locale) => locale.isNotEmpty).length;
  }

  List<ApkPermission> _extractPermissions(String badgingOutput) {
    final permissions = <ApkPermission>[];
    final permissionRegex = RegExp(r"uses-permission: name='([^']+)'");

    for (final match in permissionRegex.allMatches(badgingOutput)) {
      final permName = match.group(1) ?? '';
      final level = _categorizePermissionLevel(permName);
      permissions.add(ApkPermission(name: permName, level: level));
    }

    return permissions;
  }

  String _categorizePermissionLevel(String permissionName) {
    // Categorize based on common dangerous permissions
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

    // Check for signature-level permissions
    if (permissionName.contains('c2dm.permission') ||
        permissionName.contains('BIND_')) {
      return 'signature';
    }

    return 'normal';
  }

  int _extractActivitiesCount(String badgingOutput) {
    return RegExp(r"launchable-activity:").allMatches(badgingOutput).length;
  }

  int _extractServicesCount(String badgingOutput) {
    return RegExp(r"service:").allMatches(badgingOutput).length;
  }

  int _extractReceiversCount(String badgingOutput) {
    return RegExp(r"receiver:").allMatches(badgingOutput).length;
  }

  int _extractProvidersCount(String badgingOutput) {
    return RegExp(r"provider:").allMatches(badgingOutput).length;
  }

  int _countResources(String resourcesOutput) {
    // Count resource entries in the output
    final matches = RegExp(r"resource 0x[0-9a-f]+").allMatches(resourcesOutput);
    return matches.length;
  }

  Future<int> _countDexFiles(String apkPath) async {
    try {
      // Use unzip to list files and count .dex files
      final result = await Process.run('unzip', ['-l', apkPath]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return RegExp(r'classes\d*\.dex').allMatches(output).length;
      }
    } catch (e) {
      _logger.w('Could not count DEX files: $e');
    }
    return 1; // Default to 1 DEX file
  }

  Future<int> _countAssets(String apkPath) async {
    try {
      // Use unzip to list files in assets/ directory
      final result = await Process.run('unzip', ['-l', apkPath]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        return lines.where((line) => line.contains('assets/')).length;
      }
    } catch (e) {
      _logger.w('Could not count assets: $e');
    }
    return 0;
  }

  Future<ApkSignature?> _extractSignature(String apkPath) async {
    try {
      _logger.d('Extracting signature information from APK');

      // Step 1: List files in META-INF to find certificate file
      final listResult = await Process.run('unzip', ['-l', apkPath]);
      if (listResult.exitCode != 0) {
        _logger.w('Could not list APK contents');
        return null;
      }

      final listOutput = listResult.stdout.toString();
      String? certFile;

      // Look for RSA or DSA certificate file
      for (final line in listOutput.split('\n')) {
        if (line.contains('META-INF/') && (line.endsWith('.RSA') || line.endsWith('.DSA') || line.endsWith('.EC'))) {
          final parts = line.trim().split(RegExp(r'\s+'));
          certFile = parts.last;
          break;
        }
      }

      if (certFile == null) {
        _logger.d('No signature certificate found in APK');
        return null; // Unsigned APK
      }

      _logger.d('Found certificate file: $certFile');

      // Step 2: Extract certificate to temp file
      final tempDir = Directory.systemTemp.createTempSync('apk_cert_');
      final certPath = '${tempDir.path}/cert.rsa';

      final extractResult = await Process.run(
        'unzip',
        ['-p', apkPath, certFile],
        stdoutEncoding: null, // Binary output
      );

      if (extractResult.exitCode != 0) {
        _logger.w('Could not extract certificate');
        tempDir.deleteSync(recursive: true);
        return null;
      }

      // Write binary certificate to file
      await File(certPath).writeAsBytes(extractResult.stdout as List<int>);

      // Step 3: Use openssl to parse certificate info
      final opensslResult = await Process.run(
        'openssl',
        ['pkcs7', '-inform', 'DER', '-in', certPath, '-noout', '-print_certs', '-text'],
      );

      // Step 4: Also get certificate in PEM format for SHA-256
      final pemResult = await Process.run(
        'openssl',
        ['pkcs7', '-inform', 'DER', '-in', certPath, '-print_certs', '-outform', 'PEM'],
      );

      // Clean up temp files
      tempDir.deleteSync(recursive: true);

      if (opensslResult.exitCode != 0) {
        _logger.w('OpenSSL parsing failed: ${opensslResult.stderr}');
        return _createBasicSignature();
      }

      final certText = opensslResult.stdout.toString();
      final pemText = pemResult.stdout.toString();

      // Parse certificate information
      final issuer = _parseCertField(certText, 'Issuer:');
      final validFrom = _parseCertDate(certText, 'Not Before:');
      final validTo = _parseCertDate(certText, 'Not After :');
      final algorithm = _parseCertField(certText, 'Signature Algorithm:');
      final keySize = _parseKeySize(certText);
      final sha256 = await _computeSHA256Fingerprint(pemText);

      // Determine signing scheme (v1 is always present if META-INF exists, check for v2/v3 would need apksigner)
      String scheme = 'v1 (JAR)';

      // Try to detect v2/v3 scheme by checking for APK Signing Block
      final v2v3Check = await _checkForV2V3Signature(apkPath);
      if (v2v3Check) {
        scheme = 'v1 + v2/v3';
      }

      return ApkSignature(
        scheme: scheme,
        sha256: sha256,
        issuer: issuer,
        validFrom: validFrom,
        validTo: validTo,
        algorithm: algorithm,
        keySize: keySize,
      );
    } catch (e, stackTrace) {
      _logger.e('Error extracting signature', error: e, stackTrace: stackTrace);
      return _createBasicSignature();
    }
  }

  ApkSignature _createBasicSignature() {
    return ApkSignature(
      scheme: 'v1 (JAR)',
      sha256: 'Unable to extract fingerprint',
      issuer: 'Unable to extract issuer',
      validFrom: '—',
      validTo: '—',
      algorithm: 'Unknown',
      keySize: 0,
    );
  }

  String _parseCertField(String certText, String fieldName) {
    final lines = certText.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith(fieldName)) {
        final value = lines[i].substring(lines[i].indexOf(fieldName) + fieldName.length).trim();

        // Clean up issuer field
        if (fieldName == 'Issuer:') {
          // Extract CN, O, C from format like: C=US, ST=California, O=Organization, CN=Name
          final cnMatch = RegExp(r'CN\s*=\s*([^,]+)').firstMatch(value);
          final oMatch = RegExp(r'O\s*=\s*([^,]+)').firstMatch(value);
          final cMatch = RegExp(r'C\s*=\s*([^,]+)').firstMatch(value);

          final parts = <String>[];
          if (cnMatch != null) parts.add('CN=${cnMatch.group(1)!.trim()}');
          if (oMatch != null) parts.add('O=${oMatch.group(1)!.trim()}');
          if (cMatch != null) parts.add('C=${cMatch.group(1)!.trim()}');

          return parts.isNotEmpty ? parts.join(', ') : value;
        }

        return value;
      }
    }
    return 'Unknown';
  }

  String _parseCertDate(String certText, String fieldName) {
    final value = _parseCertField(certText, fieldName);
    if (value == 'Unknown') return '—';

    // Parse date format "Jan 1 00:00:00 2024 GMT" to "Jan 1, 2024"
    try {
      final parts = value.split(' ');
      if (parts.length >= 4) {
        return '${parts[0]} ${parts[1]}, ${parts[3]}';
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return value;
  }

  int _parseKeySize(String certText) {
    // Look for "Public-Key: (2048 bit)" or similar
    final match = RegExp(r'Public-Key:\s*\((\d+)\s*bit\)').firstMatch(certText);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 2048; // Default
  }

  Future<String> _computeSHA256Fingerprint(String pemText) async {
    try {
      // Write PEM to temp file
      final tempDir = Directory.systemTemp.createTempSync('apk_pem_');
      final pemPath = '${tempDir.path}/cert.pem';
      await File(pemPath).writeAsString(pemText);

      // Compute SHA-256 fingerprint
      final result = await Process.run(
        'openssl',
        ['x509', '-in', pemPath, '-noout', '-fingerprint', '-sha256'],
      );

      tempDir.deleteSync(recursive: true);

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Extract fingerprint from "SHA256 Fingerprint=XX:XX:XX..."
        final match = RegExp(r'Fingerprint=([A-F0-9:]+)').firstMatch(output);
        if (match != null) {
          return match.group(1) ?? 'Unable to compute';
        }
      }
    } catch (e) {
      _logger.w('Could not compute SHA-256 fingerprint: $e');
    }

    return 'Unable to compute';
  }

  Future<bool> _checkForV2V3Signature(String apkPath) async {
    try {
      // V2/V3 signatures are in the APK Signing Block, which is located before the central directory
      // This is a simplified check - just look for the magic string
      final file = File(apkPath);
      final bytes = await file.readAsBytes();

      // Look for APK Sig Block magic: "APK Sig Block 42"
      final magic = 'APK Sig Block 42'.codeUnits;
      for (int i = 0; i < bytes.length - magic.length; i++) {
        bool found = true;
        for (int j = 0; j < magic.length; j++) {
          if (bytes[i + j] != magic[j]) {
            found = false;
            break;
          }
        }
        if (found) return true;
      }
    } catch (e) {
      _logger.w('Error checking for v2/v3 signature: $e');
    }

    return false;
  }
}
