import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
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
          _KeyValueRow(label: 'Package', value: apkInfo.packageName),
          _KeyValueRow(label: 'Version name', value: apkInfo.version),
          _KeyValueRow(label: 'Version code', value: apkInfo.versionCode.toString()),
          _KeyValueRow(label: 'Min SDK', value: '${apkInfo.minSdk} (Android ${_getAndroidVersion(apkInfo.minSdk)})'),
          _KeyValueRow(label: 'Target SDK', value: '${apkInfo.targetSdk} (Android ${_getAndroidVersion(apkInfo.targetSdk)})'),
          _KeyValueRow(label: 'Compile SDK', value: apkInfo.compileSdk.toString()),
          _KeyValueRow(label: 'ABIs', value: apkInfo.abis.join(', ')),
          _KeyValueRow(label: 'Locales', value: '${apkInfo.localesCount} languages'),
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

/// Key-value row widget for manifest details
class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.surfaceContainerHighest,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
