import { describe, expect, it, vi } from 'vitest';
import { createTauriDeviceService } from './tauriDeviceService';
import { createDemoDeviceService } from './demoDeviceService';

describe('Device IPC boundary', () => {
  it('invokes the device command and accepts the serialized device contract', async () => {
    const devices = await createDemoDeviceService('devices').list();
    const invoke = vi.fn().mockResolvedValue(devices);
    expect(await createTauriDeviceService(invoke).list()).toEqual(devices);
    expect(invoke).toHaveBeenCalledWith('list_devices');
  });

  it.each([
    null,
    {},
    [{}],
    [{ id: 'usb:1', name: 'Pixel' }],
    [
      { id: 'usb:1', name: 'Pixel', serial: null, warning: null },
      { id: 'usb:1', name: 'Pixel', serial: null, warning: null },
    ],
  ])(
    'rejects malformed or ambiguous device responses: %j',
    async (response) => {
      await expect(
        createTauriDeviceService(async () => response).list(),
      ).rejects.toMatchObject({ code: 'invalid_response' });
    },
  );

  it('preserves structured native failures', async () => {
    await expect(
      createTauriDeviceService(async () => {
        throw { code: 'usb_unavailable', message: 'USB denied' };
      }).list(),
    ).rejects.toMatchObject({ code: 'usb_unavailable', message: 'USB denied' });
  });

  it.each([
    { manufacturer: 42 },
    { product: undefined },
    { vendorId: -1 },
    { vendorId: 65536 },
    { productId: 1.5 },
    { productId: '4ee7' },
  ])('rejects invalid USB metadata: %j', async (metadata) => {
    const devices = await createDemoDeviceService('devices').list();
    await expect(
      createTauriDeviceService(async () => [
        { ...devices[0], ...metadata },
      ]).list(),
    ).rejects.toMatchObject({ code: 'invalid_response' });
  });

  it('rejects duplicate connections with otherwise valid metadata', async () => {
    const devices = await createDemoDeviceService('devices').list();
    await expect(
      createTauriDeviceService(async () => [devices[0], devices[0]]).list(),
    ).rejects.toMatchObject({ code: 'invalid_response' });
  });

  it('normalizes unexpected transport failures without introducing fake data', async () => {
    await expect(
      createTauriDeviceService(async () => {
        throw new Error('IPC gone');
      }).list(),
    ).rejects.toMatchObject({ code: 'unavailable' });
  });

  it('provides reproducible empty and error demo scenarios', async () => {
    expect(await createDemoDeviceService('empty').list()).toEqual([]);
    await expect(createDemoDeviceService('error').list()).rejects.toMatchObject(
      { code: 'usb_unavailable' },
    );
  });
});
