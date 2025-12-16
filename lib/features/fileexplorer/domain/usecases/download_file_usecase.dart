import 'package:android_tools/features/fileexplorer/domain/repositories/file_repository.dart';

class DownloadFileUsecase {
  final FileRepository _fileRepository;

  DownloadFileUsecase(this._fileRepository);

  Future<void> call(String filePath, String destinationPath, String deviceId) {
    return _fileRepository.downloadFile(filePath, destinationPath, deviceId);
  }
}
