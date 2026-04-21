import 'package:android_tools/features/information/core/android_version_helper.dart';
import 'package:android_tools/features/information/presentation/widgets/meta_chip.dart';
import 'package:android_tools/features/information/presentation/widgets/stat_card_shell.dart';
import 'package:flutter/material.dart';

/// Carte pleine-largeur affichant le nom du device, son statut connecté,
/// le fabricant, quelques métadonnées, et des actions optionnelles (ex: screenshot).
class DeviceStatCard extends StatelessWidget {
  final String deviceName;
  final String manufacturer;
  final String serial;
  final String androidVersion;

  /// Boutons affichés à droite du titre (après le badge Connected).
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

    return StatCardShell(
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
                    _ConnectedBadge(),
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
                      MetaChip(label: serial, icon: Icons.tag),
                    if (androidVersion.isNotEmpty)
                      MetaChip(
                        label: 'Android $androidVersion',
                        icon: Icons.android,
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

class _ConnectedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
          ),
          const Text(
            'Connected',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
