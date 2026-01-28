import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';
import 'package:android_tools/shared/domain/repositories/package_repository.dart';

class GeneralFileRepositoryImpl implements FileRepository {
  final PackageRepository _packageRepository;
  final AdbClient _adbClient;

  GeneralFileRepositoryImpl(this._packageRepository, this._adbClient);

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
    if (path == 'data') {
      return [
        FileEntry(
          type: FileType.directory,
          name: 'data',
          permissions: 'drwx--x--x',
          date: DateTime(1970),
          size: 4096,
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
              date: DateTime(1970),
              size: 4096,
            ),
          )
          .toList();
    }

    if (path.startsWith('data/data/')) {
      final result = _parsePrivateAppPath(path);
      if (result == null) {
        return [];
      }

      final filesResult = await _adbClient.listFiles(
        result.subPath ?? "",
        deviceId,
        packageName: result.package,
      );

      return filesResult;
    }

    final result = await _adbClient.listFiles(path, deviceId);
    return result;
  }

  @override
  Future<void> deleteFile(String filePath, String deviceId) async {
    if (filePath.isEmpty) return;
    if (filePath.startsWith('data/data/')) {
      final result = _parsePrivateAppPath(filePath);
      if (result == null) return;

      await _adbClient.deleteFile(
        result.subPath ?? "",
        deviceId,
        packageName: result.package,
      );
      return;
    }

    await _adbClient.deleteFile(filePath, deviceId);
  }

  @override
  Future<void> createDirectory(
    String path,
    String name,
    String deviceId,
  ) async {
    if (path.isEmpty || name.isEmpty) return;

    if (path.startsWith('data/data/')) {
      final result = _parsePrivateAppPath(path);
      if (result == null) return;

      await _adbClient.createDirectory(
        result.subPath ?? "",
        name,
        deviceId,
        packageName: result.package,
      );
      return;
    }

    await _adbClient.createDirectory(path, name, deviceId);
  }

  @override
  Future<void> downloadFile(
    String filePath,
    String destinationPath,
    String deviceId,
  ) async {
    if (filePath.isEmpty || destinationPath.isEmpty) return;

    if (filePath.startsWith('data/data/')) {
      final result = _parsePrivateAppPath(filePath);
      if (result == null) return;

      await _adbClient.downloadFile(
        result.subPath ?? "",
        destinationPath,
        deviceId,
        packageName: result.package,
      );
      return;
    }

    await _adbClient.downloadFile(filePath, destinationPath, deviceId);
  }

  @override
  Future<void> uploadFiles(
    String filePath,
    String destination,
    String deviceId,
  ) async {
    if (filePath.isEmpty || destination.isEmpty) return;

    if (destination.startsWith('data/data/')) {
      final result = _parsePrivateAppPath(destination);
      if (result == null) return;

      await _adbClient.uploadFile(
        filePath,
        result.subPath ?? "",
        deviceId,
        packageName: result.package,
      );
      return;
    }

    await _adbClient.uploadFile(filePath, destination, deviceId);
  }
}
