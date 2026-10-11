import { describe, expect, it, vi } from 'vitest';
import { createTauriLogcatService } from './tauriLogcatService';

describe('Logcat history IPC', () => {
  it('passes device identity, viewport and resumable search without transferring full history', async () => {
    const call = vi
      .fn()
      .mockResolvedValueOnce(12)
      .mockResolvedValueOnce({
        counts: [20000, 15000, 12000, 1000, 1000, 0],
        groupedCounts: [20000, 15000, 12000, 1000, 1000, 0],
        error: null,
      })
      .mockResolvedValueOnce({
        start: 10000,
        entries: [{ id: 15200, level: 'E', text: 'failure', repeatCount: 1 }],
      })
      .mockResolvedValueOnce({ position: null, next: 2000 })
      .mockResolvedValue(null);
    const service = createTauriLogcatService(call);
    const token = await service.start('usb:phone-b', 'com.example.app');
    expect((await service.read(token)).counts[0]).toBe(20000);
    expect((await service.page(token, 'I', 10000)).entries[0]!.id).toBe(15200);
    const search = {
      grouped: false,
      minimum: 'I' as const,
      query: 'error',
      start: 0,
      end: 12000,
      backward: false,
    };
    expect(await service.search(token, search)).toEqual({
      position: null,
      next: 2000,
    });
    await service.pause(token);
    await service.clear('usb:phone-b');
    await service.stop(token);
    expect(call.mock.calls).toEqual([
      [
        'start_logcat',
        { connectionId: 'usb:phone-b', package: 'com.example.app' },
      ],
      ['read_logcat', { token: 12 }],
      [
        'page_logcat',
        { token: 12, minimum: 'I', start: 10000, grouped: false },
      ],
      ['search_logcat', { token: 12, request: search }],
      ['pause_logcat', { token: 12 }],
      ['clear_logcat', { connectionId: 'usb:phone-b' }],
      ['stop_logcat', { token: 12 }],
    ]);
  });
  it('rejects malformed counts, pages and search cursors that would loop forever', async () => {
    for (const value of [
      null,
      { counts: [1], error: null },
      { counts: [0, 1, 0, 0, 0, 0], error: null },
      { counts: [1, 1, 1, 0, 0, 0], error: {} },
    ]) {
      await expect(
        createTauriLogcatService(async () => value).read(1),
      ).rejects.toThrow('invalid response');
    }
    for (const entries of [
      [{ id: 1, level: 'X', text: 'bad' }],
      [{ id: 1, level: 'V', text: 'wrong level' }],
      [{ id: 1, level: 'I', text: 3 }],
      Array.from({ length: 201 }, (_, id) => ({ id, level: 'I', text: '' })),
    ]) {
      await expect(
        createTauriLogcatService(async () => ({ start: 0, entries })).page(
          1,
          'I',
          0,
        ),
      ).rejects.toThrow('invalid response');
    }
    for (const value of [
      { next: 0, position: null },
      { next: null, position: 500 },
      { next: 20, position: 30 },
    ]) {
      await expect(
        createTauriLogcatService(async () => value).search(1, {
          grouped: false,
          minimum: 'V',
          query: 'find',
          start: 0,
          end: 100,
          backward: false,
        }),
      ).rejects.toThrow('invalid response');
    }
    await expect(
      createTauriLogcatService(async () => -1).start('phone', ''),
    ).rejects.toThrow('invalid response');
    await expect(
      createTauriLogcatService(async () => [42]).packages('phone'),
    ).rejects.toThrow('invalid response');
  });
  it('preserves capture and storage errors', async () => {
    const service = createTauriLogcatService(async () => {
      throw { code: 'save_failed', message: 'Disk full' };
    });
    await expect(service.read(1)).rejects.toMatchObject({
      code: 'save_failed',
      message: 'Disk full',
    });
  });
});
