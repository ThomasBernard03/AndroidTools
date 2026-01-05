import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';

class DeletePackageFileUsecase {
  final PackageFileRepository _packageFileRepository;

  DeletePackageFileUsecase(this._packageFileRepository);

  Future<void> call(String package, String filePath, String deviceId) {
    return _packageFileRepository.deleteFile(package, filePath, deviceId);
  }
}
