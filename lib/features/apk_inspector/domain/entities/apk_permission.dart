import 'package:dart_mappable/dart_mappable.dart';

part 'apk_permission.mapper.dart';

/// Represents a permission requested by an APK
@MappableClass()
class ApkPermission with ApkPermissionMappable {
  /// Permission name (e.g., android.permission.INTERNET)
  final String name;

  /// Permission protection level: dangerous, normal, signature, etc.
  final String level;

  const ApkPermission({
    required this.name,
    required this.level,
  });
}
