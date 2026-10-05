import { describe, expect, it, vi } from 'vitest';
import { createTauriFileService } from './tauriFileService';

const entry = {
  name: "a\n'b.txt",
  kind: 'file',
  size: 3,
  modifiedAt: 0,
  permissions: '0644',
};
describe('File IPC', () => {
  it('preserves filenames and sends the selected device on each operation', async () => {
    const call = vi
      .fn()
      .mockResolvedValueOnce({ path: '/sdcard', entries: [entry] })
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(false);
    const service = createTauriFileService(call);
    expect((await service.list('phone-b', '/sdcard')).entries[0]).toEqual(
      entry,
    );
    await service.mutate('phone-b', '/sdcard/a', 'rename', 'b');
    expect(call).toHaveBeenLastCalledWith('mutate_file', {
      deviceId: 'phone-b',
      path: '/sdcard/a',
      operation: 'rename',
      name: 'b',
    });
    expect(await service.transfer('phone-b', '/sdcard', true, true)).toBe(
      false,
    );
  });
  it('rejects duplicate names, mismatched paths, traversal and invalid metadata', async () => {
    for (const value of [
      { path: '/', entries: [] },
      { path: '/sdcard', entries: [entry, entry] },
      { path: '/sdcard', entries: [{ ...entry, name: '../escape' }] },
      { path: '/sdcard', entries: [{ ...entry, kind: 'unknown' }] },
      { path: '/sdcard', entries: [{ ...entry, size: -1 }] },
    ]) {
      await expect(
        createTauriFileService(async () => value).list('phone', '/sdcard'),
      ).rejects.toMatchObject({ code: 'invalid_response' });
    }
  });
  it('preserves partial-operation errors and rejects malformed completion responses', async () => {
    const service = createTauriFileService(async () => {
      throw {
        code: 'disconnected',
        message: 'USB disconnected.',
        partial: true,
      };
    });
    await expect(
      service.transfer('phone', '/sdcard', true, false),
    ).rejects.toMatchObject({ code: 'disconnected', partial: true });
    await expect(
      createTauriFileService(async () => 'ok').mutate(
        'phone',
        '/sdcard/a',
        'delete',
        '',
      ),
    ).rejects.toMatchObject({ code: 'invalid_response' });
  });
});
