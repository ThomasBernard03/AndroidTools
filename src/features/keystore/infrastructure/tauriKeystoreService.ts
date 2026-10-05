import { invoke } from '@tauri-apps/api/core';
import {
  KeystoreError,
  type GeneratedKeystore,
  type KeystoreService,
} from '../domain/keystore';

type Invoke = (
  command: string,
  args?: Record<string, unknown>,
) => Promise<unknown>;
const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;
function invalid(): never {
  throw new KeystoreError(
    'invalid_response',
    'The keystore service returned an invalid response.',
  );
}

export function createTauriKeystoreService(
  call: Invoke = invoke,
): KeystoreService {
  async function request(command: string, args: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        isRecord(error) &&
        typeof error.code === 'string' &&
        typeof error.message === 'string'
      )
        throw new KeystoreError(
          error.code,
          error.message,
          typeof error.field === 'string' ? error.field : undefined,
        );
      throw new KeystoreError(
        'unavailable',
        'The desktop operation is unavailable. Please retry.',
      );
    }
  }
  return {
    async choosePath(format) {
      const value = await request('choose_keystore_path', { format });
      if (value !== null && (typeof value !== 'string' || !value)) invalid();
      return value as string | null;
    },
    async generate(input) {
      const value = await request('generate_keystore', { request: input });
      if (
        !isRecord(value) ||
        !['path', 'alias', 'expiresAt', 'sha1', 'sha256'].every(
          (key) => typeof value[key] === 'string' && value[key] !== '',
        ) ||
        value.format !== input.format ||
        value.path !== input.path ||
        value.alias !== input.alias ||
        !/^\d{4}-\d{2}-\d{2}$/.test(value.expiresAt as string) ||
        !/^([A-F0-9]{2}:){19}[A-F0-9]{2}$/.test(value.sha1 as string) ||
        !/^([A-F0-9]{2}:){31}[A-F0-9]{2}$/.test(value.sha256 as string)
      )
        invalid();
      return value as unknown as GeneratedKeystore;
    },
    async copy(text) {
      await request('copy_keystore_text', { text });
    },
    async reveal(path) {
      await request('reveal_keystore', { path });
    },
  };
}
