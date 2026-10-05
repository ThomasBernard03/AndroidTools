import { effectScope } from 'vue';
import { describe, expect, it, vi } from 'vitest';
import type { DeviceSummary } from '../domain/devices';
import { useDevices } from './useDevices';

function deferred() {
  let resolve!: (devices: DeviceSummary[]) => void;
  let reject!: (cause: unknown) => void;
  const promise = new Promise<DeviceSummary[]>((done, fail) => {
    resolve = done;
    reject = fail;
  });
  return { promise, resolve, reject };
}

describe('Device request lifecycle', () => {
  it('ignores an older failure after a newer refresh succeeds', async () => {
    const first = deferred();
    const second = deferred();
    const scope = effectScope();
    const state = scope.run(() =>
      useDevices({
        list: vi
          .fn()
          .mockReturnValueOnce(first.promise)
          .mockReturnValueOnce(second.promise),
      }),
    )!;
    try {
      const oldRequest = state.refresh();
      const newRequest = state.refresh();
      const device = {
        id: 'usb:1',
        name: 'Pixel',
        serial: null,
        manufacturer: null,
        product: null,
        vendorId: 0x18d1,
        productId: 0x4ee7,
        warning: null,
      };
      second.resolve([device]);
      await newRequest;
      state.select(device.id);
      first.reject(new Error('Stale failure'));
      await oldRequest;
      expect(state.selectedDevice.value).toEqual(device);
      expect(state.error.value).toBeNull();
      expect(state.loading.value).toBe(false);
      state.select('unknown');
      expect(state.selectedDevice.value).toBeNull();
    } finally {
      scope.stop();
    }
  });

  it('ignores discovery results after the owning scope is disposed', async () => {
    const pending = deferred();
    const scope = effectScope();
    const state = scope.run(() => useDevices({ list: () => pending.promise }))!;
    const request = state.refresh();
    scope.stop();
    pending.resolve([
      {
        id: 'usb:1',
        name: 'Pixel',
        serial: null,
        warning: null,
        manufacturer: null,
        product: null,
        vendorId: 0x18d1,
        productId: 0x4ee7,
      },
    ]);
    await request;
    expect(state.devices.value).toEqual([]);
  });
});
