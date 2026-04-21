import 'package:flutter/material.dart';

/// Conteneur visuel commun à toutes les stat cards du header.
class StatCardShell extends StatelessWidget {
  final Widget child;

  const StatCardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dim.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
