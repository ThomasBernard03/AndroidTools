abstract class LogcatRepository {
  Stream<String> listenLogcat();
  Future<void> clearLogcat();
}
