import 'package:android_tools/features/file_explorer/general_file_explorer/presentation/general_file_explorer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileExplorerAppBar extends StatelessWidget {
  final void Function()? onGoBack;

  const FileExplorerAppBar({super.key, required this.onGoBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      centerTitle: false,
      title: BlocBuilder<GeneralFileExplorerBloc, GeneralFileExplorerState>(
        builder: (context, state) {
          return Text(state.path, style: Theme.of(context).textTheme.bodyLarge);
        },
      ),
      leading: BlocBuilder<GeneralFileExplorerBloc, GeneralFileExplorerState>(
        builder: (context, state) {
          return IconButton(
            onPressed: onGoBack,
            icon: Icon(Icons.chevron_left_rounded),
          );
        },
      ),
    );
  }
}
