import 'dart:convert';
import 'dart:io';

import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';
import 'package:android_tools/features/file_explorer/shared/data/base_adb_file_repository.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';

class PackageFileRepositoryImpl extends BaseAdbFileRepository
    implements PackageFileRepository {
  PackageFileRepositoryImpl(super.logger, super.shell);

  String _root(String package) => '/data/data/$package';

  List<String> _runAs(String deviceId, String package, List<String> command) =>
      ['-s', deviceId, 'shell', 'run-as', package, ...command];

  @override
  Future<List<FileEntry>> listFiles(
    String package,
    String path,
    String deviceId,
  ) async {
    final target = path.isEmpty ? _root(package) : path;

    final (out, err, code) = await run(
      _runAs(deviceId, package, ['ls', '-l', target]),
    );

    if (err.isNotEmpty) {
      logger.w(err.trim());
    }

    return code == 0 ? parseLsOutput(out) : [];
  }

  @override
  Future<void> deleteFile(
    String package,
    String filePath,
    String deviceId,
  ) async {
    final (_, err, code) = await run(
      _runAs(deviceId, package, ['rm', '-rf', filePath]),
    );

    if (code != 0) {
      logger.e("Delete failed\n$err");
    }
  }

  @override
  Future<void> createDirectory(
    String package,
    String path,
    String name,
    String deviceId,
  ) async {
    final fullPath = path.endsWith('/') ? '$path$name' : '$path/$name';

    final (_, err, code) = await run(
      _runAs(deviceId, package, ['mkdir', '-p', fullPath]),
    );

    if (code != 0) {
      logger.e("mkdir failed\n$err");
    }
  }

  @override
  Future<void> downloadFile(
    String package,
    String filePath,
    String destinationPath,
    String deviceId,
  ) async {
    final process = await start([
      '-s',
      deviceId,
      'exec-out',
      'run-as',
      package,
      'cat',
      filePath,
    ]);

    final file = File(destinationPath)..createSync(recursive: true);
    await process.stdout.pipe(file.openWrite());

    final err = await process.stderr.transform(utf8.decoder).join();
    final code = await process.exitCode;

    if (code != 0) {
      logger.e("Download failed\n$err");
    }
  }

  @override
  Future<void> uploadFiles(
    String package,
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  ) async {
    for (final path in filesPath) {
      final file = File(path);
      if (!await file.exists()) continue;

      final process = await start([
        '-s',
        deviceId,
        'exec-in',
        'run-as',
        package,
        'sh',
        '-c',
        'cat > $destination/${file.uri.pathSegments.last}',
      ]);

      await file.openRead().pipe(process.stdin);
      await process.stdin.close();

      final err = await process.stderr.transform(utf8.decoder).join();
      final code = await process.exitCode;

      if (code != 0) {
        logger.e("Upload failed\n$err");
      }
    }
  }
}
