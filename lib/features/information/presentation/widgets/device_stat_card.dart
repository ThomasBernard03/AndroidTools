import 'package:android_tools/features/information/core/android_version_helper.dart';
import 'package:android_tools/features/information/presentation/widgets/connected_badge.dart';
import 'package:android_tools/shared/presentation/widgets/info_badge.dart';
import 'package:android_tools/shared/presentation/widgets/info_card.dart';
import 'package:flutter/material.dart';

/// Full-width card displaying the device name, connection status,
/// manufacturer, metadata, and optional actions (e.g., screenshot).
class DeviceStatCard extends StatelessWidget {
  final String deviceName;
  final String manufacturer;
  final String serial;
  final String androidVersion;

  /// Buttons displayed to the right of the title (after the Connected badge).
  final List<Widget> actions;

  const DeviceStatCard({
    super.key,
    required this.deviceName,
    required this.manufacturer,
    required this.serial,
    required this.androidVersion,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).colorScheme.surfaceContainerHighest;
    final primary = Theme.of(context).colorScheme.primary;

    return InfoCard(
      child: Row(
        spacing: 16,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: dim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: androidVersion.isNotEmpty
                  ? getAndroidVersionLogo(androidVersion)
                  : Icon(Icons.phone_android, color: primary, size: 24),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        deviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ConnectedBadge(),
                    if (actions.isNotEmpty) ...actions,
                  ],
                ),
                if (manufacturer.isNotEmpty)
                  Text(
                    manufacturer,
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                Row(
                  spacing: 12,
                  children: [
                    if (serial.isNotEmpty)
                      InfoBadge(
                        label: serial,
                        icon: Icons.tag,
                        iconSize: 11,
                        color: dim,
                      ),
                    if (androidVersion.isNotEmpty)
                      InfoBadge(
                        label: 'Android $androidVersion',
                        icon: Icons.android,
                        iconSize: 11,
                        color: dim,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
