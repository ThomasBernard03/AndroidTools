import 'package:flutter/material.dart';

/// Detail card with a header title and key/value rows.
class InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const InfoCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dim.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: dim,
              ),
            ),
          ),
          Divider(height: 1, color: dim.withValues(alpha: 0.15)),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.$1,
                      style: TextStyle(fontSize: 12, color: dim),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
