import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/component_bar.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/component_key_value_row.dart';
import 'package:android_tools/shared/presentation/widgets/info_panel.dart';
import 'package:flutter/material.dart';

/// Panel displaying APK components information
class ComponentsPanel extends StatelessWidget {
  final ApkInfo apkInfo;

  const ComponentsPanel({
    super.key,
    required this.apkInfo,
  });

  @override
  Widget build(BuildContext context) {
    return InfoPanel(
      title: 'Components',
      child: Column(
        children: [
          ComponentBar(
            label: 'Activities',
            count: apkInfo.activitiesCount,
            maxCount: 50,
          ),
          ComponentBar(
            label: 'Services',
            count: apkInfo.servicesCount,
            maxCount: 50,
          ),
          ComponentBar(
            label: 'Receivers',
            count: apkInfo.receiversCount,
            maxCount: 50,
          ),
          ComponentBar(
            label: 'Providers',
            count: apkInfo.providersCount,
            maxCount: 50,
          ),

          // Divider
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.15),
          ),
          const SizedBox(height: 10),

          // Additional info
          ComponentKeyValueRow(label: 'DEX files', value: apkInfo.dexFilesCount.toString()),
          ComponentKeyValueRow(label: 'Resources', value: apkInfo.resourcesCount.toString()),
          ComponentKeyValueRow(label: 'Assets', value: apkInfo.assetsCount.toString()),
        ],
      ),
    );
  }
}
