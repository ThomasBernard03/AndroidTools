import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/file_preview_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/widgets/file_preview_content.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_app_bar.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_file_entry_item.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_drop_target.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_menus.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  final bloc = FileExplorerBloc();
  final previewBloc = FilePreviewBloc();
  bool isDropping = false;
  final FocusNode _rootFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showSearch = false;
  int _currentMatchIndex = 0;
  List<int> _matchedIndexes = [];

  @override
  void initState() {
    super.initState();
    bloc.add(OnAppearing());
  }

  @override
  void dispose() {
    bloc.close();
    previewBloc.close();
    super.dispose();
  }

  Future<void> onUploadFiles(BuildContext context) async {
    final result = await file_picker.FilePicker.platform.pickFiles(
      dialogTitle: 'Choose file',
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    if (context.mounted) {
      final firstFile = result.files.map((f) => f.path ?? "").firstOrNull;
      if (firstFile != null && firstFile.isNotEmpty) {
        context.read<FileExplorerBloc>().add(OnUploadFile(file: firstFile));
      }
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
      context.read<FileExplorerBloc>().add(OnCreateDirectory(name: result));
    }
  }

  void _openSearch({String initialText = ""}) {
    setState(() {
      _showSearch = true;
      _searchController.text = initialText;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });

    _updateMatches();
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _showSearch = false;
      _searchController.clear();
      _matchedIndexes.clear();
      _currentMatchIndex = 0;
    });

    _rootFocus.requestFocus();
  }

  void _updateMatches() {
    final files = bloc.state.files;
    final query = _searchController.text.toLowerCase();

    setState(() {
      _matchedIndexes = [];
    });

    if (query.isEmpty) return;

    for (int i = 0; i < files.length; i++) {
      if (files.elementAt(i).name.toLowerCase().contains(query)) {
        setState(() {
          _matchedIndexes.add(i);
        });
      }
    }

    setState(() {});
  }

  void _goToNextMatch() {
    if (_matchedIndexes.isEmpty) return;

    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchedIndexes.length;
    });

    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_matchedIndexes.isEmpty) return;

    final index = _matchedIndexes[_currentMatchIndex];
    const itemHeight = 64.0;

    _scrollController.animateTo(
      index * itemHeight,
      duration: Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Focus(
        autofocus: true,
        focusNode: _rootFocus,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          final key = event.logicalKey;
          final isCtrlOrCmd =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;

          // Ctrl+F / Cmd+F
          if (isCtrlOrCmd && key == LogicalKeyboardKey.keyF) {
            _openSearch();
            return KeyEventResult.handled;
          }

          // Escape
          if (key == LogicalKeyboardKey.escape && _showSearch) {
            _closeSearch();
            return KeyEventResult.handled;
          }

          // Enter
          if (key == LogicalKeyboardKey.enter && _showSearch) {
            _goToNextMatch();
            return KeyEventResult.handled;
          }

          if (!_showSearch &&
              event.character != null &&
              event.character!.isNotEmpty &&
              event.character!.codeUnitAt(0) >= 32 &&
              !isCtrlOrCmd) {
            _openSearch(initialText: event.character!);
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: Color(0xff000000),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: BlocBuilder<FileExplorerBloc, FileExplorerState>(
              builder: (context, state) {
                return FileExplorerAppBar(
                  path: state.path.split("/").last,
                  onGoBack: state.path.isRootPath()
                      ? null
                      : () {
                          context.read<FileExplorerBloc>().add(OnGoBack());
                        },
                );
              },
            ),
          ),
          body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
            builder: (context, state) {
              return Column(
                children: [
                  if (_showSearch)
                    Container(
                      color: Color(0xFF1A1D1C),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Rechercher…",
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffix: Text(
                            "$_currentMatchIndex / ${_matchedIndexes.length}",
                          ),
                        ),
                        onChanged: (_) {
                          _currentMatchIndex = 0;
                          _updateMatches();
                          _scrollToCurrentMatch();
                        },
                        onSubmitted: (_) => _goToNextMatch(),
                      ),
                    ),
                  BlocBuilder<FileExplorerBloc, FileExplorerState>(
                    builder: (context, state) {
                      return state.isLoading
                          ? LinearProgressIndicator()
                          : SizedBox.fromSize(size: Size.fromHeight(4));
                    },
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        // Left panel: File Explorer
                        Expanded(
                          flex: 1,
                          child: FileExplorerDropTarget(
                            onFileDropped: (details) {
                              final firstFile = details.files
                                  .map((f) => f.path)
                                  .firstOrNull;
                              if (firstFile != null) {
                                context.read<FileExplorerBloc>().add(
                                  OnUploadFile(file: firstFile),
                                );
                              }
                            },
                            child: BlocBuilder<FileExplorerBloc, FileExplorerState>(
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
                                    controller: _scrollController,
                                    padding: EdgeInsets.all(16),
                                    itemCount: state.files.length,
                                    itemBuilder: (context, index) {
                                      final file = state.files.elementAt(index);
                                      return FileExplorerFileEntryItem(
                                        file: file,
                                        isSelected: state.selectedFile == file,
                                        onDownloadFile: () => context
                                            .read<FileExplorerBloc>()
                                            .add(OnDownloadFile(fileName: file.name)),
                                        onDeleteFile: () => context
                                            .read<FileExplorerBloc>()
                                            .add(OnDeleteFile(fileName: file.name)),
                                        onTap: () {
                                          context
                                              .read<FileExplorerBloc>()
                                              .add(OnFileEntryTapped(fileEntry: file));

                                          // Trigger preview for files
                                          if (file.type == FileType.file) {
                                            previewBloc.add(OnFilePreviewAppearing(
                                              fileEntry: file,
                                              currentPath: state.path,
                                            ));
                                          }
                                        },
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
                        // Divider
                        Container(
                          width: 1,
                          color: Color(0xFF2A2A2A),
                        ),
                        // Right panel: File Preview
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Color(0xFF0D0D0D),
                            child: BlocProvider.value(
                              value: previewBloc,
                              child: BlocBuilder<FilePreviewBloc, FilePreviewState>(
                                builder: (context, previewState) {
                                  return Column(
                                    children: [
                                      // Preview header
                                      if (previewState.fileEntry != null)
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF1A1D1C),
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Color(0xFF2A2A2A),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.visibility_outlined,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  previewState.fileEntry!.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Preview content
                                      Expanded(
                                        child: FilePreviewContent(state: previewState),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Color(0xFF1A1D1C),
                    child: SizedBox(
                      height: 30,
                      child: BlocBuilder<FileExplorerBloc, FileExplorerState>(
                        builder: (context, state) {
                          final parts = state.path.split("/");

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (context, index) {
                              return Icon(
                                Icons.chevron_right_rounded,
                                size: 12,
                                color: Color.fromARGB(255, 98, 99, 99),
                              );
                            },
                            itemBuilder: (context, index) {
                              final part = parts[index];
                              return TextButton(
                                onPressed: () {
                                  final newPath = parts
                                      .take(index + 1)
                                      .join("/");
                                  context.read<FileExplorerBloc>().add(
                                    OnGoToDirectory(path: newPath),
                                  );
                                },
                                child: Padding(
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
                                      Text(part),
                                    ],
                                  ),
                                ),
                              );
                            },

                            itemCount: parts.length,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
