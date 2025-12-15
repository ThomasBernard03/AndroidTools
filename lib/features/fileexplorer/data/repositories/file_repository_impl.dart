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

      final lines = output
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .skip(1)
          .toList();

      return lines.map((line) => _parseLine(line)).toList();
    } catch (e, stack) {
      _logger.e('Failed to list files ${stack.toString()}');
      return [];
    }
  }

  final regex = RegExp(
    r'^(\S+)\s+' // permissions
    r'(\S+)\s+' // links
    r'(\S+)\s+' // owner
    r'(\S+)\s+' // group
    r'(\S+)\s+' // size
    r'(\d{4}-\d{2}-\d{2})\s+' // date
    r'(\d{2}:\d{2})\s+' // time
    r'(.+)$', // name (with spaces + symlink)
  );

  FileEntry _parseLine(String line) {
    final match = regex.firstMatch(line);

    if (match == null) {
      return FileEntry(
        type: line.startsWith('d')
            ? FileType.directory
            : line.startsWith('l')
            ? FileType.symlink
            : FileType.unknown,
        permissions: line.split(' ').first,
        name: line.split(' ').last,
      );
    }

    final perm = match.group(1)!;
    final namePart = match.group(8)!;

    final type = perm.startsWith('d')
        ? FileType.directory
        : perm.startsWith('l')
        ? FileType.symlink
        : FileType.file;

    String name = namePart;
    String? symlinkTarget;

    if (type == FileType.symlink && namePart.contains('->')) {
      final split = namePart.split('->');
      name = split[0].trim();
      symlinkTarget = split[1].trim();
    }

    return FileEntry(
      type: type,
      permissions: perm,
      links: int.tryParse(match.group(2)!),
      owner: match.group(3),
      group: match.group(4),
      size: int.tryParse(match.group(5)!),
      date: DateTime.tryParse('${match.group(6)} ${match.group(7)}'),
      name: name,
      symlinkTarget: symlinkTarget,
    );
  }
}
