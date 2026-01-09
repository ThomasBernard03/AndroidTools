class DeviceInformationEntity {
  final String manufacturer;
  final String model;
  final String version;
  final String serialNumber;

  final Map<String, String> rawInformation;

  DeviceInformationEntity({
    required this.manufacturer,
    required this.model,
    required this.version,
    required this.serialNumber,
    required this.rawInformation,
  });
}
