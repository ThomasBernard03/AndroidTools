import { describe, expect, it, vi } from 'vitest';
import { createTauriSettingsService } from './tauriSettingsService';

describe('Settings IPC', () => {
  it('sends preference changes and fixed destination identifiers', async () => {
    const call = vi.fn().mockResolvedValue({ crashReportingEnabled: true });
    const service = createTauriSettingsService(call);
    expect(await service.load()).toEqual({ crashReportingEnabled: true });
    await service.setCrashReporting(false);
    await service.openProjectLink('issue');
    await service.openProjectLink('repository');
    await service.openLogsFolder();
    expect(call.mock.calls).toEqual([
      ['load_settings', undefined],
      ['set_crash_reporting', { enabled: false }],
      ['open_project_link', { link: 'issue' }],
      ['open_project_link', { link: 'repository' }],
      ['open_logs_folder', undefined],
    ]);
  });
  it('propagates log folder failures for display and retry', async () => {
    const service = createTauriSettingsService(
      vi.fn().mockRejectedValue({
        code: 'open_failed',
        message: 'Could not open logs.',
      }),
    );
    await expect(service.openLogsFolder()).rejects.toMatchObject({
      code: 'open_failed',
      message: 'Could not open logs.',
    });
  });
  it.each([null, {}, { crashReportingEnabled: 'true' }, false])(
    'rejects malformed preferences: %j',
    async (response) => {
      const service = createTauriSettingsService(async () => response);
      await expect(service.load()).rejects.toMatchObject({
        code: 'invalid_response',
      });
      await expect(service.setCrashReporting(true)).rejects.toMatchObject({
        code: 'invalid_response',
      });
    },
  );
  it('preserves structured failures and normalizes unexpected ones', async () => {
    const call = vi
      .fn()
      .mockRejectedValueOnce({
        code: 'storage_failed',
        message: 'Cannot save.',
      })
      .mockRejectedValueOnce('unknown');
    const service = createTauriSettingsService(call);
    await expect(service.setCrashReporting(true)).rejects.toMatchObject({
      code: 'storage_failed',
      message: 'Cannot save.',
    });
    await expect(service.openProjectLink('issue')).rejects.toMatchObject({
      code: 'unavailable',
    });
  });
});
