import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/core/int_extensions.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_menu_result.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_explorer_menus.dart';
import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FileExplorerFileEntryItem extends StatelessWidget {
  final FileEntry file;
  final bool isSelected;
  final String? searchQuery;
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
    this.searchQuery,
    required this.onDownloadFile,
    required this.onDeleteFile,
    required this.onTap,
    required this.onUploadFile,
    required this.onRefresh,
    required this.onNewDirectory,
  });

  Widget _buildHighlightedText(String text, String? query, TextStyle? style) {
    if (query == null || query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, currentIndex);

      if (matchIndex == -1) {
        // No more matches, add remaining text
        matches.add(TextSpan(
          text: text.substring(currentIndex),
          style: style,
        ));
        break;
      }

      // Add text before match
      if (matchIndex > currentIndex) {
        matches.add(TextSpan(
          text: text.substring(currentIndex, matchIndex),
          style: style,
        ));
      }

      // Add highlighted match
      matches.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: style?.copyWith(
          backgroundColor: Colors.orange,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ) ?? TextStyle(
          backgroundColor: Colors.orange,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(children: matches),
    );
  }

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
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
          ),
          child: ListTile(
            selectedColor: Theme.of(context).colorScheme.onPrimary,
            selectedTileColor: Theme.of(context).colorScheme.primary,
            tileColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : Color(0xFF131313),
            enabled:
                file.type == FileType.directory || file.type == FileType.file,
            selected: isSelected,
            leading: file.icon(),
            title: _buildHighlightedText(
              file.name,
              searchQuery,
              DefaultTextStyle.of(context).style,
            ),
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
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
