import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border.all(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Text(
              'Components',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Column(
              children: [
                _ComponentBar(
                  label: 'Activities',
                  count: apkInfo.activitiesCount,
                  maxCount: 50,
                ),
                _ComponentBar(
                  label: 'Services',
                  count: apkInfo.servicesCount,
                  maxCount: 50,
                ),
                _ComponentBar(
                  label: 'Receivers',
                  count: apkInfo.receiversCount,
                  maxCount: 50,
                ),
                _ComponentBar(
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
                _KeyValueRow(label: 'DEX files', value: apkInfo.dexFilesCount.toString()),
                _KeyValueRow(label: 'Resources', value: apkInfo.resourcesCount.toString()),
                _KeyValueRow(label: 'Assets', value: apkInfo.assetsCount.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Component bar widget showing count with visual bar
class _ComponentBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;

  const _ComponentBar({
    required this.label,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (count / maxCount).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.surfaceContainerHighest,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Key-value row widget for additional component info
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
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }
}
