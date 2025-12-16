import 'package:android_tools/features/fileexplorer/domain/entities/file_entry.dart';

abstract class FileRepository {
  Future<List<FileEntry>> listFiles(String path, String deviceId);
  Future<void> uploadFiles(
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  );
}
