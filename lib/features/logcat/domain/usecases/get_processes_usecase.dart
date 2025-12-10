import 'package:android_tools/features/logcat/domain/entities/process_entity.dart';
import 'package:android_tools/features/logcat/domain/repositories/logcat_repository.dart';

class GetProcessesUsecase {
  final LogcatRepository logcatRepository;

  GetProcessesUsecase(this.logcatRepository);

  Future<List<ProcessEntity>> call(String deviceId) {
    return logcatRepository.getProcesses(deviceId);
  }
}
