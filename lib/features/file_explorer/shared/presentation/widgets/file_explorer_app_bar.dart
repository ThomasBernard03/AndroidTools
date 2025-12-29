import 'package:flutter/material.dart';

class FileExplorerAppBar extends StatelessWidget {
  final void Function()? onGoBack;
  final String path;

  const FileExplorerAppBar({
    super.key,
    required this.path,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      centerTitle: false,
      title: Text(path, style: Theme.of(context).textTheme.bodyLarge),
      leading: IconButton(
        onPressed: onGoBack,
        icon: Icon(Icons.chevron_left_rounded),
      ),
    );
  }
}
