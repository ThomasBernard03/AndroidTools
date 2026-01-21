import 'package:bitsdojo_window/bitsdojo_window.dart';
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
    return MoveWindow(
      child: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(path, style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          onPressed: onGoBack,
          icon: Icon(Icons.chevron_left_rounded),
        ),
      ),
    );
  }
}
