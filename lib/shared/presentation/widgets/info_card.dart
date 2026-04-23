import 'package:flutter/material.dart';

/// Generic card container with consistent styling across the app.
///
/// Used for displaying information in cards with a surface container background,
/// border, and rounded corners. This component unifies the styling used in
/// StatCardShell, ApkHeroCard, and various panels.
class InfoCard extends StatelessWidget {
  /// The content to display inside the card
  final Widget child;

  /// Optional padding around the child (defaults to 16)
  final EdgeInsetsGeometry? padding;

  const InfoCard({super.key, required this.child, this.padding});

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
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
