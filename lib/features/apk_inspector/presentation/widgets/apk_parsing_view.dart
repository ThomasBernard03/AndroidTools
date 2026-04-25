import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_bloc.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/parsing_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Parsing progress view for APK Inspector
///
/// Shows animated progress bar and step-by-step checklist
class ApkParsingView extends StatelessWidget {
  const ApkParsingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ApkInspectorBloc, ApkInspectorState>(
      builder: (context, state) {
        final progress = state.progress;
        final progressPercent = (progress * 100).round();

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
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'READING ARCHIVE · $progressPercent%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.surfaceContainerHighest,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Step checklist
                      ParsingStep(
                        label: 'Extracting AndroidManifest.xml',
                        isComplete: true,
                      ),
                      ParsingStep(
                        label: 'Parsing resources.arsc',
                        isComplete: progress > 0.3,
                      ),
                      ParsingStep(
                        label: 'Verifying signature (v2+v3)',
                        isComplete: progress > 0.55,
                      ),
                      ParsingStep(
                        label: 'Listing permissions & components',
                        isComplete: progress > 0.8,
                      ),
                      ParsingStep(
                        label: 'Building summary',
                        isComplete: progress >= 1.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
