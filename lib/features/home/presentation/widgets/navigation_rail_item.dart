import 'package:flutter/material.dart';

class NavigationRailItem extends StatelessWidget {
  final bool selected;
  final String text;
  final void Function()? onTap;

  const NavigationRailItem({
    super.key,
    required this.selected,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          spacing: 8,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.white : Color(0xFFA9AEB2),
                fontWeight: selected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
