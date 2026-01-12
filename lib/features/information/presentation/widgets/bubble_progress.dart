import 'package:flutter/material.dart';

class BubbleProgress extends StatelessWidget {
  final double percentage; // 0 à 100
  final int totalBubbles;
  final double size;
  final double spacing;

  const BubbleProgress({
    super.key,
    required this.percentage,
    this.totalBubbles = 30,
    this.size = 16,
    this.spacing = 1,
  });

  @override
  Widget build(BuildContext context) {
    final filledBubbles = (percentage.clamp(0, 100) / 100 * totalBubbles)
        .round();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(totalBubbles, (index) {
        final isFilled = index < filledBubbles;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFilled ? Theme.of(context).primaryColor : Colors.white,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
