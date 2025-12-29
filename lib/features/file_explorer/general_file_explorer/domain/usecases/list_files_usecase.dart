import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';
import 'package:android_tools/features/file_explorer/general_file_explorer/domain/repositories/general_file_repository.dart';

class ListFilesUsecase {
  final GeneralFileRepository _fileRepository;

  ListFilesUsecase(this._fileRepository);

  Future<List<FileEntry>> call(String path, String deviceId) {
    return _fileRepository.listFiles(path, deviceId);
  }
}
