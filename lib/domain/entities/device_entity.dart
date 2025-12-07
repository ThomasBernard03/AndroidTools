import 'package:equatable/equatable.dart';

class DeviceEntity extends Equatable {
  final String manufacturer;
  final String name;
  final String deviceId;

  const DeviceEntity({
    required this.manufacturer,
    required this.name,
    required this.deviceId,
  });

  @override
  List<Object?> get props => [deviceId];
}
