import 'package:android_tools/features/file_explorer/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';

class ListFilesUsecase {
  final FileRepository _fileRepository;

  ListFilesUsecase(this._fileRepository);

  Future<List<FileEntry>> call(String path, String deviceId) {
    return _fileRepository.listFiles(path, deviceId);
  }
}
