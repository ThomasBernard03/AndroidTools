import 'package:android_tools/features/file_explorer/general_file_explorer/presentation/general_file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/shared/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_explorer_app_bar.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_explorer_file_entry_item.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_explorer_drop_target.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_explorer_menus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class GeneralFileExplorerScreen extends StatefulWidget {
  const GeneralFileExplorerScreen({super.key});

  @override
  State<GeneralFileExplorerScreen> createState() =>
      _GeneralFileExplorerScreenState();
}

class _GeneralFileExplorerScreenState extends State<GeneralFileExplorerScreen> {
  final bloc = GeneralFileExplorerBloc();
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
    if (context.mounted) {
      context.read<GeneralFileExplorerBloc>().add(
        OnUploadFiles(files: result.files.map((f) => f.path ?? "")),
      );
    }
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
    if (context.mounted) {
      context.read<GeneralFileExplorerBloc>().add(
        OnCreateDirectory(name: result),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: Color(0xff000000),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<GeneralFileExplorerBloc, GeneralFileExplorerState>(
            builder: (context, state) {
              return FileExplorerAppBar(
                path: state.path.split("/").last,
                onGoBack: state.path.isRootPath()
                    ? null
                    : () {
                        context.read<GeneralFileExplorerBloc>().add(OnGoBack());
                      },
              );
            },
          ),
        ),
        body: BlocBuilder<GeneralFileExplorerBloc, GeneralFileExplorerState>(
          builder: (context, state) {
            return Column(
              children: [
                BlocBuilder<GeneralFileExplorerBloc, GeneralFileExplorerState>(
                  builder: (context, state) {
                    return state.isLoading
                        ? LinearProgressIndicator()
                        : SizedBox.fromSize(size: Size.fromHeight(4));
                  },
                ),
                Expanded(
                  child: FileExplorerDropTarget(
                    onFileDropped: (details) {
                      context.read<GeneralFileExplorerBloc>().add(
                        OnUploadFiles(files: details.files.map((f) => f.path)),
                      );
                    },
                    child:
                        BlocBuilder<
                          GeneralFileExplorerBloc,
                          GeneralFileExplorerState
                        >(
                          builder: (context, state) {
                            return GestureDetector(
                              behavior: HitTestBehavior.deferToChild,
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
                                      context
                                          .read<GeneralFileExplorerBloc>()
                                          .add(OnRefreshFiles());
                                    }
                                    return;
                                  }
                                  if (value ==
                                      FileEntryMenuResult.newDirectory) {
                                    if (context.mounted) {
                                      await onShowCreateDirectoryDialog(
                                        context,
                                      );
                                    }
                                    return;
                                  }
                                });
                              },
                              child: ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: state.files.length,
                                itemBuilder: (context, index) {
                                  final file = state.files[index];
                                  return FileExplorerFileEntryItem(
                                    file: file,
                                    isSelected: state.selectedFile == file,
                                    onDownloadFile: () => context
                                        .read<GeneralFileExplorerBloc>()
                                        .add(
                                          OnDownloadFile(fileName: file.name),
                                        ),
                                    onDeleteFile: () => context
                                        .read<GeneralFileExplorerBloc>()
                                        .add(OnDeleteFile(fileName: file.name)),
                                    onTap: () => context
                                        .read<GeneralFileExplorerBloc>()
                                        .add(
                                          OnFileEntryTapped(fileEntry: file),
                                        ),
                                    onUploadFile: () async {
                                      await onUploadFiles(context);
                                    },
                                    onRefresh: () => context
                                        .read<GeneralFileExplorerBloc>()
                                        .add(OnRefreshFiles()),
                                    onNewDirectory: () async {
                                      await onShowCreateDirectoryDialog(
                                        context,
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ),
                Container(
                  color: Color(0xFF1A1D1C),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 30,
                      child:
                          BlocBuilder<
                            GeneralFileExplorerBloc,
                            GeneralFileExplorerState
                          >(
                            builder: (context, state) {
                              final parts = state.path.split("/");

                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                separatorBuilder: (context, index) {
                                  return Icon(
                                    Icons.chevron_right_rounded,
                                    size: 12,
                                    color: Color.fromARGB(255, 98, 99, 99),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Row(
                                      spacing: 4,
                                      children: [
                                        SvgPicture.asset(
                                          "assets/images/folder/red_folder.svg",
                                          width: 12,
                                        ),
                                        Text(parts[index]),
                                      ],
                                    ),
                                  );
                                },

                                itemCount: parts.length,
                              );
                            },
                          ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
