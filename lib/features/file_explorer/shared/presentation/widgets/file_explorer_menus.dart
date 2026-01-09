import 'package:android_tools/features/file_explorer/shared/presentation/widgets/file_entry_menu_result.dart';
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
          value: FileEntryMenuResult.refresh,
          child: Row(
            spacing: 8,
            children: [Icon(Icons.refresh_rounded), Text('Refresh')],
          ),
        ),
        const PopupMenuItem(
          value: FileEntryMenuResult.newDirectory,
          child: Row(
            spacing: 8,
            children: [
              Icon(Icons.create_new_folder_outlined),
              Text('New folder'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: FileEntryMenuResult.upload,
          child: Row(
            spacing: 8,
            children: [Icon(Icons.upload_rounded), Text('Upload')],
          ),
        ),
        const PopupMenuItem(
          value: FileEntryMenuResult.download,
          child: Row(
            spacing: 8,
            children: [Icon(Icons.download_rounded), Text('Download')],
          ),
        ),
        PopupMenuItem(
          value: FileEntryMenuResult.delete,
          child: Row(
            spacing: 8,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<FileEntryMenuResult?> showGeneralMenu<T>(
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
          value: FileEntryMenuResult.refresh,
          child: Row(
            spacing: 8,
            children: [Icon(Icons.refresh_rounded), Text('Refresh')],
          ),
        ),
        const PopupMenuItem(
          value: FileEntryMenuResult.newDirectory,
          child: Row(
            spacing: 8,
            children: [
              Icon(Icons.create_new_folder_outlined),
              Text('New folder'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: FileEntryMenuResult.upload,
          child: Row(
            spacing: 8,
            children: [Icon(Icons.upload_rounded), Text('Upload')],
          ),
        ),
      ],
    );
  }
}
