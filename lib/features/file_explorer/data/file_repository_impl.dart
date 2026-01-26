import 'package:adb_dart/adb_dart.dart' hide FileEntry;
import 'package:android_tools/features/file_explorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';

class GeneralFileRepositoryImpl implements FileRepository {
  final PackageRepository _packageRepository;
  final ShellDatasource _shellDatasource;

  GeneralFileRepositoryImpl(this._packageRepository, this._shellDatasource);

  ({String package, String? subPath})? _parsePrivateAppPath(String path) {
    if (!path.startsWith('data/data/')) return null;

    final parts = path.split('/');
    if (parts.length < 3) return null;

    final package = parts[2];
    final subPath = parts.length > 3 ? parts.sublist(3).join('/') : null;

    return (package: package, subPath: subPath);
  }

  @override
  Future<Iterable<FileEntry>> listFiles(String path, String deviceId) async {
    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );

    if (path == 'data') {
      return [
        FileEntry(
          type: FileType.directory,
          name: 'data',
          permissions: 'drwx--x--x',
        ),
      ];
    }

    if (path == 'data/data') {
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

    if (path.startsWith('data/data/')) {
      final result = _parsePrivateAppPath(path);
      if (result == null) {
        return [];
      }

      final filesResult = await adbClient.listFiles(
        result.subPath ?? "",
        deviceId,
        packageName: result.package,
      );

      return filesResult.map(
        (x) =>
            FileEntry(type: x.type, permissions: x.permissions, name: x.name),
      );
    }

    final result = await adbClient.listFiles(path, deviceId);

    return result.map(
      (x) => FileEntry(type: x.type, permissions: x.permissions, name: x.name),
    );
  }

  @override
  Future<void> deleteFile(String filePath, String deviceId) async {
    if (filePath.isEmpty) return;

    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    await adbClient.deleteFile(filePath, deviceId);
  }

  @override
  Future<void> createDirectory(
    String path,
    String name,
    String deviceId,
  ) async {
    if (path.isEmpty || name.isEmpty) return;

    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    await adbClient.createDirectory(path, name, deviceId);
  }

  @override
  Future<void> downloadFile(
    String filePath,
    String destinationPath,
    String deviceId,
  ) async {
    if (filePath.isEmpty || destinationPath.isEmpty) return;

    final adbClient = AdbClient(
      adbExecutablePath: _shellDatasource.getAdbPath(),
    );
    adbClient.downloadFile(filePath, destinationPath, deviceId);
  }

  @override
  Future<void> uploadFiles(
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  ) async {}
}
