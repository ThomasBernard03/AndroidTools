import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/presentation/apk_inspector_bloc.dart';
import 'package:android_tools/shared/presentation/widgets/info_badge.dart';
import 'package:android_tools/shared/presentation/widgets/info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Hero card displaying APK summary information
///
/// Shows app icon, name, version, badges, and install button
class ApkHeroCard extends StatelessWidget {
  final ApkInfo apkInfo;

  const ApkHeroCard({
    super.key,
    required this.apkInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InfoCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon (letter avatar for now)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colorScheme.primary,
            ),
            child: Center(
              child: Text(
                apkInfo.appLabel.isNotEmpty ? apkInfo.appLabel[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // App info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apkInfo.appLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${apkInfo.packageName} · ${apkInfo.version}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.surfaceContainerHighest,
                        fontFamily: 'monospace',
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (apkInfo.signature != null)
                      InfoBadge(
                        label: 'signed ${apkInfo.signature!.scheme}',
                        icon: Icons.check,
                        color: const Color(0xFF3FCF8E),
                      ),
                    InfoBadge(
                      label: 'min SDK ${apkInfo.minSdk}',
                      color: const Color(0xFF5AA9FF),
                    ),
                    InfoBadge(
                      label: 'target ${apkInfo.targetSdk}',
                      color: const Color(0xFF5AA9FF),
                    ),
                    InfoBadge(
                      label: apkInfo.isDebuggable ? 'debuggable' : 'release',
                      color: apkInfo.isDebuggable
                          ? const Color(0xFFE8B339)
                          : const Color(0xFF3FCF8E),
                    ),
                    InfoBadge(label: '${apkInfo.sizeInMB} MB'),
                    InfoBadge(label: '${apkInfo.abis.length} ABIs'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Install area
          BlocBuilder<ApkInspectorBloc, ApkInspectorState>(
            builder: (context, state) {
              return SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (state.status == ApkInspectorStatus.ready) ...[
                      Text(
                        'Install on device',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.surfaceContainerHighest,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton(
                            onPressed: () {
                              // TODO: Get actual device ID
                              context.read<ApkInspectorBloc>().add(
                                    OnInstallApk(deviceId: 'device-id'),
                                  );
                            },
                            child: const Text('Install APK'),
                          ),
                        ],
                      ),
                    ],
                    if (state.status == ApkInspectorStatus.installing) ...[
                      Text(
                        'Installing… ${(state.progress * 100).round()}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.surfaceContainerHighest,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 220,
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 4,
                        ),
                      ),
                    ],
                    if (state.status == ApkInspectorStatus.installed) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3FCF8E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF3FCF8E),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Installed successfully',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF3FCF8E),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

