import 'package:flutter/material.dart';

class InformationRecapItem extends StatelessWidget {
  final String label;
  final String value;

  const InformationRecapItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(180),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
