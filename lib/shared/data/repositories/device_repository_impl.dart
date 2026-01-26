import 'dart:async';
import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/data/datasources/shell/shell_datasource.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final Logger logger;
  final ShellDatasource shellDatasource;

  final BehaviorSubject<DeviceEntity?> _selectedDeviceSubject =
      BehaviorSubject<DeviceEntity?>();

  final BehaviorSubject<List<DeviceEntity>> _connectedDevicesSubject =
      BehaviorSubject<List<DeviceEntity>>.seeded(const []);

  DeviceRepositoryImpl(this.logger, this.shellDatasource);

  @override
  Future<void> setSelectedDevice(DeviceEntity device) async {
    _selectedDeviceSubject.add(device);
  }

  @override
  Stream<DeviceEntity?> listenSelectedDevice() => _selectedDeviceSubject.stream;

  @override
  Stream<List<DeviceEntity>> listenConnectedDevice() =>
      _connectedDevicesSubject.stream;

  @override
  Future<void> refreshConnectedDevices() async {
    logger.i("Refreshing connected devices");

    final devices = await _getConnectedDevices();
    _connectedDevicesSubject.add(devices);

    final current = _selectedDeviceSubject.valueOrNull;

    if (devices.isEmpty) {
      _selectedDeviceSubject.add(null);
      return;
    }

    if (current == null || !devices.contains(current)) {
      _selectedDeviceSubject.add(devices.first);
    }
  }

  Future<List<DeviceEntity>> _getConnectedDevices() async {
    final adbPath = shellDatasource.getAdbPath();

    final adbClient = AdbClient(adbExecutablePath: adbPath);
    final connectedDevices = await adbClient.listConnectedDevices();
    return connectedDevices
        .map(
          (c) => DeviceEntity(
            manufacturer: c.manufacturer,
            name: c.name,
            deviceId: c.deviceId,
          ),
        )
        .toList();
  }
}
