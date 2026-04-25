import 'package:flutter/material.dart';

/// Generic badge/chip component for displaying metadata.
///
/// Unifies the `_Badge` component from ApkHeroCard and `MetaChip` from
/// DeviceStatCard. Can display an optional icon and a label with customizable
/// colors and styling.
class InfoBadge extends StatelessWidget {
  /// The text to display in the badge
  final String label;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Optional color for the badge (icon and text)
  /// If null, uses the theme's onSurfaceVariant color
  final Color? color;

  /// Whether to use monospace font for the label (defaults to true)
  final bool monospace;

  /// Font size for the label (defaults to 11)
  final double fontSize;

  /// Icon size (defaults to 10)
  final double iconSize;

  const InfoBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.monospace = true,
    this.fontSize = 11,
    this.iconSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: icon != null ? 4 : 0,
        children: [
          if (icon != null) Icon(icon, size: iconSize, color: badgeColor),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: monospace ? 'monospace' : null,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
