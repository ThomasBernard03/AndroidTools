import 'package:android_tools/features/apk_inspector/domain/entities/apk_permission.dart';
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
            child: Row(
              children: [
                Text(
                  'Permissions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${permissions.length} total',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.surfaceContainerHighest,
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legend
                Row(
                  children: [
                    _PermissionLegend(
                      color: const Color(0xFFEF6F6C),
                      count: dangerousCount,
                      label: 'Dangerous',
                    ),
                    const SizedBox(width: 12),
                    _PermissionLegend(
                      color: colorScheme.onSurfaceVariant,
                      count: normalCount,
                      label: 'Normal',
                    ),
                    const SizedBox(width: 12),
                    _PermissionLegend(
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
                  return _PermissionRow(
                    permission: permission,
                    color: color,
                  );
                }),
              ],
            ),
          ),
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

/// Permission legend item
class _PermissionLegend extends StatelessWidget {
  final Color color;
  final int count;
  final String label;

  const _PermissionLegend({
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.surfaceContainerHighest,
              ),
        ),
      ],
    );
  }
}

/// Individual permission row
class _PermissionRow extends StatelessWidget {
  final ApkPermission permission;
  final Color color;

  const _PermissionRow({
    required this.permission,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              permission.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            permission.level.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  letterSpacing: 0.5,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
