import 'package:flutter/material.dart';

class NavigationRailItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String text;
  final void Function()? onTap;

  const NavigationRailItem({
    super.key,
    required this.selected,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(8),
      ),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: selected
          ? Theme.of(context).colorScheme.surfaceContainer
          : Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                size: 16,
                icon,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              Text(text, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
