import 'package:android_tools/features/file_explorer/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileExplorerAppBar extends StatelessWidget {
  const FileExplorerAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      title: BlocBuilder<FileExplorerBloc, FileExplorerState>(
        builder: (context, state) {
          return Text(state.path);
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
      actions: [
        BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return IconButton(
              onPressed: () async {
                final result = await showDialog<String?>(
                  context: context,
                  builder: (context) {
                    final controller = TextEditingController();
                    return AlertDialog(
                      title: Text("Create new directory"),
                      content: TextFormField(controller: controller),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(controller.text);
                          },
                          child: Text("Create"),
                        ),
                      ],
                    );
                  },
                );

                if (result == null || result.isEmpty) {
                  return;
                }
                context.read<FileExplorerBloc>().add(
                  OnCreateDirectory(name: result),
                );
              },
              icon: Icon(Icons.create_new_folder_outlined),
            );
          },
        ),
        BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return IconButton(
              onPressed: () {
                context.read<FileExplorerBloc>().add(OnRefreshFiles());
              },
              icon: Icon(Icons.refresh_rounded),
            );
          },
        ),
        VerticalDivider(),
        BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.selectedFile == null
                  ? null
                  : () {
                      final selectedFile = state.selectedFile;
                      if (selectedFile == null) return;
                      context.read<FileExplorerBloc>().add(
                        OnDeleteFile(fileName: selectedFile.name),
                      );
                    },
              icon: Icon(Icons.delete),
            );
          },
        ),
        BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return IconButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  dialogTitle: 'Choose files',
                );
                if (result == null || result.files.isEmpty) {
                  return;
                }
                context.read<FileExplorerBloc>().add(
                  OnUploadFiles(files: result.files.map((f) => f.path ?? "")),
                );
              },
              icon: Icon(Icons.upload_rounded),
            );
          },
        ),
        BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return IconButton(
              onPressed: state.selectedFile == null
                  ? null
                  : () {
                      final selectedFile = state.selectedFile;
                      if (selectedFile == null) return;
                      context.read<FileExplorerBloc>().add(
                        OnDownloadFile(fileName: selectedFile.name),
                      );
                    },
              icon: Icon(Icons.download_rounded),
            );
          },
        ),
      ],
    );
  }
}
