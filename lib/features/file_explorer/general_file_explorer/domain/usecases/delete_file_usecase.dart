import 'package:android_tools/features/file_explorer/general_file_explorer/domain/repositories/general_file_repository.dart';

class DeleteFileUsecase {
  final GeneralFileRepository _fileRepository;

  DeleteFileUsecase(this._fileRepository);

  Future<void> call(String filePath, String deviceId) {
    return _fileRepository.deleteFile(filePath, deviceId);
  }
}
