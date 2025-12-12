import 'dart:convert';
import 'dart:io';

import 'package:android_tools/features/fileexplorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/fileexplorer/domain/entities/file_type.dart';
import 'package:android_tools/features/fileexplorer/domain/repositories/file_repository.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:logger/logger.dart';

class FileRepositoryImpl implements FileRepository {
  final Logger _logger;
  final ShellDatasource _shellDatasource;

  FileRepositoryImpl(this._logger, this._shellDatasource);

  @override
  Future<List<FileEntry>> listFiles(String path) async {
    final adbPath = _shellDatasource.getAdbPath();

    if (path.isEmpty) {
      path = "/";
    }

    try {
      final process = await Process.start(adbPath, ['shell', 'ls', '-l', path]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final error = await process.stderr.transform(utf8.decoder).join();

      if (error.isNotEmpty) {
        _logger.w('ADB error: $error');
      }

      final lines = output.split('\n').where((line) => line.trim().isNotEmpty);

      return lines.map((line) => _parseLine(line)).toList();
    } catch (e, stack) {
      _logger.e('Failed to list files ${stack.toString()}');
      return [];
    }
  }

  FileEntry _parseLine(String line) {
    final parts = line.split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return FileEntry(
        type: FileType.unknown,
        permissions: '?????????',
        name: line,
      );
    }

    final perm = parts[0];

    final type = perm.startsWith('d')
        ? FileType.directory
        : perm.startsWith('l')
        ? FileType.symlink
        : perm.startsWith('-')
        ? FileType.file
        : FileType.unknown;

    int? parseIntSafe(String s) => int.tryParse(s);

    DateTime? date;
    try {
      if (parts.length >= 7) {
        final dateStr = '${parts[5]} ${parts[6]}';
        date = DateTime.tryParse(dateStr);
      }
    } catch (_) {}

    final nameIndex = line.indexOf(parts.length > 7 ? parts[7] : '');
    String fullName = nameIndex >= 0
        ? line.substring(nameIndex).trim()
        : parts.last;

    String name = fullName;
    String? symlinkTarget;

    if (type == FileType.symlink && fullName.contains('->')) {
      final split = fullName.split('->');
      name = split[0].trim();
      symlinkTarget = split[1].trim();
    }

    return FileEntry(
      type: type,
      permissions: perm,
      links: parts.length > 1 ? parseIntSafe(parts[1]) : null,
      owner: parts.length > 2 ? parts[2] : null,
      group: parts.length > 3 ? parts[3] : null,
      size: parts.length > 4 ? parseIntSafe(parts[4]) : null,
      date: date,
      name: name,
      symlinkTarget: symlinkTarget,
    );
  }
}
