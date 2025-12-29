import 'dart:io';

import 'package:android_tools/features/file_explorer/shared/data/base_adb_file_repository.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/repositories/general_file_repository.dart';

class GeneralFileRepositoryImpl extends BaseAdbFileRepository
    implements GeneralFileRepository {
  GeneralFileRepositoryImpl(super.logger, super.shell);

  @override
  Future<List<FileEntry>> listFiles(String path, String deviceId) async {
    final target = path.isEmpty ? '/' : path;

    final (out, err, code) = await run([
      '-s',
      deviceId,
      'shell',
      'ls',
      '-l',
      target,
    ]);

    if (err.isNotEmpty) {
      logger.w(err.trim());
    }

    return code == 0 ? parseLsOutput(out) : [];
  }

  @override
  Future<void> deleteFile(String filePath, String deviceId) async {
    if (filePath.isEmpty) return;

    final escaped = filePath.replaceAll("'", r"'\''");

    final (_, err, code) = await run([
      '-s',
      deviceId,
      'shell',
      'rm',
      '-rf',
      "'$escaped'",
    ]);

    if (code != 0) {
      logger.e("Delete failed\n$err");
    }
  }

  @override
  Future<void> createDirectory(
    String path,
    String name,
    String deviceId,
  ) async {
    if (path.isEmpty || name.isEmpty) return;

    final fullPath = path.endsWith('/') ? '$path$name' : '$path/$name';
    final escaped = fullPath.replaceAll("'", r"'\''");

    final (_, err, code) = await run([
      '-s',
      deviceId,
      'shell',
      'mkdir',
      '-p',
      "'$escaped'",
    ]);

    if (code != 0) {
      logger.e("mkdir failed\n$err");
    }
  }

  @override
  Future<void> downloadFile(
    String filePath,
    String destinationPath,
    String deviceId,
  ) async {
    if (filePath.isEmpty || destinationPath.isEmpty) return;

    final (_, err, code) = await run([
      '-s',
      deviceId,
      'pull',
      filePath,
      destinationPath,
    ]);

    if (code != 0) {
      logger.e("Download failed\n$err");
    }
  }

  @override
  Future<void> uploadFiles(
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  ) async {
    for (final path in filesPath) {
      final file = File(path);
      if (!await file.exists()) continue;

      final (_, err, code) = await run([
        '-s',
        deviceId,
        'push',
        path,
        destination,
      ]);

      if (code != 0) {
        logger.e("Upload failed\n$err");
      }
    }
  }
}
