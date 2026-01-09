import 'package:android_tools/features/file_explorer/shared/core/int_extensions.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_type.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_explorer_menus.dart';
import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_entry_extensions.dart';
import 'package:flutter/material.dart';

class FileExplorerFileEntryItem extends StatelessWidget {
  final FileEntry file;
  final bool isSelected;
  final void Function() onDownloadFile;
  final void Function() onDeleteFile;
  final void Function() onUploadFile;
  final void Function() onRefresh;
  final void Function() onNewDirectory;
  final void Function() onTap;

  const FileExplorerFileEntryItem({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onDownloadFile,
    required this.onDeleteFile,
    required this.onTap,
    required this.onUploadFile,
    required this.onRefresh,
    required this.onNewDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: false,
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          FileExplorerMenus.showFileEntryMenu(context, details).then((value) {
            switch (value) {
              case FileEntryMenuResult.download:
                onDownloadFile();
              case FileEntryMenuResult.delete:
                onDeleteFile();
              case FileEntryMenuResult.upload:
                onUploadFile();
              case FileEntryMenuResult.refresh:
                onRefresh();
              case FileEntryMenuResult.newDirectory:
                onNewDirectory();
              case null:
            }
          });
        },
        child: ListTile(
          enabled:
              file.type == FileType.directory || file.type == FileType.file,
          selected: isSelected,
          leading: file.icon(),
          title: Text(file.name),
          subtitle: Text(
            "${file.date?.toIso8601String()}\n${file.size?.toReadableBytes()}",
          ),
          selectedTileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          onTap: onTap,
        ),
      ),
    );
  }
}
