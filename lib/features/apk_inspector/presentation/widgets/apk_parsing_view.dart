import 'package:flutter/material.dart';

/// Parsing progress view for APK Inspector
///
/// Shows animated progress bar and step-by-step checklist
class ApkParsingView extends StatelessWidget {
  const ApkParsingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Top bar
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(
                'Parsing APK…',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),

        // Centered progress content
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Reading APK archive…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
