import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';

class UploadFilesUsecase {
  final FileRepository _fileRepository;

  UploadFilesUsecase(this._fileRepository);

  Future<void> call(String filePath, String destination, String deviceId) {
    return _fileRepository.uploadFiles(filePath, destination, deviceId);
  }
}
