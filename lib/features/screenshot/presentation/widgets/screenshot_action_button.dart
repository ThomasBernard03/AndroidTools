import 'package:flutter/material.dart';

class ScreenshotActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const ScreenshotActionButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onPressed: onPressed,
      child: Column(
        children: [
          Icon(icon),
          Text(text),
        ],
      ),
    );
  }
}
