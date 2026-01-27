import 'package:adb_dart/adb_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

extension FileEntryExtensions on FileEntry {
  Widget icon() {
    switch (type) {
      case FileType.directory:
        return SvgPicture.asset(
          "assets/images/folder/red_folder.svg",
          width: 30,
        );
      case FileType.symlink:
        return Icon(Icons.drive_folder_upload_outlined);
      case FileType.unknown:
        return Icon(Icons.folder_off);
      case FileType.file:
        return _buildFileIcon(name);
    }
  }

  Widget _buildFileIcon(String name) {
    final lowerName = name.toLowerCase();

    final assetName = switch (lowerName) {
      _ when RegExp(r'\.log(\.\d+)?$').hasMatch(lowerName) => 'log.svg',
      _ when RegExp(r'\.(png|jpe?g|gif|webp)$').hasMatch(lowerName) =>
        'image.svg',
      _ when lowerName.endsWith('.svg') => 'svg.svg',
      _ when RegExp(r'\.(db|sqlite)$').hasMatch(lowerName) => 'database.svg',
      _ when lowerName.endsWith('.json') => 'json.svg',
      _ when lowerName.endsWith('.xml') => 'xml.svg',
      _ when RegExp(r'\.(mp4|mov|avi|mkv)$').hasMatch(lowerName) => 'video.svg',
      _ => 'document.svg',
    };

    return Stack(
      alignment: AlignmentGeometry.center,
      children: [
        SvgPicture.asset("assets/images/file/file_dark.svg", width: 30),
        SvgPicture.asset("assets/images/file_extensions/$assetName", width: 14),
      ],
    );
  }
}
