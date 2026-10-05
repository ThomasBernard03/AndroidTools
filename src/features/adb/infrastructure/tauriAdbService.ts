import { invoke } from '@tauri-apps/api/core';
import { AdbError, type AdbService, type AndroidInfo } from '../domain/adb';

type Invoke = (
  command: string,
  args?: Record<string, unknown>,
) => Promise<unknown>;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function isInfo(value: unknown): value is AndroidInfo {
  return (
    isRecord(value) &&
    [
      'manufacturer',
      'model',
      'androidVersion',
      'apiLevel',
      'securityPatch',
      'buildId',
      'architecture',
      'batteryStatus',
      'warning',
    ].every((key) => value[key] === null || typeof value[key] === 'string') &&
    (value.batteryPercent === null ||
      (typeof value.batteryPercent === 'number' &&
        Number.isInteger(value.batteryPercent) &&
        value.batteryPercent >= 0 &&
        value.batteryPercent <= 100))
  );
}

export function createTauriAdbService(call: Invoke = invoke): AdbService {
  async function request(command: string, args?: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        isRecord(error) &&
        typeof error.code === 'string' &&
        typeof error.message === 'string'
      ) {
        throw new AdbError(error.code, error.message);
      }
      throw new AdbError(
        'unavailable',
        'ADB communication is unavailable. Please retry.',
      );
    }
  }
  return {
    async read(connectionId) {
      const info = await request('read_android_info', { connectionId });
      if (!isInfo(info))
        throw new AdbError(
          'invalid_response',
          'Android information returned an invalid response. Please retry.',
        );
      return info;
    },
    async disconnect() {
      await request('disconnect_adb');
    },
  };
}
