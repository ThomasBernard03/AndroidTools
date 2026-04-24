import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/manifest_key_value_row.dart';
import 'package:android_tools/shared/presentation/widgets/info_panel.dart';
import 'package:flutter/material.dart';

/// Panel displaying APK manifest information
class ManifestPanel extends StatelessWidget {
  final ApkInfo apkInfo;

  const ManifestPanel({
    super.key,
    required this.apkInfo,
  });

  @override
  Widget build(BuildContext context) {
    return InfoPanel(
      title: 'Manifest',
      child: Column(
        children: [
          ManifestKeyValueRow(label: 'Package', value: apkInfo.packageName),
          ManifestKeyValueRow(label: 'Version name', value: apkInfo.version),
          ManifestKeyValueRow(label: 'Version code', value: apkInfo.versionCode.toString()),
          ManifestKeyValueRow(label: 'Min SDK', value: '${apkInfo.minSdk} (Android ${_getAndroidVersion(apkInfo.minSdk)})'),
          ManifestKeyValueRow(label: 'Target SDK', value: '${apkInfo.targetSdk} (Android ${_getAndroidVersion(apkInfo.targetSdk)})'),
          ManifestKeyValueRow(label: 'Compile SDK', value: apkInfo.compileSdk.toString()),
          ManifestKeyValueRow(label: 'ABIs', value: apkInfo.abis.join(', ')),
          ManifestKeyValueRow(label: 'Locales', value: '${apkInfo.localesCount} languages'),
        ],
      ),
    );
  }

  String _getAndroidVersion(int sdkVersion) {
    return switch (sdkVersion) {
      >= 35 => '15',
      34 => '14',
      33 => '13',
      32 || 31 => '12',
      30 => '11',
      29 => '10',
      28 => '9',
      27 || 26 => '8',
      25 || 24 => '7',
      23 => '6',
      22 || 21 => '5',
      _ => sdkVersion.toString(),
    };
  }
}
