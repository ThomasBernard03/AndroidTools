import 'package:flutter/material.dart';

/// Individual parsing step indicator
class ParsingStep extends StatelessWidget {
  final String label;
  final bool isComplete;

  const ParsingStep({
    super.key,
    required this.label,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            isComplete ? '✓' : '…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                  height: 1.7,
                ),
          ),
        ],
      ),
    );
  }
}
