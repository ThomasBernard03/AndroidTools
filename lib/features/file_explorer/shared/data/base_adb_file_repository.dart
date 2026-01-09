import 'dart:convert';
import 'dart:io';

import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_type.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:logger/logger.dart';

abstract class BaseAdbFileRepository {
  final Logger logger;
  final ShellDatasource shell;

  BaseAdbFileRepository(this.logger, this.shell);

  String get adbPath => shell.getAdbPath();

  Future<Process> start(List<String> args) {
    return Process.start(adbPath, args);
  }

  Future<(String stdout, String stderr, int code)> run(
    List<String> args,
  ) async {
    final process = await start(args);
    final stdout = await process.stdout.transform(utf8.decoder).join();
    final stderr = await process.stderr.transform(utf8.decoder).join();
    final code = await process.exitCode;
    return (stdout, stderr, code);
  }

  // Parsing commun
  final _regex = RegExp(
    r'^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+'
    r'(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.+)$',
  );

  FileEntry parseLsLine(String line) {
    final match = _regex.firstMatch(line);

    if (match == null) {
      return FileEntry(
        type: FileType.unknown,
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

  List<FileEntry> parseLsOutput(String output) {
    return output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .skip(1)
        .map(parseLsLine)
        .toList();
  }
}
