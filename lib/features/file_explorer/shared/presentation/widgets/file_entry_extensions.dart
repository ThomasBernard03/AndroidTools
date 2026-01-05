import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_type.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

extension FileEntryExtensions on FileEntry {
  Widget icon() {
    switch (type) {
      case FileType.directory:
        return Icon(Icons.folder_outlined);
      case FileType.symlink:
        return Icon(Icons.drive_folder_upload_outlined);
      case FileType.unknown:
        return Icon(Icons.folder_off);
      case FileType.file:
        return FileIcon(name);
    }
  }
}
