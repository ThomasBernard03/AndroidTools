import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/features/file_explorer/domain/repositories/file_repository.dart';

class ListFilesUsecase {
  final FileRepository _fileRepository;

  ListFilesUsecase(this._fileRepository);

  Future<Iterable<FileEntry>> call(String path, String deviceId) {
    return _fileRepository.listFiles(path, deviceId);
  }
}
