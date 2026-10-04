import { invoke } from '@tauri-apps/api/core';
import { SigningError, type SigningService } from '../domain/signing';

type Invoke = (
  command: string,
  args?: Record<string, unknown>,
) => Promise<unknown>;

export function createTauriSigningService(
  call: Invoke = invoke,
): SigningService {
  async function request(command: string, args?: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        'message' in error &&
        typeof error.code === 'string' &&
        typeof error.message === 'string'
      ) {
        throw new SigningError(error.code, error.message);
      }
      throw new SigningError(
        'unavailable',
        'The signing operation is unavailable. Please retry.',
      );
    }
  }
  async function path(
    command: string,
    args?: Record<string, unknown>,
  ): Promise<string | null> {
    const value = await request(command, args);
    if (value === null || (typeof value === 'string' && value.length > 0))
      return value;
    throw new SigningError(
      'invalid_response',
      'The signing service returned an invalid response.',
    );
  }
  return {
    chooseApk: () => path('choose_apk_path'),
    chooseKeystore: () => path('choose_signing_keystore'),
    signAndSave: (input) => path('sign_apk', { request: input }),
    async copy(text) {
      await request('copy_keystore_text', { text });
    },
    async reveal(value) {
      await request('reveal_keystore', { path: value });
    },
  };
}
