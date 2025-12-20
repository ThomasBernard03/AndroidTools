import 'package:android_tools/features/file_explorer/core/int_extensions.dart';
import 'package:android_tools/features/file_explorer/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/domain/entities/file_type.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_menus.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_drop_target.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_type_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  final bloc = FileExplorerBloc();
  bool isDropping = false;

  @override
  void initState() {
    super.initState();
    bloc.add(OnAppearing());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
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
                  onPressed: () {
                    context.read<FileExplorerBloc>().add(OnRefreshFiles());
                  },
                  icon: Icon(Icons.refresh_rounded),
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
                            OnDeleteFile(fileName: selectedFile.name),
                          );
                        },
                  icon: Icon(Icons.delete),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return FileExplorerDropTarget(
              onFileDropped: (details) {
                context.read<FileExplorerBloc>().add(
                  OnUploadFiles(files: details.files.map((f) => f.path)),
                );
              },
              child: BlocBuilder<FileExplorerBloc, FileExplorerState>(
                builder: (context, state) {
                  return ListView.builder(
                    itemCount: state.files.length,
                    itemBuilder: (context, index) {
                      final file = state.files[index];
                      return GestureDetector(
                        onSecondaryTapDown: (details) {
                          FileExplorerMenus.showFileEntryMenu(
                            context,
                            details,
                          ).then((value) {
                            switch (value) {
                              case FileEntryMenuResult.download:
                                context.read<FileExplorerBloc>().add(
                                  OnDownloadFile(fileName: file.name),
                                );
                              case FileEntryMenuResult.delete:
                                context.read<FileExplorerBloc>().add(
                                  OnDeleteFile(fileName: file.name),
                                );
                              case null:
                            }
                          });
                        },
                        child: BlocBuilder<FileExplorerBloc, FileExplorerState>(
                          builder: (context, state) {
                            return ListTile(
                              enabled:
                                  file.type == FileType.directory ||
                                  file.type == FileType.file,
                              selected: state.selectedFile == file,
                              leading: Icon(file.type.icon()),
                              title: Text(file.name),
                              subtitle: Text(
                                "${file.date?.toIso8601String()}\n${file.size?.toReadableBytes()}",
                              ),
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                              onTap: () => context.read<FileExplorerBloc>().add(
                                OnFileEntryTapped(fileEntry: file),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
