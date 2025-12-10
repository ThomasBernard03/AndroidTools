import 'package:flutter/material.dart';

class LogcatButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final void Function()? onPressed;

  const LogcatButton({
    super.key,
    required this.color,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.grey;
          }
          return color;
        }),
      ),
      child: Icon(icon),
    );
  }
}
