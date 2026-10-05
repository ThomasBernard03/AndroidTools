import { describe, expect, it, vi } from 'vitest';
import { createTauriKeystoreExplorerService } from './tauriKeystoreExplorerService';
import { createDemoKeystoreExplorerService } from './demoKeystoreExplorerService';

const input = {
  path: '/upload.jks',
  password: 'demo-password',
  keyAlias: null,
  keyPassword: '',
};
describe('Keystore explorer IPC', () => {
  it('passes credentials to the native command and validates certificate results', async () => {
    const report = await createDemoKeystoreExplorerService().inspect(input);
    const call = vi.fn().mockResolvedValue(report);
    expect(
      await createTauriKeystoreExplorerService(call).inspect(input),
    ).toEqual(report);
    expect(call).toHaveBeenCalledWith('explore_keystore', { request: input });
    report.entries[0]!.certificates[0]!.sha256 = 'invalid';
    await expect(
      createTauriKeystoreExplorerService(call).inspect(input),
    ).rejects.toMatchObject({ code: 'invalid_response' });
  });
  it('rejects invalid statuses and translates structured native failures', async () => {
    const report = await createDemoKeystoreExplorerService().inspect(input);
    const call = vi.fn().mockResolvedValue({
      ...report,
      entries: [{ ...report.entries[0], keyStatus: 'healthy' }],
    });
    await expect(
      createTauriKeystoreExplorerService(call).inspect(input),
    ).rejects.toMatchObject({ code: 'invalid_response' });
    call.mockRejectedValue({
      code: 'unlock_failed',
      message: 'Password or integrity check failed.',
    });
    await expect(
      createTauriKeystoreExplorerService(call).inspect(input),
    ).rejects.toMatchObject({
      code: 'unlock_failed',
      message: 'Password or integrity check failed.',
    });
  });
  it('handles cancelled file selection without inventing a path', async () => {
    const service = createTauriKeystoreExplorerService(
      vi.fn().mockResolvedValue(null),
    );
    expect(await service.choose()).toBeNull();
  });
});
