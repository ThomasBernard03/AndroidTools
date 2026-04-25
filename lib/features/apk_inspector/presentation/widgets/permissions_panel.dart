import 'package:android_tools/features/apk_inspector/domain/entities/apk_permission.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/permission_legend.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/permission_row.dart';
import 'package:android_tools/shared/presentation/widgets/info_panel.dart';
import 'package:flutter/material.dart';

/// Panel displaying APK permissions
class PermissionsPanel extends StatelessWidget {
  final List<ApkPermission> permissions;

  const PermissionsPanel({
    super.key,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final dangerousCount = permissions.where((p) => p.level == 'dangerous').length;
    final normalCount = permissions.where((p) => p.level == 'normal').length;
    final signatureCount = permissions.where((p) => p.level == 'signature').length;

    return InfoPanel(
      title: 'Permissions',
      trailing: Text(
        '${permissions.length} total',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.surfaceContainerHighest,
              fontFamily: 'monospace',
            ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              PermissionLegend(
                color: const Color(0xFFEF6F6C),
                count: dangerousCount,
                label: 'Dangerous',
              ),
              const SizedBox(width: 12),
              PermissionLegend(
                color: colorScheme.onSurfaceVariant,
                count: normalCount,
                label: 'Normal',
              ),
              const SizedBox(width: 12),
              PermissionLegend(
                color: const Color(0xFF5AA9FF),
                count: signatureCount,
                label: 'Signature',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Permission list
          ...permissions.map((permission) {
            final color = _getPermissionColor(permission.level);
            return PermissionRow(
              permission: permission,
              color: color,
            );
          }),
        ],
      ),
    );
  }

  Color _getPermissionColor(String level) {
    return switch (level) {
      'dangerous' => const Color(0xFFEF6F6C),
      'signature' => const Color(0xFF5AA9FF),
      _ => const Color(0xFF6B707A),
    };
  }
}
