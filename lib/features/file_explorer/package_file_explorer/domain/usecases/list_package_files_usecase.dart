import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';
import 'package:android_tools/features/file_explorer/shared/domain/entities/file_entry.dart';

class ListPackageFilesUsecase {
  final PackageFileRepository _packageFileRepository;

  ListPackageFilesUsecase(this._packageFileRepository);

  Future<Iterable<FileEntry>> call(
    String package,
    String path,
    String deviceId,
  ) {
    return _packageFileRepository.listFiles(package, path, deviceId);
  }
}
