import 'package:android_tools/features/file_explorer/shared/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/presentation/file_explorer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileExplorerAppBar extends StatelessWidget {
  const FileExplorerAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      centerTitle: false,
      title: BlocBuilder<FileExplorerBloc, FileExplorerState>(
        builder: (context, state) {
          return Text(state.path, style: Theme.of(context).textTheme.bodyLarge);
        },
      ),
      leading: BlocBuilder<FileExplorerBloc, FileExplorerState>(
        builder: (context, state) {
          return IconButton(
            onPressed: state.path.isRootPath()
                ? null
                : () {
                    context.read<FileExplorerBloc>().add(OnGoBack());
                  },
            icon: Icon(Icons.chevron_left_rounded),
          );
        },
      ),
    );
  }
}
