import 'package:flutter/material.dart';

/// Responsive grid of detail cards.
/// All cards fit on the same line if space permits,
/// otherwise they wrap to the next line. Minimum width per card: 240 px.
class InfoCardsGrid extends StatelessWidget {
  final List<Widget> cards;

  static const double _minCardWidth = 240;
  static const double _spacing = 16;

  const InfoCardsGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final n = cards.length;

        int perRow = 1;
        for (int k = n; k >= 1; k--) {
          if (k * _minCardWidth + (k - 1) * _spacing <= available) {
            perRow = k;
            break;
          }
        }

        final cardWidth = (available - (perRow - 1) * _spacing) / perRow;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: cards
              .map((c) => SizedBox(width: cardWidth, child: c))
              .toList(),
        );
      },
    );
  }
}
