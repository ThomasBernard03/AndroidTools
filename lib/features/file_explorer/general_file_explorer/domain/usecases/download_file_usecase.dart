import 'package:android_tools/features/file_explorer/general_file_explorer/domain/repositories/general_file_repository.dart';

class DownloadFileUsecase {
  final GeneralFileRepository _fileRepository;

  DownloadFileUsecase(this._fileRepository);

  Future<void> call(String filePath, String destinationPath, String deviceId) {
    return _fileRepository.downloadFile(filePath, destinationPath, deviceId);
  }
}
