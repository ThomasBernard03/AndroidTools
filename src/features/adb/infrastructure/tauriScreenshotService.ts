import { invoke } from '@tauri-apps/api/core';
import { AdbError } from '../domain/adb';
import type { ScreenshotService } from '../domain/screenshot';

export function createTauriScreenshotService(
  call: (
    command: string,
    args: Record<string, unknown>,
  ) => Promise<unknown> = invoke,
): ScreenshotService {
  async function request(command: string, args: Record<string, unknown>) {
    try {
      return await call(command, args);
    } catch (error) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        typeof error.code === 'string' &&
        'message' in error &&
        typeof error.message === 'string'
      )
        throw new AdbError(error.code, error.message);
      throw new AdbError(
        'unavailable',
        'The screen preview operation is unavailable. Please retry.',
      );
    }
  }
  return {
    async save(image, connectionId) {
      const result = await request('save_device_screen', {
        image,
        connectionId,
      });
      if (typeof result !== 'boolean') {
        throw new AdbError(
          'invalid_response',
          'Saving the preview returned an invalid response.',
        );
      }
      return result;
    },
    async capture(connectionId) {
      const result = await request('capture_device_screen', { connectionId });
      if (
        typeof result !== 'string' ||
        result.length > 23_000_000 ||
        !/^data:image\/png;base64,iVBORw0KGgo[A-Za-z0-9+/]*={0,2}$/.test(result)
      ) {
        throw new AdbError(
          'invalid_response',
          'The device returned an invalid screen capture.',
        );
      }
      return result;
    },
  };
}
