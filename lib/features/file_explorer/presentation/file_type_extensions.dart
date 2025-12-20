import 'package:android_tools/features/file_explorer/domain/entities/file_type.dart';
import 'package:flutter/material.dart';

extension FileTypeExtensions on FileType {
  IconData icon() {
    switch (this) {
      case FileType.file:
        return Icons.format_align_left_rounded;
      case FileType.directory:
        return Icons.folder_outlined;
      case FileType.symlink:
        return Icons.drive_folder_upload_outlined;
      case FileType.unknown:
        return Icons.folder_off;
    }
  }
}
