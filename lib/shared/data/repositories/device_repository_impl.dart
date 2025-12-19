import 'dart:async';
import 'dart:io';

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
    try {
      logger.i("Searching connected devices");

      final process = await Process.run(adbPath, ['devices', '-l']);

      if (process.exitCode != 0) {
        logger.w("Error fetching devices: ${process.stderr}");
        return [];
      }

      final output = process.stdout as String;
      final lines = output.split('\n');

      final devices = <DeviceEntity>[];

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('List of devices')) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2 || parts[1] != 'device') continue;

        String manufacturer = "Unknown";
        String deviceId = parts[0];
        String name = deviceId;

        for (var part in parts.skip(2)) {
          if (part.startsWith('model:')) {
            name = part.replaceFirst('model:', '');
          } else if (part.startsWith('manufacturer:')) {
            manufacturer = part.replaceFirst('manufacturer:', '');
          }
        }

        devices.add(
          DeviceEntity(
            manufacturer: manufacturer,
            name: name,
            deviceId: deviceId,
          ),
        );
      }

      logger.i("Found ${devices.length} devices");
      return devices;
    } catch (e) {
      logger.w("Exception while fetching devices: $e");
      return [];
    }
  }
}
