import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_bloc.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/apk_drop_zone.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/recent_apk_item.dart';
import 'package:android_tools/shared/presentation/widgets/info_card.dart';
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

                // Recent APKs area
                SizedBox(
                  width: 260,
                  child: InfoCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          child: Text(
                            'Recent',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: BlocBuilder<ApkInspectorBloc,
                                ApkInspectorState>(
                              builder: (context, state) {
                                if (state.recentApks.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No recent APKs',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  itemCount: state.recentApks.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(
                                    height: 1,
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.1),
                                  ),
                                  itemBuilder: (context, index) {
                                    final apk = state.recentApks[index];
                                    return RecentApkItem(
                                      apkInfo: apk,
                                      onTap: () {
                                        context.read<ApkInspectorBloc>().add(
                                              OnSelectRecentApk(
                                                apkPath: apk.filePath,
                                              ),
                                            );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
