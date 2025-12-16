import 'package:android_tools/features/fileexplorer/core/string_extensions.dart';
import 'package:android_tools/features/fileexplorer/domain/entities/file_type.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_type_extensions.dart';
import 'package:desktop_drop/desktop_drop.dart';
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
        ),
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return DropTarget(
              onDragEntered: (_) {
                setState(() => isDropping = true);
              },
              onDragExited: (_) {
                setState(() => isDropping = false);
              },
              onDragDone: (details) {
                context.read<FileExplorerBloc>().add(
                  OnUploadFile(files: details.files.map((f) => f.path)),
                );
              },
              child: Stack(
                children: [
                  BlocBuilder<FileExplorerBloc, FileExplorerState>(
                    builder: (context, state) {
                      return ListView.builder(
                        itemCount: state.files.length,
                        itemBuilder: (context, index) {
                          final file = state.files[index];
                          return ListTile(
                            leading: Icon(file.type.icon()),
                            title: Text(file.name),
                            subtitle: Text(file.date.toString()),
                            onTap: () {
                              if (file.type == FileType.directory) {
                                context.read<FileExplorerBloc>().add(
                                  OnGoToFolder(folder: file),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),

                  if (isDropping)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.file_download_outlined,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Drop your files here',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
