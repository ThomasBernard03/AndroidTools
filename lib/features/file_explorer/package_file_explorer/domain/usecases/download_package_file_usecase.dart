import 'package:android_tools/features/file_explorer/package_file_explorer/domain/repositories/package_file_repository.dart';

class DownloadPackageFileUsecase {
  final PackageFileRepository _packageFileRepository;

  DownloadPackageFileUsecase(this._packageFileRepository);

  Future<void> call(
    String package,
    String filePath,
    String destinationPath,
    String deviceId,
  ) {
    return _packageFileRepository.downloadFile(
      package,
      filePath,
      destinationPath,
      deviceId,
    );
  }
}
