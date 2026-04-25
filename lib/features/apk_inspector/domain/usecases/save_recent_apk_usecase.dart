import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/domain/repositories/recent_apk_repository.dart';

class SaveRecentApkUsecase {
  final RecentApkRepository _repository;

  SaveRecentApkUsecase(this._repository);

  Future<void> call(ApkInfo apkInfo) async {
    return _repository.saveRecentApk(apkInfo);
  }
}
