import 'package:android_tools/features/file_explorer/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/domain/entities/file_type.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/file_type_extensions.dart';
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
          ],
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
                  OnUploadFiles(files: details.files.map((f) => f.path)),
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
                          return GestureDetector(
                            onSecondaryTapDown: (details) {
                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  details.globalPosition.dx,
                                  details.globalPosition.dy,
                                  details.globalPosition.dx,
                                  details.globalPosition.dy,
                                ),
                                items: [
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Text('Download'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ).then((value) {
                                if (value == 'delete') {
                                  context.read<FileExplorerBloc>().add(
                                    OnDeleteFile(fileName: file.name),
                                  );
                                  return;
                                }
                                if (value == 'download') {
                                  context.read<FileExplorerBloc>().add(
                                    OnDownloadFile(fileName: file.name),
                                  );
                                }
                              });
                            },
                            child: ListTile(
                              title: ListTile(
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
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  if (isDropping)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Colors.black.withAlpha(60),
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
