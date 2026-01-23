import 'dart:io';

import 'package:android_tools/features/file_explorer/data/base_adb_file_repository.dart';
import 'package:android_tools/features/file_explorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/domain/entities/file_type.dart';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';

class GeneralFileRepositoryImpl extends BaseAdbFileRepository
    implements FileRepository {
  final PackageRepository _packageRepository;

  GeneralFileRepositoryImpl(super.logger, super.shell, this._packageRepository);

  ({String package, String? subPath})? _parsePrivateAppPath(String path) {
    if (!path.startsWith('/data/data/')) return null;

    final parts = path.split('/');
    if (parts.length < 4) return null;

    final package = parts[3];
    final subPath = parts.length > 4 ? parts.sublist(4).join('/') : null;

    return (package: package, subPath: subPath);
  }

  @override
  Future<List<FileEntry>> listFiles(String path, String deviceId) async {
    if (path == '/data') {
      return [
        FileEntry(
          type: FileType.directory,
          name: 'data',
          permissions: 'drwx--x--x',
        ),
      ];
    }

    if (path == '/data/data') {
      final packages = await _packageRepository.getAllPackages(deviceId);
      return packages
          .map(
            (pkg) => FileEntry(
              type: FileType.directory,
              name: pkg,
              permissions: 'drwx------',
            ),
          )
          .toList();
    }

    if (path.startsWith('/data/data/')) {
      final parts = path.split('/');

      // /data/data/<package>/...
      if (parts.length < 4) {
        return [];
      }

      final package = parts[3];
      final subPath = parts.length > 4 ? parts.sublist(4).join('/') : '';

      final command = ['-s', deviceId, 'shell', 'run-as', package, 'ls', '-l'];

      if (subPath.isNotEmpty) {
        command.add(subPath);
      }

      final (out, err, code) = await run(command);

      return code == 0 ? parseLsOutput(out) : [];
    }

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

    final privatePath = _parsePrivateAppPath(filePath);

    if (privatePath != null) {
      final target = privatePath.subPath ?? '.';

      final (_, err, code) = await run([
        '-s',
        deviceId,
        'shell',
        'run-as',
        privatePath.package,
        'rm',
        '-rf',
        target,
      ]);

      if (code != 0) {
        logger.e("Delete failed (private)\n$err");
      }
      return;
    }

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
    final privatePath = _parsePrivateAppPath(fullPath);

    if (privatePath != null) {
      final target = privatePath.subPath ?? name;

      final (_, err, code) = await run([
        '-s',
        deviceId,
        'shell',
        'run-as',
        privatePath.package,
        'mkdir',
        '-p',
        target,
      ]);

      if (code != 0) {
        logger.e("mkdir failed (private)\n$err");
      }
      return;
    }

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

    final privatePath = _parsePrivateAppPath(filePath);

    if (privatePath != null) {
      final localFile = File(destinationPath);
      await localFile.parent.create(recursive: true);

      final process = await start([
        '-s',
        deviceId,
        'exec-out',
        'run-as',
        privatePath.package,
        'cat',
        filePath,
      ]);

      final sink = localFile.openWrite();
      await process.stdout.pipe(sink);
      await sink.close();

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        logger.e('Download failed (exec-out)');
      }
      return;
    }

    // fallback classique
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
    final privatePath = _parsePrivateAppPath(destination);

    for (final path in filesPath) {
      final file = File(path);
      if (!await file.exists()) continue;

      if (privatePath != null) {
        final fileName = file.uri.pathSegments.last;
        final tmpPath = '/sdcard/$fileName';

        await run(['-s', deviceId, 'push', path, tmpPath]);

        final target = privatePath.subPath != null
            ? '${privatePath.subPath}/$fileName'
            : fileName;

        final (_, err, code) = await run([
          '-s',
          deviceId,
          'shell',
          'run-as',
          privatePath.package,
          'cp',
          tmpPath,
          target,
        ]);

        await run(['-s', deviceId, 'shell', 'rm', tmpPath]);

        if (code != 0) {
          logger.e("Upload failed (private)\n$err");
        }
        continue;
      }

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
