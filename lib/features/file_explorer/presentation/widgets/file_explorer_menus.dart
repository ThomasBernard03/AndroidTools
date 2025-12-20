import 'package:android_tools/features/file_explorer/presentation/widgets/file_entry_menu_result.dart';
import 'package:flutter/material.dart';

class FileExplorerMenus {
  static Future<FileEntryMenuResult?> showFileEntryMenu<T>(
    BuildContext context,
    TapDownDetails details,
  ) {
    return showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        const PopupMenuItem(
          value: FileEntryMenuResult.download,
          child: Text('Download'),
        ),
        const PopupMenuItem(
          value: FileEntryMenuResult.delete,
          child: Text('Delete'),
        ),
      ],
    );
  }
}
