import 'package:android_tools/features/apk_inspector/domain/entities/apk_signature.dart';
import 'package:android_tools/features/apk_inspector/presentation/widgets/manifest_key_value_row.dart';
import 'package:android_tools/shared/presentation/widgets/info_panel.dart';
import 'package:flutter/material.dart';

/// Panel displaying APK signature information
class SignaturePanel extends StatelessWidget {
  final ApkSignature? signature;

  const SignaturePanel({
    super.key,
    required this.signature,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (signature == null) {
      return InfoPanel(
        title: 'Signature',
        trailing: Row(
          children: [
            Icon(
              Icons.block,
              size: 14,
              color: colorScheme.error,
            ),
            const SizedBox(width: 3),
            Text(
              'unsigned',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.08),
            border: Border.all(
              color: colorScheme.error.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This APK is not signed. Unsigned APKs cannot be installed '
                  'on devices and should not be distributed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sig = signature!;

    return InfoPanel(
      title: 'Signature',
      trailing: Row(
        children: [
          if (sig.isDebugKeystore) ...[
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: const Color(0xFFE8B339),
            ),
            const SizedBox(width: 3),
            Text(
              'debug',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFE8B339),
                    fontFamily: 'monospace',
                  ),
            ),
          ] else ...[
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3FCF8E),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'verified',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF3FCF8E),
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ],
      ),
      child: Column(
        children: [
          if (sig.isDebugKeystore)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8B339).withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFFE8B339).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFE8B339),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This APK is signed with the Android debug keystore. '
                      'Debug certificates are not meant for production distribution.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFE8B339),
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ManifestKeyValueRow(label: 'Scheme', value: sig.scheme),
          ManifestKeyValueRow(label: 'Algorithm', value: sig.algorithm),
          ManifestKeyValueRow(label: 'Key size', value: '${sig.keySize}-bit'),
          ManifestKeyValueRow(label: 'Issuer', value: sig.issuer),
          ManifestKeyValueRow(label: 'Valid from', value: sig.validFrom),
          ManifestKeyValueRow(label: 'Valid to', value: sig.validTo),

          // SHA-256 fingerprint box
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHA-256 FINGERPRINT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.surfaceContainerHighest,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  sig.sha256,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
