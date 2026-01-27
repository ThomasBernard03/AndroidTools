import 'dart:io';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DownloadFileToCacheUsecase {
  final FileRepository _fileRepository;

  DownloadFileToCacheUsecase(this._fileRepository);

  Future<String> call(
    String filePath,
    String fileName,
    String deviceId,
  ) async {
    final cacheDir = await getTemporaryDirectory();
    final localFilePath = p.join(cacheDir.path, 'file_preview', fileName);

    // Create directory if it doesn't exist
    final directory = Directory(p.dirname(localFilePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await _fileRepository.downloadFile(filePath, localFilePath, deviceId);

    return localFilePath;
  }
}
