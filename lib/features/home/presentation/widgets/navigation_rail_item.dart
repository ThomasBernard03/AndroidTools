import 'package:flutter/material.dart';

class NavigationRailItem extends StatelessWidget {
  final bool selected;
  final String text;
  final IconData? icon;
  final String? shortcut;
  final void Function()? onTap;

  const NavigationRailItem({
    super.key,
    required this.selected,
    required this.text,
    this.icon,
    this.shortcut,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dimColor = const Color(0xFF6B707A);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border(
                  left: BorderSide(color: primary, width: 2),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? primary : dimColor,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? primary : const Color(0xFFA7ABB4),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (shortcut != null)
              Text(
                shortcut!,
                style: TextStyle(fontSize: 11, color: dimColor),
              ),
          ],
        ),
      ),
    );
  }
}
