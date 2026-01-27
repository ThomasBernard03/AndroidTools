import 'package:android_tools/features/file_explorer/domain/entities/file_entry.dart';

abstract class FileRepository {
  Future<Iterable<FileEntry>> listFiles(String path, String deviceId);
  Future<void> deleteFile(String filePath, String deviceId);
  Future<void> createDirectory(String path, String name, String deviceId);
  Future<void> downloadFile(
    String filePath,
    String destinationPath,
    String deviceId,
  );
  Future<void> uploadFiles(
    String filePath,
    String destination,
    String deviceId,
  );
}
