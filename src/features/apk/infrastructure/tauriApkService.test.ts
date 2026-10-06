import { describe, expect, it } from 'vitest';
import { createTauriApkService, parseReport } from './tauriApkService';
import { demoReport } from './demoApkService';

describe('APK IPC boundary', () => {
  it('installs on the requested device and validates the response', async () => {
    const service = createTauriApkService(async (command, args) => {
      expect(command).toBe('install_apk');
      expect(args).toEqual({
        connectionId: 'phone',
        path: '/app.apk',
        sha256: 'AB'.repeat(32),
      });
      return null;
    });
    await service.install('phone', '/app.apk', 'AB'.repeat(32));
    await expect(
      createTauriApkService(async () => true).install(
        'phone',
        '/app.apk',
        'AB'.repeat(32),
      ),
    ).rejects.toThrow('invalid response');
    await expect(
      createTauriApkService(async () => {
        throw { code: 'disconnected', message: 'Device disconnected' };
      }).install('phone', '/app.apk', 'AB'.repeat(32)),
    ).rejects.toMatchObject({
      code: 'disconnected',
      message: 'Device disconnected',
    });
  });
  it('accepts reports and dialog cancellation', async () => {
    expect(parseReport(demoReport()).files).toHaveLength(2);
    expect(
      await createTauriApkService(async () => null).choosePath(),
    ).toBeNull();
  });
  it('rejects malformed nested data, invalid hashes and mismatched paths', async () => {
    for (const data of [
      null,
      { ...demoReport(), sha256: 'bad' },
      { ...demoReport(), files: [{ name: 'x', size: -1 }] },
      {
        ...demoReport(),
        sections: [{ title: 'App', items: [{ label: 'Package', value: 3 }] }],
      },
    ]) {
      expect(() => parseReport(data)).toThrow('invalid response');
    }
    await expect(
      createTauriApkService(async () => demoReport()).analyze('/different.apk'),
    ).rejects.toThrow('invalid response');
  });
  it('preserves structured errors', async () => {
    await expect(
      createTauriApkService(async () => {
        throw { code: 'read_failed', message: 'File unavailable' };
      }).analyze('/a.apk'),
    ).rejects.toMatchObject({
      code: 'read_failed',
      message: 'File unavailable',
    });
  });
  it('rejects malformed or unsupported verification claims', () => {
    for (const signature of [
      null,
      {},
      { status: 'verified', schemes: [], message: 'OK' },
      { status: 'verified', schemes: ['v1'], message: 'OK' },
      { status: 'trusted', schemes: ['v2'], message: 'OK' },
      { status: 'verified', schemes: ['v4'], message: 'OK' },
    ]) {
      expect(() => parseReport({ ...demoReport(), signature })).toThrow(
        'invalid response',
      );
    }
    expect(parseReport(demoReport()).signature.status).toBe('verified');
  });
  it('allows inline raster icons only', () => {
    for (const iconDataUrl of [
      null,
      'data:image/png;base64,YQ==',
      'data:image/webp;base64,YQ==',
      'data:image/jpeg;base64,YQ==',
    ]) {
      expect(parseReport({ ...demoReport(), iconDataUrl }).iconDataUrl).toBe(
        iconDataUrl,
      );
    }
    for (const iconDataUrl of [
      undefined,
      42,
      'https://example.com/icon.png',
      'file:///icon.png',
      'data:image/svg+xml;base64,YQ==',
      'data:image/png;base64,',
      `data:image/png;base64,${'A'.repeat(2_800_000)}`,
    ]) {
      expect(() => parseReport({ ...demoReport(), iconDataUrl })).toThrow(
        'invalid response',
      );
    }
  });
});
