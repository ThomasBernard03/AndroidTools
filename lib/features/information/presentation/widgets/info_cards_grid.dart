import 'package:flutter/material.dart';

/// Grille responsive de cartes de détail.
/// Toutes les cartes tiennent sur la même ligne si la place le permet,
/// sinon elles passent à la ligne suivante. Largeur minimale par carte : 240 px.
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
