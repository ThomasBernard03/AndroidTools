import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';

class UploadPackageFilesUsecase {
  final PackageFileRepository _packageFileRepository;

  UploadPackageFilesUsecase(this._packageFileRepository);

  Future<void> call(
    String package,
    Iterable<String> filesPath,
    String destination,
    String deviceId,
  ) {
    return _packageFileRepository.uploadFiles(
      package,
      filesPath,
      destination,
      deviceId,
    );
  }
}
