import 'package:android_tools/domain/repositories/logcat_repository.dart';

class ListenLogcatUsecase {
  final LogcatRepository logcatRepository;
  const ListenLogcatUsecase({required this.logcatRepository});

  Stream<String> call() {
    return logcatRepository.listenLogcat();
  }
}
