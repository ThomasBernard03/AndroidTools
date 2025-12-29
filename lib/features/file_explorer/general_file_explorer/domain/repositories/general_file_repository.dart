import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';

abstract class GeneralFileRepository {
  Future<List<FileEntry>> listFiles(String path, String deviceId);
  Future<void> deleteFile(String filePath, String deviceId);
  Future<void> createDirectory(String path, String name, String deviceId);
  Future<void> downloadFile(
    String filePath,
    String destinationPath,
    String deviceId,
  );
  Future<void> uploadFiles(
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  );
}
