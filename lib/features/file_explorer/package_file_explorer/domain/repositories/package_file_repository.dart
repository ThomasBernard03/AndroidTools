import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';

abstract class PackageFileRepository {
  Future<List<FileEntry>> listFiles(
    String package,
    String path,
    String deviceId,
  );
  Future<void> deleteFile(String package, String filePath, String deviceId);
  Future<void> createDirectory(
    String package,
    String path,
    String name,
    String deviceId,
  );
  Future<void> downloadFile(
    String package,
    String filePath,
    String destinationPath,
    String deviceId,
  );
  Future<void> uploadFiles(
    String package,
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  );
}
