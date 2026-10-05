import { effectScope, nextTick, shallowRef } from 'vue';
import { flushPromises } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import { AdbError, type AndroidInfo } from '../domain/adb';
import { createDemoAdbService } from '../infrastructure/demoAdbService';
import { createDemoDeviceService } from '../../devices/infrastructure/demoDeviceService';
import type { DeviceSummary } from '../../devices/domain/devices';
import { useAdb } from './useAdb';

describe('ADB session lifecycle', () => {
  it('discards old-device results and serializes switching and disconnecting', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const info = await createDemoAdbService().read(devices[0]!.id);
    let resolve!: (info: AndroidInfo) => void;
    const pending = new Promise<AndroidInfo>((done) => {
      resolve = done;
    });
    const read = vi
      .fn()
      .mockReturnValueOnce(pending)
      .mockResolvedValueOnce({ ...info, model: 'Second phone' });
    const disconnect = vi.fn().mockResolvedValue(undefined);
    const selected = shallowRef<DeviceSummary | null>(devices[0]!);
    const scope = effectScope();
    const adb = scope.run(() => useAdb(selected, { read, disconnect }))!;
    try {
      await flushPromises();
      expect(adb.state.value.status).toBe('connecting');
      selected.value = devices[1]!;
      await nextTick();
      expect(read).toHaveBeenCalledTimes(1);
      resolve(info);
      await flushPromises();
      expect(read).toHaveBeenLastCalledWith(devices[1]!.id);
      expect(adb.state.value.info?.model).toBe('Second phone');
      selected.value = null;
      await flushPromises();
      expect(adb.state.value).toEqual({
        status: 'idle',
        info: null,
        error: null,
      });
      expect(disconnect).toHaveBeenCalledTimes(1);
    } finally {
      scope.stop();
    }
  });

  it('supports authorization retry and removes stale information on failure', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const info = await createDemoAdbService().read(devices[0]!.id);
    const service = {
      read: vi
        .fn()
        .mockRejectedValueOnce(new AdbError('unauthorized', 'Allow debugging'))
        .mockResolvedValueOnce(info)
        .mockRejectedValueOnce(
          new AdbError('disconnected', 'Phone disconnected'),
        ),
      disconnect: vi.fn().mockResolvedValue(undefined),
    };
    const scope = effectScope();
    const adb = scope.run(() => useAdb(shallowRef(devices[0]!), service))!;
    try {
      await flushPromises();
      expect(adb.state.value.status).toBe('unauthorized');
      await adb.refresh();
      expect(adb.state.value.status).toBe('connected');
      expect(adb.state.value.info).toEqual(info);
      await adb.refresh();
      expect(adb.state.value).toEqual({
        status: 'disconnected',
        info: null,
        error: 'Phone disconnected',
      });
    } finally {
      scope.stop();
    }
  });

  it('releases an in-flight session after disposal without publishing its result', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const info = await createDemoAdbService().read(devices[0]!.id);
    let resolve!: (info: AndroidInfo) => void;
    const read = vi.fn(
      () =>
        new Promise<AndroidInfo>((done) => {
          resolve = done;
        }),
    );
    const disconnect = vi.fn().mockResolvedValue(undefined);
    const scope = effectScope();
    const adb = scope.run(() =>
      useAdb(shallowRef(devices[0]!), { read, disconnect }),
    )!;
    await flushPromises();
    scope.stop();
    resolve(info);
    await flushPromises();
    expect(adb.state.value.info).toBeNull();
    expect(disconnect).toHaveBeenCalledTimes(1);
  });
});
