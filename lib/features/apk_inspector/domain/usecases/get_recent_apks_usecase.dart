import 'package:android_tools/features/apk_inspector/domain/entities/apk_info.dart';
import 'package:android_tools/features/apk_inspector/domain/repositories/recent_apk_repository.dart';

class GetRecentApksUsecase {
  final RecentApkRepository _repository;

  GetRecentApksUsecase(this._repository);

  Future<List<ApkInfo>> call({int limit = 10}) async {
    return _repository.getRecentApks(limit: limit);
  }
}
