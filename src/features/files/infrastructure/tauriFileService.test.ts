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
  it('validates preview content and never marks read failures as partial writes', async () => {
    const call = vi
      .fn()
      .mockResolvedValue({ kind: 'text', content: '{"enabled":true}' });
    const service = createTauriFileService(call);
    expect(await service.preview('phone', '/sdcard/config.json')).toEqual({
      kind: 'text',
      content: '{"enabled":true}',
    });
    expect(call).toHaveBeenCalledWith('preview_file', {
      deviceId: 'phone',
      path: '/sdcard/config.json',
    });
    for (const value of [
      null,
      { kind: 'html', content: '<b>hi</b>' },
      { kind: 'image', content: 'https://example.com/image.png' },
      { kind: 'image', content: 'data:image/svg+xml;base64,AAAA' },
      { kind: 'text', content: 'a'.repeat(1024 ** 2 + 1) },
    ]) {
      call.mockResolvedValueOnce(value);
      await expect(
        service.preview('phone', '/sdcard/file'),
      ).rejects.toMatchObject({ code: 'invalid_response', partial: false });
    }
    call.mockRejectedValueOnce(new Error('Disconnected'));
    await expect(
      service.preview('phone', '/sdcard/file'),
    ).rejects.toMatchObject({ partial: false });
  });
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
