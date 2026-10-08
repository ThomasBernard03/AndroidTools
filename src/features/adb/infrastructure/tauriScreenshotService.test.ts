import { describe, expect, it, vi } from 'vitest';
import { createTauriScreenshotService } from './tauriScreenshotService';

describe('Screen capture IPC', () => {
  it('sends the displayed snapshot and distinguishes saved, cancelled and invalid responses', async () => {
    const call = vi
      .fn()
      .mockResolvedValueOnce(true)
      .mockResolvedValueOnce(false)
      .mockResolvedValueOnce('saved');
    const service = createTauriScreenshotService(call);
    await expect(service.save('displayed-image', 'usb:2')).resolves.toBe(true);
    expect(call).toHaveBeenCalledWith('save_device_screen', {
      image: 'displayed-image',
      connectionId: 'usb:2',
    });
    await expect(service.save('displayed-image', 'usb:2')).resolves.toBe(false);
    await expect(
      service.save('displayed-image', 'usb:2'),
    ).rejects.toMatchObject({
      code: 'invalid_response',
    });
  });
  it('targets the selected connection and validates the returned image', async () => {
    const png =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1sAAAAASUVORK5CYII=';
    const call = vi.fn().mockResolvedValue(png);
    const service = createTauriScreenshotService(call);
    await expect(service.capture('usb:2')).resolves.toBe(png);
    expect(call).toHaveBeenCalledWith('capture_device_screen', {
      connectionId: 'usb:2',
    });
    for (const value of [
      null,
      {},
      'https://example.com/image.png',
      'data:image/svg+xml,<svg/>',
      'data:image/png;base64,bad',
    ]) {
      call.mockResolvedValueOnce(value);
      await expect(service.capture('usb:2')).rejects.toMatchObject({
        code: 'invalid_response',
      });
    }
  });

  it('preserves structured device failures and normalizes unavailable IPC', async () => {
    const call = vi
      .fn()
      .mockRejectedValueOnce({
        code: 'disconnected',
        message: 'Device disconnected.',
      })
      .mockRejectedValueOnce('IPC missing');
    const service = createTauriScreenshotService(call);
    await expect(service.capture('usb:2')).rejects.toMatchObject({
      code: 'disconnected',
      message: 'Device disconnected.',
    });
    await expect(service.capture('usb:2')).rejects.toMatchObject({
      code: 'unavailable',
    });
  });
});
