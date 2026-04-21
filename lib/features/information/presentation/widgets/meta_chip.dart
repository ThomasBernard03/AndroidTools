import 'package:flutter/material.dart';

/// Petit label icône + texte monospace, utilisé dans DeviceStatCard.
class MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const MetaChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Row(
      spacing: 3,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: dim),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: dim, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
