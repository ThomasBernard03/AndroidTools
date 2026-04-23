import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_bloc.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/apk_hero_card.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/components_panel.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/manifest_panel.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/permissions_panel.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/signature_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// APK report view displaying comprehensive APK information
///
/// Shows breadcrumb navigation, hero card, and panels for signature,
/// permissions, manifest, and components
class ApkReportView extends StatelessWidget {
  const ApkReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApkInspectorBloc, ApkInspectorState>(
      builder: (context, state) {
        final apkInfo = state.apkInfo;

        if (apkInfo == null) {
          return const Center(
            child: Text('No APK data available'),
          );
        }

        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          children: [
            // Top bar with breadcrumb navigation
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
                  // Breadcrumb back button
                  InkWell(
                    onTap: () {
                      context.read<ApkInspectorBloc>().add(OnResetView());
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        Text(
                          'APK Inspector',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    '/',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        ),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      apkInfo.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Body with scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero card
                    ApkHeroCard(apkInfo: apkInfo),

                    const SizedBox(height: 16),

                    // Panels grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate number of columns based on width
                        final availableWidth = constraints.maxWidth;
                        final minCardWidth = 360.0;
                        final columns = (availableWidth / (minCardWidth + 12)).floor().clamp(1, 4);

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // Signature panel (if available)
                            if (apkInfo.signature != null)
                              SizedBox(
                                width: (availableWidth - (12 * (columns - 1))) / columns,
                                child: SignaturePanel(signature: apkInfo.signature!),
                              ),

                            // Manifest panel
                            SizedBox(
                              width: (availableWidth - (12 * (columns - 1))) / columns,
                              child: ManifestPanel(apkInfo: apkInfo),
                            ),

                            // Components panel
                            SizedBox(
                              width: (availableWidth - (12 * (columns - 1))) / columns,
                              child: ComponentsPanel(apkInfo: apkInfo),
                            ),

                            // Permissions panel
                            SizedBox(
                              width: (availableWidth - (12 * (columns - 1))) / columns,
                              child: PermissionsPanel(permissions: apkInfo.permissions),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Row(
                children: [
                  Text(
                    'APK parsed · ${apkInfo.permissions.length} permissions · '
                    '${apkInfo.activitiesCount + apkInfo.servicesCount + apkInfo.receiversCount + apkInfo.providersCount} components',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    'aapt dump badging · apksigner verify',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.surfaceContainerHighest,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
