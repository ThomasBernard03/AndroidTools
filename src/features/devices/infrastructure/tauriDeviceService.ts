import { invoke } from '@tauri-apps/api/core';
import {
  DeviceDiscoveryError,
  type DeviceService,
  type DeviceSummary,
} from '../domain/devices';

type Invoke = (command: string) => Promise<unknown>;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function isUsbId(value: unknown): value is number {
  return (
    typeof value === 'number' &&
    Number.isInteger(value) &&
    value >= 0 &&
    value <= 0xffff
  );
}

function isDevice(value: unknown): value is DeviceSummary {
  return (
    isRecord(value) &&
    typeof value.id === 'string' &&
    value.id.length > 0 &&
    typeof value.name === 'string' &&
    value.name.length > 0 &&
    (value.serial === null || typeof value.serial === 'string') &&
    (value.manufacturer === null || typeof value.manufacturer === 'string') &&
    (value.product === null || typeof value.product === 'string') &&
    isUsbId(value.vendorId) &&
    isUsbId(value.productId) &&
    (value.warning === null || typeof value.warning === 'string')
  );
}

/** Validate IPC at runtime instead of trusting an unchecked invoke<T> cast. */
export function createTauriDeviceService(call: Invoke = invoke): DeviceService {
  return {
    async list() {
      let result: unknown;
      try {
        result = await call('list_devices');
      } catch (error) {
        if (
          isRecord(error) &&
          typeof error.code === 'string' &&
          typeof error.message === 'string'
        ) {
          throw new DeviceDiscoveryError(error.code, error.message);
        }
        throw new DeviceDiscoveryError(
          'unavailable',
          'Device discovery is unavailable. Please retry.',
        );
      }
      if (
        !Array.isArray(result) ||
        !result.every(isDevice) ||
        new Set(result.map((device) => device.id)).size !== result.length
      ) {
        throw new DeviceDiscoveryError(
          'invalid_response',
          'The device list returned an invalid response. Please retry.',
        );
      }
      return result;
    },
  };
}
