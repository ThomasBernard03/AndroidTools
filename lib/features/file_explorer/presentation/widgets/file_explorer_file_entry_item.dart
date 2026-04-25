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

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String? query,
    TextStyle? style, {
    required Color textColor,
  }) {
    if (query == null || query.isEmpty) {
      return Text(
        text,
        style: (style ?? const TextStyle()).copyWith(color: textColor),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int currentIndex = 0;

    // Create base style with proper text color
    final baseStyle = (style ?? const TextStyle()).copyWith(color: textColor);

    while (currentIndex < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, currentIndex);

      if (matchIndex == -1) {
        // No more matches, add remaining text
        matches.add(
          TextSpan(text: text.substring(currentIndex), style: baseStyle),
        );
        break;
      }

      // Add text before match
      if (matchIndex > currentIndex) {
        matches.add(
          TextSpan(
            text: text.substring(currentIndex, matchIndex),
            style: baseStyle,
          ),
        );
      }

      // Add highlighted match
      matches.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: TextStyle(
            backgroundColor: Colors.orange,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      currentIndex = matchIndex + query.length;
    }

    return Text.rich(
      TextSpan(children: matches, style: baseStyle),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final parts = <String>[];
    if (file.size != null) parts.add(file.size!.toReadableBytes());
    if (file.date != null) parts.add(DateFormat('dd MMM yyyy HH:mm').format(file.date!));
    if (parts.isEmpty) return null;
    return Text(
      parts.join('  ·  '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isSelected
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.7)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

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
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(12)),
          ),
          child: ListTile(
            selectedColor: Theme.of(context).colorScheme.surface,
            selectedTileColor: Theme.of(context).colorScheme.onSurface,
            tileColor: Colors.transparent,
            enabled:
                file.type == FileType.directory || file.type == FileType.file,
            selected: isSelected,
            leading: file.icon(),
            title: _buildHighlightedText(
              context,
              file.name,
              searchQuery,
              null,
              textColor: isSelected
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.onSurface,
            ),
            subtitle: _buildSubtitle(context),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
