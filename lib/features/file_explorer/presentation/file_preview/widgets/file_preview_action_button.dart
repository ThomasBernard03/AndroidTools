import 'package:flutter/material.dart';

class FilePreviewActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function() onPressed;

  const FilePreviewActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
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
      child: Column(children: [Icon(icon), Text(text)]),
    );
  }
}
