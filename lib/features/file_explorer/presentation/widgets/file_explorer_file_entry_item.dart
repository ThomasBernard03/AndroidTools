import 'package:adb_dart/adb_dart.dart' hide FileEntry;
import 'package:android_tools/features/file_explorer/core/int_extensions.dart';
import 'package:android_tools/features/file_explorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_menus.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final dateTimeFormat = DateFormat("yyyy-MM-dd HH:mm");
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
        child: Card(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
          ),
          child: ListTile(
            tileColor: Color(0xFF131313),
            enabled:
                file.type == FileType.directory || file.type == FileType.file,
            selected: isSelected,
            leading: file.icon(),
            title: Text(file.name),
            subtitle: Row(
              spacing: 8,
              children: [
                Text(
                  file.date != null ? dateTimeFormat.format(file.date!) : "-",
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6E6E6E),
                  ),
                  height: 6,
                  width: 6,
                ),
                Text(file.size?.toReadableBytes() ?? ""),
              ],
            ),
            selectedTileColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHigh,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
