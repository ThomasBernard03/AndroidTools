import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';

class CreatePackageDirectoryUsecase {
  final PackageFileRepository _packageFileRepository;

  CreatePackageDirectoryUsecase(this._packageFileRepository);

  Future<void> call(String package, String path, String name, String deviceId) {
    return _packageFileRepository.createDirectory(
      package,
      path,
      name,
      deviceId,
    );
  }
}
