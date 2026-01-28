import 'package:android_tools/shared/domain/entities/installed_application_history_entity.dart';
import 'package:android_tools/shared/domain/repositories/application_repository.dart';

class ListenInstalledApplicationHistoryUsecase {
  final ApplicationRepository _applicationRepository;

  ListenInstalledApplicationHistoryUsecase(this._applicationRepository);

  Stream<List<InstalledApplicationHistoryEntity>> call() {
    return _applicationRepository.watchInstalledApplicationHistory();
  }
}
