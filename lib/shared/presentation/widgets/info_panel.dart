import 'package:flutter/material.dart';

/// Panel component with optional header and content sections.
///
/// Provides a consistent layout for panels with a title, optional trailing
/// widget in the header, and a content area. Used across APK Inspector panels
/// and can be used in other features.
class InfoPanel extends StatelessWidget {
  /// Title displayed in the header
  final String? title;

  /// Optional widget displayed at the end of the header (e.g., status badge, count)
  final Widget? trailing;

  /// Main content of the panel
  final Widget child;

  /// Padding around the content (defaults to EdgeInsets.fromLTRB(14, 6, 14, 12))
  final EdgeInsetsGeometry? contentPadding;

  const InfoPanel({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.contentPadding,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (only if title is provided)
          if (title != null)
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
                    title!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),

          // Content
          Padding(
            padding: contentPadding ?? const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}
