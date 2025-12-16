import 'package:android_tools/features/fileexplorer/domain/repositories/file_repository.dart';

class UploadFilesUsecase {
  final FileRepository _fileRepository;

  UploadFilesUsecase(this._fileRepository);

  Future<void> call(
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  ) {
    return _fileRepository.uploadFiles(filesPath, destination, deviceId);
  }
}
