import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_app_bar.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_file_entry_item.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_drop_target.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_menus.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<void> onUploadFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose files',
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    context.read<FileExplorerBloc>().add(
      OnUploadFiles(files: result.files.map((f) => f.path ?? "")),
    );
  }

  Future<void> onShowCreateDirectoryDialog(BuildContext context) async {
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
    context.read<FileExplorerBloc>().add(OnCreateDirectory(name: result));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: FileExplorerAppBar(),
        ),
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: FileExplorerDropTarget(
                    onFileDropped: (details) {
                      context.read<FileExplorerBloc>().add(
                        OnUploadFiles(files: details.files.map((f) => f.path)),
                      );
                    },
                    child: BlocBuilder<FileExplorerBloc, FileExplorerState>(
                      builder: (context, state) {
                        return GestureDetector(
                          onSecondaryTapDown: (details) {
                            FileExplorerMenus.showGeneralMenu(
                              context,
                              details,
                            ).then((value) async {
                              if (value == FileEntryMenuResult.upload) {
                                if (context.mounted) {
                                  onUploadFiles(context);
                                }
                                return;
                              }
                              if (value == FileEntryMenuResult.refresh) {
                                if (context.mounted) {
                                  context.read<FileExplorerBloc>().add(
                                    OnRefreshFiles(),
                                  );
                                }
                                return;
                              }
                              if (value == FileEntryMenuResult.newDirectory) {
                                if (context.mounted) {
                                  await onShowCreateDirectoryDialog(context);
                                }
                                return;
                              }
                            });
                          },
                          child: ListView.builder(
                            itemCount: state.files.length,
                            itemBuilder: (context, index) {
                              final file = state.files[index];
                              return FileExplorerFileEntryItem(
                                file: file,
                                isSelected: state.selectedFile == file,
                                onDownloadFile: () => context
                                    .read<FileExplorerBloc>()
                                    .add(OnDownloadFile(fileName: file.name)),
                                onDeleteFile: () => context
                                    .read<FileExplorerBloc>()
                                    .add(OnDeleteFile(fileName: file.name)),
                                onTap: () => context
                                    .read<FileExplorerBloc>()
                                    .add(OnFileEntryTapped(fileEntry: file)),
                                onUploadFile: () async {
                                  await onUploadFiles(context);
                                },
                                onRefresh: () => context
                                    .read<FileExplorerBloc>()
                                    .add(OnRefreshFiles()),
                                onNewDirectory: () async {
                                  await onShowCreateDirectoryDialog(context);
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                BlocBuilder<FileExplorerBloc, FileExplorerState>(
                  builder: (context, state) {
                    return state.isLoading
                        ? LinearProgressIndicator()
                        : SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
