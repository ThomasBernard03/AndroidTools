import 'package:android_tools/features/apk_inspector/domain/entities/apk_signature.dart';
import 'package:android_tools/shared/presentation/widgets/info_panel.dart';
import 'package:flutter/material.dart';

/// Panel displaying APK signature information
class SignaturePanel extends StatelessWidget {
  final ApkSignature signature;

  const SignaturePanel({
    super.key,
    required this.signature,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InfoPanel(
      title: 'Signature',
      trailing: Row(
        children: [
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
      ),
      child: Column(
        children: [
          _KeyValueRow(label: 'Scheme', value: signature.scheme),
          _KeyValueRow(label: 'Algorithm', value: signature.algorithm),
          _KeyValueRow(label: 'Key size', value: '${signature.keySize}-bit'),
          _KeyValueRow(label: 'Issuer', value: signature.issuer),
          _KeyValueRow(label: 'Valid from', value: signature.validFrom),
          _KeyValueRow(label: 'Valid to', value: signature.validTo),

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
                  signature.sha256,
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

/// Key-value row widget for signature details
class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.surfaceContainerHighest,
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
