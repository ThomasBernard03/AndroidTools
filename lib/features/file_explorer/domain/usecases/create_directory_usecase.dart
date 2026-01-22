import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';

class CreateDirectoryUsecase {
  final FileRepository _fileRepository;

  CreateDirectoryUsecase(this._fileRepository);

  Future<void> call(String path, String name, String deviceId) {
    return _fileRepository.createDirectory(path, name, deviceId);
  }
}
