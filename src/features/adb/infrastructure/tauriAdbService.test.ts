import { describe, expect, it, vi } from 'vitest';
import { createTauriAdbService } from './tauriAdbService';
import { createDemoAdbService } from './demoAdbService';

describe('ADB IPC boundary', () => {
  it('targets the selected connection and releases the native session', async () => {
    const info = await createDemoAdbService().read('usb:1:2:18d1:4ee7');
    const call = vi
      .fn()
      .mockResolvedValueOnce(info)
      .mockResolvedValueOnce(null);
    const service = createTauriAdbService(call);
    expect(await service.read('selected-id')).toEqual(info);
    expect(call).toHaveBeenNthCalledWith(1, 'read_android_info', {
      connectionId: 'selected-id',
    });
    await service.disconnect();
    expect(call).toHaveBeenNthCalledWith(2, 'disconnect_adb', undefined);
  });

  it.each([undefined, -1, 101, 2.5, '82'])(
    'rejects invalid battery values: %j',
    async (batteryPercent) => {
      const info = await createDemoAdbService().read('usb:1:2:18d1:4ee7');
      await expect(
        createTauriAdbService(async () => ({ ...info, batteryPercent })).read(
          'id',
        ),
      ).rejects.toMatchObject({ code: 'invalid_response' });
    },
  );

  it.each([null, {}, { model: 'Pixel' }])(
    'rejects incomplete Android information: %j',
    async (info) => {
      await expect(
        createTauriAdbService(async () => info).read('id'),
      ).rejects.toMatchObject({ code: 'invalid_response' });
    },
  );

  it('accepts explicitly missing properties and battery information', async () => {
    const info = {
      manufacturer: null,
      model: null,
      androidVersion: null,
      apiLevel: null,
      securityPatch: null,
      buildId: null,
      architecture: null,
      batteryPercent: null,
      batteryStatus: null,
      warning: 'Battery unavailable',
    };
    expect(await createTauriAdbService(async () => info).read('id')).toEqual(
      info,
    );
  });

  it('preserves authorization failures and normalizes unknown failures', async () => {
    await expect(
      createTauriAdbService(async () => {
        throw { code: 'unauthorized', message: 'Allow USB debugging' };
      }).read('id'),
    ).rejects.toMatchObject({
      code: 'unauthorized',
      message: 'Allow USB debugging',
    });
    await expect(
      createTauriAdbService(async () => {
        throw new Error('IPC gone');
      }).disconnect(),
    ).rejects.toMatchObject({ code: 'unavailable' });
  });
});
