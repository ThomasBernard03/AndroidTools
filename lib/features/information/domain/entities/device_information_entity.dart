class DeviceInformationEntity {
  final String manufacturer;
  final String model;
  final String version;
  final String serialNumber;
  final int? screenWidth;
  final int? screenHeight;

  final Map<String, String> rawInformation;

  DeviceInformationEntity({
    required this.manufacturer,
    required this.model,
    required this.version,
    required this.serialNumber,
    required this.rawInformation,
    this.screenWidth,
    this.screenHeight,
  });
}
