import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';

class DeleteFileUsecase {
  final FileRepository _fileRepository;

  DeleteFileUsecase(this._fileRepository);

  Future<void> call(String filePath, String deviceId) {
    return _fileRepository.deleteFile(filePath, deviceId);
  }
}
