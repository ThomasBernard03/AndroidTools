import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:flutter/material.dart';

class RecentApkItem extends StatelessWidget {
  final ApkInfo apkInfo;
  final VoidCallback onTap;

  const RecentApkItem({
    super.key,
    required this.apkInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                apkInfo.appLabel,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                apkInfo.packageName,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      apkInfo.version,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${apkInfo.sizeInMB} MB',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
