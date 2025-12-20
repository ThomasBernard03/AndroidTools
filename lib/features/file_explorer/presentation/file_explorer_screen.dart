import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_app_bar.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_file_entry_item.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_drop_target.dart';
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: FileExplorerAppBar(),
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
                      return FileExplorerFileEntryItem(
                        file: file,
                        isSelected: state.selectedFile == file,
                        onDownloadFile: () => context
                            .read<FileExplorerBloc>()
                            .add(OnDownloadFile(fileName: file.name)),
                        onDeleteFile: () => context
                            .read<FileExplorerBloc>()
                            .add(OnDeleteFile(fileName: file.name)),
                        onTap: () => context.read<FileExplorerBloc>().add(
                          OnFileEntryTapped(fileEntry: file),
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
