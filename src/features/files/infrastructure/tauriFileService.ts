import { invoke } from '@tauri-apps/api/core';
import {
  FileError,
  validName,
  type FileEntry,
  type FileListing,
  type FileService,
} from '../domain/files';

type Invoke = (
  command: string,
  args: Record<string, unknown>,
) => Promise<unknown>;
function record(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}
function invalid(partial = false): never {
  throw new FileError(
    'invalid_response',
    'The desktop returned an invalid file response.',
    partial,
  );
}
function entry(value: unknown): value is FileEntry {
  return (
    record(value) &&
    typeof value.name === 'string' &&
    validName(value.name) &&
    ['directory', 'file', 'symlink', 'other'].includes(String(value.kind)) &&
    (value.size === null ||
      (typeof value.size === 'number' &&
        Number.isSafeInteger(value.size) &&
        value.size >= 0)) &&
    (value.modifiedAt === null ||
      (typeof value.modifiedAt === 'number' &&
        Number.isSafeInteger(value.modifiedAt))) &&
    (value.permissions === null ||
      (typeof value.permissions === 'string' &&
        /^[0-7]{4}$/u.test(value.permissions)))
  );
}
export function createTauriFileService(call: Invoke = invoke): FileService {
  async function request(command: string, args: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        record(error) &&
        typeof error.code === 'string' &&
        typeof error.message === 'string' &&
        typeof error.partial === 'boolean'
      ) {
        throw new FileError(error.code, error.message, error.partial);
      }
      throw new FileError(
        'native_failed',
        'The desktop file operation failed. Refresh the device and retry.',
        command !== 'list_files',
      );
    }
  }
  return {
    async list(deviceId, path): Promise<FileListing> {
      const value = await request('list_files', { deviceId, path });
      if (
        !record(value) ||
        value.path !== path ||
        !Array.isArray(value.entries) ||
        !value.entries.every(entry) ||
        new Set(value.entries.map((e) => e.name)).size !== value.entries.length
      )
        return invalid();
      return { path, entries: value.entries };
    },
    async mutate(deviceId, path, operation, name) {
      if (
        (await request('mutate_file', { deviceId, path, operation, name })) !==
        null
      )
        invalid(true);
    },
    async transfer(deviceId, path, upload, directory) {
      const value = await request('transfer_file', {
        deviceId,
        path,
        upload,
        directory,
      });
      if (typeof value !== 'boolean') return invalid(true);
      return value;
    },
  };
}
