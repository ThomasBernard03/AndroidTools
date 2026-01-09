import 'package:android_tools/features/file_explorer/general_file_explorer/domain/repositories/general_file_repository.dart';

class CreateDirectoryUsecase {
  final GeneralFileRepository _fileRepository;

  CreateDirectoryUsecase(this._fileRepository);

  Future<void> call(String path, String name, String deviceId) {
    return _fileRepository.createDirectory(path, name, deviceId);
  }
}
