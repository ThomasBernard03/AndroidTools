import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/file_explorer/core/string_extensions.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/file_preview_bloc.dart';
import 'package:android_tools/features/file_explorer/presentation/file_preview/file_preview_screen.dart';
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

  // Search
  final FocusNode _rootFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearch = false;
  List<int> _matchingIndexes = [];
  int _currentMatchIndex = -1;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    bloc.add(OnAppearing());
  }

  @override
  void dispose() {
    bloc.close();
    previewBloc.close();
    _rootFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearch({String initialText = ""}) {
    setState(() {
      _showSearch = true;
      _searchController.text = initialText;
    });
    _searchFocusNode.requestFocus();
    _updateMatches();
  }

  void _closeSearch() {
    setState(() {
      _showSearch = false;
      _searchController.clear();
      _matchingIndexes.clear();
      _currentMatchIndex = -1;
    });
    _rootFocusNode.requestFocus();
  }

  void _updateMatches() {
    final query = _searchController.text.toLowerCase().trim();
    final files = bloc.state.files;

    if (query.isEmpty) {
      setState(() {
        _matchingIndexes.clear();
        _currentMatchIndex = -1;
      });
      return;
    }

    final matches = <int>[];
    for (int i = 0; i < files.length; i++) {
      if (files.elementAt(i).name.toLowerCase().contains(query)) {
        matches.add(i);
      }
    }

    setState(() {
      _matchingIndexes = matches;
      _currentMatchIndex = matches.isEmpty ? -1 : 0;
    });

    if (_currentMatchIndex >= 0) {
      _scrollToMatch(_currentMatchIndex);
    }
  }

  void _goToNextMatch() {
    if (_matchingIndexes.isEmpty) return;

    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchingIndexes.length;
    });
    _scrollToMatch(_currentMatchIndex);
  }

  void _goToPreviousMatch() {
    if (_matchingIndexes.isEmpty) return;

    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchingIndexes.length) %
          _matchingIndexes.length;
    });
    _scrollToMatch(_currentMatchIndex);
  }

  void _scrollToMatch(int matchIndex) {
    if (matchIndex < 0 || matchIndex >= _matchingIndexes.length) return;

    final fileIndex = _matchingIndexes[matchIndex];
    const itemHeight = 48.0;
    final targetOffset = fileIndex * itemHeight;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: Focus(
        focusNode: _rootFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          final isCtrlOrCmd =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;

          // Cmd/Ctrl + F: Open search
          if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyF) {
            _openSearch();
            return KeyEventResult.handled;
          }

          // Escape: Close search
          if (event.logicalKey == LogicalKeyboardKey.escape && _showSearch) {
            _closeSearch();
            return KeyEventResult.handled;
          }

          // Enter: Next match when search is open
          if (event.logicalKey == LogicalKeyboardKey.enter && _showSearch) {
            _goToNextMatch();
            return KeyEventResult.handled;
          }

          // Any printable character: Open search with that character
          if (!_showSearch &&
              !isCtrlOrCmd &&
              event.character != null &&
              event.character!.isNotEmpty &&
              event.character!.codeUnitAt(0) >= 32) {
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
                                // Check if path has changed and update search results
                                if (_currentPath != state.path) {
                                  _currentPath = state.path;
                                  // Update matches on next frame to avoid calling setState during build
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (_showSearch && mounted) {
                                      _updateMatches();
                                    }
                                  });
                                }

                                return Column(
                                  children: [
                                    if (_showSearch)
                                      Container(
                                        color: Color(0xFF1E1E1E),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _searchController,
                                                focusNode: _searchFocusNode,
                                                autofocus: true,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Rechercher...',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white54,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  isDense: true,
                                                  suffixText:
                                                      _matchingIndexes.isEmpty
                                                      ? '0/0'
                                                      : '${_currentMatchIndex + 1}/${_matchingIndexes.length}',
                                                  suffixStyle: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                onChanged: (_) =>
                                                    _updateMatches(),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            IconButton(
                                              icon: Icon(
                                                Icons.keyboard_arrow_up,
                                                color: Colors.white,
                                              ),
                                              onPressed:
                                                  _matchingIndexes.isEmpty
                                                  ? null
                                                  : _goToPreviousMatch,
                                              tooltip:
                                                  'Précédent (Shift+Enter)',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.white,
                                              ),
                                              onPressed:
                                                  _matchingIndexes.isEmpty
                                                  ? null
                                                  : _goToNextMatch,
                                              tooltip: 'Suivant (Enter)',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                              onPressed: _closeSearch,
                                              tooltip: 'Fermer (Escape)',
                                              padding: EdgeInsets.all(4),
                                              constraints: BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.deferToChild,
                                        onSecondaryTapDown: (details) {
                                          FileExplorerMenus.showGeneralMenu(
                                            context,
                                            details,
                                          ).then((value) async {
                                            if (value ==
                                                FileEntryMenuResult.upload) {
                                              if (context.mounted) {
                                                onUploadFiles(context);
                                              }
                                              return;
                                            }
                                            if (value ==
                                                FileEntryMenuResult.refresh) {
                                              if (context.mounted) {
                                                context
                                                    .read<FileExplorerBloc>()
                                                    .add(OnRefreshFiles());
                                              }
                                              return;
                                            }
                                            if (value ==
                                                FileEntryMenuResult
                                                    .newDirectory) {
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
                                          controller: _scrollController,
                                          padding: EdgeInsets.all(16),
                                          itemCount: state.files.length,
                                          itemBuilder: (context, index) {
                                            final file = state.files.elementAt(
                                              index,
                                            );
                                            final query =
                                                _showSearch &&
                                                    _searchController
                                                        .text
                                                        .isNotEmpty
                                                ? _searchController.text
                                                : null;

                                            return FileExplorerFileEntryItem(
                                              file: file,
                                              isSelected:
                                                  state.selectedFile == file,
                                              searchQuery: query,
                                              onDownloadFile: () => context
                                                  .read<FileExplorerBloc>()
                                                  .add(
                                                    OnDownloadFile(
                                                      fileName: file.name,
                                                    ),
                                                  ),
                                              onDeleteFile: () => context
                                                  .read<FileExplorerBloc>()
                                                  .add(
                                                    OnDeleteFile(
                                                      fileName: file.name,
                                                    ),
                                                  ),
                                              onTap: () {
                                                context
                                                    .read<FileExplorerBloc>()
                                                    .add(
                                                      OnFileEntryTapped(
                                                        fileEntry: file,
                                                      ),
                                                    );

                                                // Trigger preview for files
                                                if (file.type ==
                                                    FileType.file) {
                                                  previewBloc.add(
                                                    OnFilePreviewAppearing(
                                                      fileEntry: file,
                                                      currentPath: state.path,
                                                    ),
                                                  );
                                                }
                                              },
                                              onUploadFile: () async {
                                                await onUploadFiles(context);
                                              },
                                              onRefresh: () => context
                                                  .read<FileExplorerBloc>()
                                                  .add(OnRefreshFiles()),
                                              onNewDirectory: () async {
                                                await onShowCreateDirectoryDialog(
                                                  context,
                                                );
                                              },
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
                        // Divider
                        Container(width: 1, color: Color(0xFF2A2A2A)),
                        // Right panel: File Preview
                        BlocBuilder<FileExplorerBloc, FileExplorerState>(
                          builder: (context, state) {
                            return Expanded(
                              flex: 1,
                              child: state.selectedFile != null
                                  ? FilePreviewScreen(
                                      key: ValueKey(
                                        '${state.path}/${state.selectedFile!.name}',
                                      ),
                                      fileEntry: state.selectedFile!,
                                      currentPath: state.path,
                                    )
                                  : SizedBox.shrink(),
                            );
                          },
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
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
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
