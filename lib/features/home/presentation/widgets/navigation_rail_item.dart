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
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        selected: selected,
        leading: Icon(
          size: 16,
          icon,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        title: Text(text, style: TextStyle(fontSize: 14)),
        hoverColor: Theme.of(context).colorScheme.surfaceContainerLow,
        selectedTileColor: Theme.of(context).colorScheme.surfaceContainer,
        onTap: onTap,
      ),
    );
  }
}
