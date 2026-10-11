import { invoke } from '@tauri-apps/api/core';
import { AdbError } from '../../adb/domain/adb';
import { logLevels, type LogEntry, type LogcatService } from '../domain/logcat';

const record = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;
const integer = (value: unknown): value is number =>
  typeof value === 'number' && Number.isSafeInteger(value) && value >= 0;
const counts = (value: unknown): value is number[] =>
  Array.isArray(value) &&
  value.length === 6 &&
  value.every(integer) &&
  value.every((count, index, all) => index === 0 || count <= all[index - 1]!);
const failure = (value: unknown): value is { code: string; message: string } =>
  record(value) &&
  typeof value.code === 'string' &&
  typeof value.message === 'string';

export function createTauriLogcatService(
  call: (
    command: string,
    args: Record<string, unknown>,
  ) => Promise<unknown> = invoke,
): LogcatService {
  function invalid(): never {
    throw new AdbError(
      'invalid_response',
      'Logcat returned an invalid response.',
    );
  }
  async function request(command: string, args: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (failure(error)) throw new AdbError(error.code, error.message);
      throw new AdbError(
        'unavailable',
        'The Logcat operation failed. Check the device and refresh.',
      );
    }
  }
  return {
    async packages(connectionId) {
      const value = await request('list_logcat_packages', { connectionId });
      if (
        !Array.isArray(value) ||
        !value.every(
          (name): name is string =>
            typeof name === 'string' && /^[\w.]{1,255}$/.test(name),
        )
      )
        return invalid();
      return value;
    },
    async start(connectionId, packageName) {
      const value = await request('start_logcat', {
        connectionId,
        package: packageName,
      });
      if (!integer(value) || value === 0) return invalid();
      return value;
    },
    async read(token) {
      const value = await request('read_logcat', { token });
      if (
        !record(value) ||
        !counts(value.counts) ||
        !counts(value.groupedCounts) ||
        (value.error !== null && !failure(value.error))
      )
        return invalid();
      const raw = value.counts;
      if (!value.groupedCounts.every((count, index) => count <= raw[index]!))
        return invalid();
      return {
        counts: value.counts,
        groupedCounts: value.groupedCounts,
        error: value.error,
      };
    },
    async page(token, minimum, start, grouped = false) {
      const value = await request('page_logcat', {
        token,
        minimum,
        start,
        grouped,
      });
      if (
        !record(value) ||
        !integer(value.start) ||
        value.start > start ||
        !Array.isArray(value.entries) ||
        value.entries.length > 200 ||
        !value.entries.every(
          (entry): entry is LogEntry =>
            record(entry) &&
            integer(entry.id) &&
            integer(entry.repeatCount) &&
            entry.repeatCount >= 1 &&
            (grouped || entry.repeatCount === 1) &&
            typeof entry.text === 'string' &&
            entry.text.length <= 65536 &&
            logLevels.some((level) => level.value === entry.level),
        )
      )
        return invalid();
      if (
        !value.entries.every(
          (entry, index, all) =>
            (index === 0 || entry.id > all[index - 1]!.id) &&
            'VDIWEF'.indexOf(entry.level) >= 'VDIWEF'.indexOf(minimum),
        )
      )
        return invalid();
      return { start: value.start, entries: value.entries };
    },
    async search(token, search) {
      const value = await request('search_logcat', { token, request: search });
      if (
        !record(value) ||
        (value.position !== null &&
          (!integer(value.position) ||
            value.position < search.start ||
            value.position >= search.end)) ||
        (value.next !== null &&
          (!integer(value.next) ||
            (search.backward
              ? value.next >= search.end || value.next < search.start
              : value.next <= search.start || value.next > search.end))) ||
        (value.position !== null && value.next !== null)
      )
        return invalid();
      return { position: value.position, next: value.next };
    },
    async stop(token) {
      await request('stop_logcat', { token });
    },
    async pause(token) {
      await request('pause_logcat', { token });
    },
    async clear(connectionId) {
      await request('clear_logcat', { connectionId });
    },
  };
}
