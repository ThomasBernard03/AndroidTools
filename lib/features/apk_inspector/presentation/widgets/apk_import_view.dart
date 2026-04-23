import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_bloc.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/apk_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Import view for the APK Inspector
///
/// Displays a drop zone for importing APK files and a list of recent APKs
class ApkImportView extends StatelessWidget {
  const ApkImportView({super.key});

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
                'APK Inspector',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Drop or browse an .apk to inspect · verify signature · install on device',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Main content area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drop zone area
                Expanded(
                  child: ApkDropZone(
                    onApkSelected: (apkPath) {
                      context.read<ApkInspectorBloc>().add(
                            OnSelectApkFile(apkPath: apkPath),
                          );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // Recent APKs area (empty for now)
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    border: Border.all(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                        child: Text(
                          'RECENT',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.surfaceContainerHighest,
                                letterSpacing: 0.6,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'No recent APKs',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                ),
                          ),
                        ),
                      ),
                    ],
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
