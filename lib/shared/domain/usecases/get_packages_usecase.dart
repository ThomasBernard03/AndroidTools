import 'package:android_tools/shared/domain/repositories/package_repository.dart';

class GetPackagesUsecase {
  final PackageRepository _packageRepository;

  GetPackagesUsecase(this._packageRepository);

  Future<Iterable<String>> call(String deviceId) {
    return _packageRepository.getAllPackages(deviceId);
  }
}
