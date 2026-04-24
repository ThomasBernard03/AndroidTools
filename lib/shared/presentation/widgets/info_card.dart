import 'package:flutter/material.dart';

/// Generic card container with consistent styling across the app.
///
/// Used for displaying information in cards with a surface container background,
/// border, and rounded corners. This component unifies the styling used in
/// StatCardShell, ApkHeroCard, and various panels.
///
/// Supports dynamic styling via optional parameters for border color, width,
/// background color, and border radius.
class InfoCard extends StatelessWidget {
  /// The content to display inside the card
  final Widget child;

  /// Optional padding around the child (defaults to 16)
  final EdgeInsetsGeometry? padding;

  /// Optional border color (defaults to surfaceContainerHighest with alpha 0.15)
  final Color? borderColor;

  /// Optional border width (defaults to 1)
  final double? borderWidth;

  /// Optional background color (defaults to surfaceContainer)
  final Color? backgroundColor;

  /// Optional border radius (defaults to 8)
  final double? borderRadius;

  /// Optional border stroke alignment (defaults to BorderSide.strokeAlignCenter)
  final double? strokeAlign;

  const InfoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.borderWidth,
    this.backgroundColor,
    this.borderRadius,
    this.strokeAlign,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surfaceContainer,
        border: Border.all(
          color: borderColor ??
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          width: borderWidth ?? 1,
          strokeAlign: strokeAlign ?? BorderSide.strokeAlignCenter,
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
