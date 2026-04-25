import 'package:dart_mappable/dart_mappable.dart';

part 'apk_signature.mapper.dart';

/// Represents signature information for an APK
@MappableClass()
class ApkSignature with ApkSignatureMappable {
  /// Signature scheme (e.g., v2, v3, v2 + v3)
  final String scheme;

  /// SHA-256 fingerprint of the certificate
  final String sha256;

  /// Certificate issuer (e.g., CN=Company, O=Organization, C=US)
  final String issuer;

  /// Certificate validity start date
  final String validFrom;

  /// Certificate validity end date
  final String validTo;

  /// Signature algorithm (e.g., SHA256withRSA)
  final String algorithm;

  /// Key size in bits (e.g., 2048)
  final int keySize;

  const ApkSignature({
    required this.scheme,
    required this.sha256,
    required this.issuer,
    required this.validFrom,
    required this.validTo,
    required this.algorithm,
    required this.keySize,
  });
}
