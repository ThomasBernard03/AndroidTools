abstract class PackageRepository {
  Future<Iterable<String>> getAllPackages(String deviceId);
}
