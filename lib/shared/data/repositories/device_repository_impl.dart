import 'dart:async';
import 'package:adb_dart/adb_dart.dart';
import 'package:android_tools/shared/domain/entities/device_entity.dart';
import 'package:android_tools/shared/domain/repositories/device_repository.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final Logger logger;
  final AdbClient adbClient;

  final BehaviorSubject<DeviceEntity?> _selectedDeviceSubject =
      BehaviorSubject<DeviceEntity?>();

  final BehaviorSubject<List<DeviceEntity>> _connectedDevicesSubject =
      BehaviorSubject<List<DeviceEntity>>.seeded(const []);

  Future<List<DeviceEntity>>? _ongoingRefresh;

  DeviceRepositoryImpl(this.logger, this.adbClient);

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
    // If a refresh is already in progress, wait for it to complete
    if (_ongoingRefresh != null) {
      logger.d("Refresh already in progress, waiting for completion");
      await _ongoingRefresh;
      return;
    }

    logger.i("Refreshing connected devices");

    _ongoingRefresh = _getConnectedDevices();
    try {
      final devices = await _ongoingRefresh!;
      _connectedDevicesSubject.add(devices);

      final current = _selectedDeviceSubject.valueOrNull;

      if (devices.isEmpty) {
        _selectedDeviceSubject.add(null);
        return;
      }

      if (current == null || !devices.contains(current)) {
        _selectedDeviceSubject.add(devices.first);
      }
    } finally {
      _ongoingRefresh = null;
    }
  }

  Future<List<DeviceEntity>> _getConnectedDevices() async {
    try {
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
    } catch (e) {
      // Device disconnected while retrieving properties or ADB error occurred
      logger.w("Failed to retrieve connected devices: $e");
      return [];
    }
  }
}
