import 'package:android_tools/shared/domain/repositories/application_repository.dart';

class InstallApplicationUsecase {
  final ApplicationRepository _applicationRepository;
  InstallApplicationUsecase(this._applicationRepository);
  Future<void> call(String apkPath, String deviceId) {
    return _applicationRepository.intallApplication(apkPath, deviceId);
  }
}
